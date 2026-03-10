//
//  LuaKit.swift
//  Manages interaction between Lua and Swift.
//  Created by William Laverty on 14/12/2023.
//

import Combine
import Foundation
import lua

// MARK: - Errors

/// Errors that can occur during Lua operations.
public enum LuaError: Error, LocalizedError {
    case loadError(String)
    case executionError(String)
    case fileNotFound(String)
    case unexpectedType(String)
    case registrationFailed(String)

    public var errorDescription: String? {
        switch self {
        case .loadError(let message): return "Lua load error: \(message)"
        case .executionError(let message): return "Lua execution error: \(message)"
        case .fileNotFound(let path): return "File not found: \(path)"
        case .unexpectedType(let type): return "Unexpected Lua type: \(type)"
        case .registrationFailed(let message): return "Function registration failed: \(message)"
        }
    }
}

// MARK: - Lua

public class Lua {
    public private(set) var state: OpaquePointer!
    private var cancellables: Set<AnyCancellable> = []

    // MARK: - Initialization

    public init() {
        state = luaL_newstate()!
        luaL_openlibs(state)
    }

    public init(state: OpaquePointer) {
        self.state = state
    }

    deinit {
        cleanup()
    }

    // MARK: - Cleanup

    public func cleanup() {
        if let state {
            lua_close(state)
            self.state = nil
        }
        cancellables = []
    }

    // MARK: - Stack Management

    /// The number of elements currently on the Lua stack.
    public var stackSize: Int32 {
        lua_gettop(state)
    }

    public func withUnchangedStack<R>(_ block: () throws -> R) rethrows -> R {
        let original = lua_gettop(state)
        defer {
            let current = lua_gettop(state)
            if original != current {
                fatalError("Stack changed! Expected \(original) but got \(current)")
            }
        }
        return try block()
    }

    // MARK: - Script Execution

    /// Execute a Lua script from a source string.
    /// - Throws: `LuaError.loadError` if the script fails to load, `LuaError.executionError` if it fails to run.
    @discardableResult
    public func execute(source: String) throws -> [LuaValue] {
        let loadResult = luaL_loadbufferx(state, source, strlen(source), "<string>", "t")
        guard loadResult == LUA_OK else {
            let message = String(cString: lua_tolstring(state, -1, nil))
            lua_pop(state, 1)
            throw LuaError.loadError(message)
        }

        let before = lua_gettop(state) - 1
        let callResult = lua_pcallk(state, 0, LUA_MULTRET, 0, 0, nil)
        guard callResult == LUA_OK else {
            let message = String(cString: lua_tolstring(state, -1, nil))
            lua_pop(state, 1)
            throw LuaError.executionError(message)
        }

        let returnCount = lua_gettop(state) - before
        let results = decode(count: returnCount)
        lua_pop(state, returnCount)
        return results
    }

    /// Execute a Lua script from a file URL.
    /// - Throws: `LuaError.fileNotFound` if the file doesn't exist, `LuaError.loadError` or `LuaError.executionError` on failure.
    @discardableResult
    public func execute(url: URL) throws -> [LuaValue] {
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw LuaError.fileNotFound(url.path)
        }

        let loadResult = luaL_loadfilex(state, url.path, nil)
        guard loadResult == LUA_OK else {
            let message = String(cString: lua_tolstring(state, -1, nil))
            lua_pop(state, 1)
            throw LuaError.loadError(message)
        }

        let before = lua_gettop(state) - 1
        let callResult = lua_pcallk(state, 0, LUA_MULTRET, 0, 0, nil)
        guard callResult == LUA_OK else {
            let message = String(cString: lua_tolstring(state, -1, nil))
            lua_pop(state, 1)
            throw LuaError.executionError(message)
        }

        let returnCount = lua_gettop(state) - before
        let results = decode(count: returnCount)
        lua_pop(state, returnCount)
        return results
    }

    // MARK: - Global Variables

    /// Set a global Lua variable.
    public func setGlobal(name: String, value: LuaValue) {
        push(value: value)
        lua_setglobal(state, name)
    }

    /// Get the value of a global Lua variable.
    public func getGlobal(name: String) -> LuaValue {
        lua_getglobal(state, name)
        let value = decode(index: -1)
        lua_pop(state, 1)
        return value
    }

    // MARK: - Function Invocation

    /// Call a Lua function by name with parameters.
    /// - Returns: The first return value, or `LuaNull()` if no return value.
    public func call(function: String, parameters: [LuaValue] = []) throws -> LuaValue {
        try withUnchangedStack {
            let before = lua_gettop(state)
            lua_getglobal(state, function)

            for param in parameters {
                push(value: param)
            }

            let callResult = lua_pcallk(state, Int32(parameters.count), LUA_MULTRET, 0, 0, nil)
            guard callResult == LUA_OK else {
                let message = String(cString: lua_tolstring(state, -1, nil))
                lua_pop(state, 1)
                throw LuaError.executionError(message)
            }

            let returnCount = lua_gettop(state) - before
            let results = decode(count: returnCount)
            lua_pop(state, returnCount)
            return results.first ?? LuaNull()
        }
    }

    /// Call a Lua function that returns multiple values.
    public func callMultiReturn(function: String, parameters: [LuaValue] = []) throws -> [LuaValue] {
        try withUnchangedStack {
            let before = lua_gettop(state)
            lua_getglobal(state, function)

            for param in parameters {
                push(value: param)
            }

            let callResult = lua_pcallk(state, Int32(parameters.count), LUA_MULTRET, 0, 0, nil)
            guard callResult == LUA_OK else {
                let message = String(cString: lua_tolstring(state, -1, nil))
                lua_pop(state, 1)
                throw LuaError.executionError(message)
            }

            let returnCount = lua_gettop(state) - before
            let results = decode(count: returnCount)
            lua_pop(state, returnCount)
            return results
        }
    }

    // MARK: - Function Registration

    public func register(function name: String, body: @escaping (Lua) -> Int32) throws {
        let start = lua_gettop(state)

        pushUserData(value: WeakBox(self))
        pushUserData(value: body)

        let upValueCount = lua_gettop(state) - start

        func luaClosure(state: OpaquePointer?) -> Int32 {
            guard let state = state else {
                fatalError("luaClosure called with nil state")
            }
            guard let lua = Lua.getUserData(state: state, type: WeakBox<Lua>.self, index: lua_upvalueindex(1)).element else {
                fatalError("Lua instance was deallocated")
            }
            let callable = Lua.getUserData(state: state, type: ((Lua) -> Int32).self, index: lua_upvalueindex(2))
            return callable(lua)
        }

        lua_pushcclosure(state, luaClosure, upValueCount)
        lua_setglobal(state, name)
    }
}

// MARK: - Private Extension

private extension Lua {
    func pushUserData<T>(value: T) {
        let pointer = UnsafeMutablePointer<T>.allocate(capacity: 1)
        pointer.initialize(to: value)
        lua_pushlightuserdata(state, pointer)

        AnyCancellable {
            pointer.deinitialize(count: 1)
            pointer.deallocate()
        }
        .store(in: &cancellables)
    }

    static func getUserData<T>(state: OpaquePointer, type: T.Type, index: Int32) -> T {
        guard let pointer = lua_touserdata(state, index) else {
            fatalError("No user data at index \(index)")
        }
        return pointer.assumingMemoryBound(to: T.self).pointee
    }

    func push(value: LuaValue) {
        switch value {
        case _ as LuaNull:
            lua_pushnil(state)
        case let value as Bool:
            lua_pushboolean(state, value ? 1 : 0)
        case let value as Int:
            lua_pushinteger(state, Int64(value))
        case let value as Int64:
            lua_pushinteger(state, value)
        case let value as Double:
            lua_pushnumber(state, value)
        case let value as String:
            lua_pushstring(state, value)
        default:
            fatalError("Cannot push value of type \(type(of: value)) to Lua stack")
        }
    }

    func decode(index: Int32) -> LuaValue {
        let type = lua_type(state, index)
        switch type {
        case LUA_TNIL:
            return LuaNull()
        case LUA_TBOOLEAN:
            return lua_toboolean(state, index) != 0
        case LUA_TNUMBER:
            var isnum: Int32 = 0
            let number = lua_tonumberx(state, index, &isnum)
            // Return Int64 if the number is an integer
            if number == number.rounded(.towardZero) && number >= Double(Int64.min) && number <= Double(Int64.max) {
                return Int64(number)
            }
            return number
        case LUA_TSTRING:
            return String(cString: lua_tolstring(state, index, nil))
        default:
            return LuaNull()
        }
    }

    func decode(count: Int32) -> [LuaValue] {
        guard count > 0 else {
            return []
        }
        return (-count ... -1).map { index in
            decode(index: index)
        }
    }
}

// MARK: - LuaValue Protocol

public protocol LuaValue {}

extension Int: LuaValue {}
extension Int64: LuaValue {}
extension Double: LuaValue {}
extension Bool: LuaValue {}
extension String: LuaValue {}

public struct LuaNull: LuaValue, Equatable {}
