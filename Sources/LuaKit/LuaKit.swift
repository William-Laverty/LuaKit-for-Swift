//
//  LuaKit.swift
//  Manages interaction between Lua and Swift.
//  Created by William Laverty on 14/12/2023.
//

import Combine
import Foundation
import lua

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

    public func withUnchangedStack<R>(_ block: () throws -> R) rethrows -> R {
        let original = lua_gettop(state)
        defer {
            let current = lua_gettop(state)
            if original != current {
                fatalError("Stack changed!")
            }
        }
        return try block()
    }

    // MARK: - Script Execution

    public func execute(source: String) {
        luaL_loadbufferx(state, source, strlen(source), "<string>", "t")
        assert(lua_status(state) == LUA_OK)
        lua_call(state, 0, LUA_MULTRET)
        assert(lua_status(state) == LUA_OK)
    }

    public func execute(url: URL) {
        assert(FileManager().fileExists(atPath: url.path))
        luaL_loadfilex(state, url.path, nil)
        assert(lua_status(state) == LUA_OK)
        lua_call(state, 0, LUA_MULTRET)
        assert(lua_status(state) == LUA_OK)
    }

    // MARK: - Function Invocation

    public func call(function: String, parameters: [LuaValue] = []) throws -> LuaValue {
        withUnchangedStack {
            let before = lua_gettop(state)
            lua_getglobal(state, function)
            push(values: parameters)
            lua_call(state, Int32(parameters.count), 1)
            assert(lua_status(state) == LUA_OK)
            let returnCount = lua_gettop(state) - (before)
            let result = decode(count: returnCount)
            lua_pop(state, returnCount)
            return result[0]
        }
    }

    public func register(function name: String, body: @escaping (Lua) -> Int32) throws {
        let start = lua_gettop(state)

        pushUserData(value: WeakBox(self))
        pushUserData(value: body)

        let upValueCount = lua_gettop(state) - start

        // Function for invoking Swift closures from Lua
        func luaClosure(state: OpaquePointer?) -> Int32 {
            guard let state = state else {
                fatalError("luaClosure failed()")
            }
            guard let lua = Lua.getUserData(state: state, type: WeakBox<Lua>.self, index: lua_upvalueindex(1)).element else {
                fatalError("getUserData failed")
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
    // MARK: - User Data Handling

    func pushUserData<T>(value: T) {
        let pointer = UnsafeMutablePointer<T>.allocate(capacity: 1)
        pointer.initialize(to: value)
        lua_pushlightuserdata(state, pointer)

        // Store the pointer's deallocation in cancellables
        AnyCancellable {
            pointer.deinitialize(count: 1)
            pointer.deallocate()
        }
        .store(in: &cancellables)
    }

    static func getUserData<T>(state: OpaquePointer, type: T.Type, index: Int32) -> T {
        guard let pointer = lua_touserdata(state, index) else {
            fatalError("No user data")
        }
        return pointer.assumingMemoryBound(to: T.self).pointee
    }

    // MARK: - Stack Operations

    func push(values: [LuaValue]) {
        for value in values {
            switch value {
            case _ as LuaNull:
                lua_pushnil(state)
            case let value as Bool:
                lua_pushboolean(state, value ? -1 : 0)
            case let value as Int64:
                lua_pushinteger(state, value)
            case let value as Double:
                lua_pushnumber(state, value)
            case let value as String:
                lua_pushstring(state, value)
            default:
                fatalError("Unexpected type")
            }
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
            return lua_tonumberx(state, index, &isnum)
        case LUA_TSTRING:
            return String(cString: lua_tolstring(state, index, nil))
        default:
            fatalError("Unexpected type")
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

    func pop(index: Int32) -> LuaValue {
        let value = decode(index: index)
        lua_pop(state, 1)
        return value
    }

    func pop(count: Int32) -> [LuaValue] {
        let values = decode(count: count)
        lua_pop(state, count)
        return values
    }
}

// MARK: - Protocol Conformances

public protocol LuaValue { }

extension Int64: LuaValue { }
extension Double: LuaValue { }
extension Bool: LuaValue { }
extension String: LuaValue { }

public struct LuaNull: LuaValue { }
