//
//  LuaExecutionTests.swift
//  Tests for Lua script execution, error handling, and stack management.
//  Created by William Laverty on 14/12/2023.
//

import XCTest
@testable import LuaKit

final class LuaExecutionTests: XCTestCase {

    var lua: Lua!

    override func setUp() {
        super.setUp()
        lua = Lua()
    }

    override func tearDown() {
        lua.cleanup()
        lua = nil
        super.tearDown()
    }

    // MARK: - Initialization

    func testInitCreatesValidState() {
        XCTAssertNotNil(lua.state, "Lua state should be non-nil after init")
    }

    func testCleanupNilsState() {
        lua.cleanup()
        XCTAssertNil(lua.state, "Lua state should be nil after cleanup")
    }

    func testDoubleCleanupDoesNotCrash() {
        lua.cleanup()
        lua.cleanup() // Should not crash
    }

    // MARK: - Execute Source

    func testExecuteSimpleScript() throws {
        let results = try lua.execute(source: "return 42")
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results[0] as? Int64, 42)
    }

    func testExecuteReturnsMultipleValues() throws {
        let results = try lua.execute(source: "return 1, 'hello', true")
        XCTAssertEqual(results.count, 3)
        XCTAssertEqual(results[0] as? Int64, 1)
        XCTAssertEqual(results[1] as? String, "hello")
        XCTAssertEqual(results[2] as? Bool, true)
    }

    func testExecuteNoReturnValue() throws {
        let results = try lua.execute(source: "local x = 1 + 1")
        XCTAssertTrue(results.isEmpty)
    }

    func testExecuteStringReturn() throws {
        let results = try lua.execute(source: "return 'hello world'")
        XCTAssertEqual(results.first as? String, "hello world")
    }

    func testExecuteFloatReturn() throws {
        let results = try lua.execute(source: "return 3.14")
        let value = results.first as? Double
        XCTAssertNotNil(value)
        XCTAssertEqual(value!, 3.14, accuracy: 0.001)
    }

    func testExecuteBooleanReturn() throws {
        let trueResults = try lua.execute(source: "return true")
        XCTAssertEqual(trueResults.first as? Bool, true)

        let falseResults = try lua.execute(source: "return false")
        XCTAssertEqual(falseResults.first as? Bool, false)
    }

    func testExecuteNilReturn() throws {
        let results = try lua.execute(source: "return nil")
        XCTAssertEqual(results.count, 1)
        XCTAssertTrue(results[0] is LuaNull)
    }

    // MARK: - Execute Errors

    func testExecuteSyntaxErrorThrows() {
        XCTAssertThrowsError(try lua.execute(source: "this is not valid lua !!!")) { error in
            guard case LuaError.loadError = error else {
                XCTFail("Expected LuaError.loadError, got \(error)")
                return
            }
        }
    }

    func testExecuteRuntimeErrorThrows() {
        XCTAssertThrowsError(try lua.execute(source: "error('boom')")) { error in
            guard case LuaError.executionError(let msg) = error else {
                XCTFail("Expected LuaError.executionError, got \(error)")
                return
            }
            XCTAssertTrue(msg.contains("boom"))
        }
    }

    func testExecuteUndefinedFunctionErrorThrows() {
        XCTAssertThrowsError(try lua.execute(source: "nonexistent_function()")) { error in
            guard case LuaError.executionError = error else {
                XCTFail("Expected LuaError.executionError, got \(error)")
                return
            }
        }
    }

    // MARK: - Execute File

    func testExecuteFileNotFoundThrows() {
        let url = URL(fileURLWithPath: "/nonexistent/path/script.lua")
        XCTAssertThrowsError(try lua.execute(url: url)) { error in
            guard case LuaError.fileNotFound = error else {
                XCTFail("Expected LuaError.fileNotFound, got \(error)")
                return
            }
        }
    }

    func testExecuteFileWithValidScript() throws {
        let tempDir = FileManager.default.temporaryDirectory
        let scriptURL = tempDir.appendingPathComponent("test_\(UUID().uuidString).lua")
        try "return 99".write(to: scriptURL, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: scriptURL) }

        let results = try lua.execute(url: scriptURL)
        XCTAssertEqual(results.first as? Int64, 99)
    }

    func testExecuteFileWithSyntaxError() throws {
        let tempDir = FileManager.default.temporaryDirectory
        let scriptURL = tempDir.appendingPathComponent("bad_\(UUID().uuidString).lua")
        try "this is not valid lua !!!".write(to: scriptURL, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: scriptURL) }

        XCTAssertThrowsError(try lua.execute(url: scriptURL)) { error in
            guard case LuaError.loadError = error else {
                XCTFail("Expected LuaError.loadError, got \(error)")
                return
            }
        }
    }

    // MARK: - Stack Management

    func testStackSizeStartsAtZero() {
        XCTAssertEqual(lua.stackSize, 0)
    }

    func testWithUnchangedStackSucceeds() {
        let result = lua.withUnchangedStack {
            return 42
        }
        XCTAssertEqual(result, 42)
    }

    // MARK: - Global Variables

    func testSetAndGetGlobalString() {
        lua.setGlobal(name: "greeting", value: "hello")
        let value = lua.getGlobal(name: "greeting")
        XCTAssertEqual(value as? String, "hello")
    }

    func testSetAndGetGlobalInt() {
        lua.setGlobal(name: "count", value: Int64(42))
        let value = lua.getGlobal(name: "count")
        XCTAssertEqual(value as? Int64, 42)
    }

    func testSetAndGetGlobalDouble() {
        lua.setGlobal(name: "pi", value: 3.14159)
        let value = lua.getGlobal(name: "pi")
        let result = value as? Double
        XCTAssertNotNil(result)
        XCTAssertEqual(result!, 3.14159, accuracy: 0.00001)
    }

    func testSetAndGetGlobalBool() {
        lua.setGlobal(name: "flag", value: true)
        let value = lua.getGlobal(name: "flag")
        XCTAssertEqual(value as? Bool, true)

        lua.setGlobal(name: "flag", value: false)
        let value2 = lua.getGlobal(name: "flag")
        XCTAssertEqual(value2 as? Bool, false)
    }

    func testGetUndefinedGlobalReturnsNull() {
        let value = lua.getGlobal(name: "undefined_variable")
        XCTAssertTrue(value is LuaNull)
    }

    func testGlobalAccessibleFromScript() throws {
        lua.setGlobal(name: "x", value: Int64(10))
        let results = try lua.execute(source: "return x + 5")
        XCTAssertEqual(results.first as? Int64, 15)
    }

    // MARK: - Function Calls

    func testCallLuaFunction() throws {
        try lua.execute(source: """
            function add(a, b)
                return a + b
            end
        """)
        let result = try lua.call(function: "add", parameters: [Int64(3), Int64(4)])
        XCTAssertEqual(result as? Int64, 7)
    }

    func testCallLuaFunctionWithStringParams() throws {
        try lua.execute(source: """
            function greet(name)
                return "Hello, " .. name .. "!"
            end
        """)
        let result = try lua.call(function: "greet", parameters: ["World"])
        XCTAssertEqual(result as? String, "Hello, World!")
    }

    func testCallLuaFunctionNoParams() throws {
        try lua.execute(source: """
            function getFortyTwo()
                return 42
            end
        """)
        let result = try lua.call(function: "getFortyTwo")
        XCTAssertEqual(result as? Int64, 42)
    }

    func testCallLuaFunctionNoReturnValue() throws {
        try lua.execute(source: """
            called = false
            function sideEffect()
                called = true
            end
        """)
        let result = try lua.call(function: "sideEffect")
        XCTAssertTrue(result is LuaNull)

        let called = lua.getGlobal(name: "called")
        XCTAssertEqual(called as? Bool, true)
    }

    func testCallMultiReturn() throws {
        try lua.execute(source: """
            function multiReturn()
                return 1, "two", 3.0
            end
        """)
        let results = try lua.callMultiReturn(function: "multiReturn")
        XCTAssertEqual(results.count, 3)
        XCTAssertEqual(results[0] as? Int64, 1)
        XCTAssertEqual(results[1] as? String, "two")
    }

    func testCallUndefinedFunctionThrows() throws {
        XCTAssertThrowsError(try lua.call(function: "nonexistent")) { error in
            guard case LuaError.executionError = error else {
                XCTFail("Expected LuaError.executionError, got \(error)")
                return
            }
        }
    }

    // MARK: - Function Registration

    func testRegisterSwiftFunction() throws {
        try lua.register(function: "swiftAdd") { lua in
            // For now just return a constant
            lua.setGlobal(name: "swift_result", value: Int64(100))
            return 0
        }

        try lua.execute(source: "swiftAdd()")
        let result = lua.getGlobal(name: "swift_result")
        XCTAssertEqual(result as? Int64, 100)
    }

    // MARK: - Boolean Correctness

    func testBooleanTruePassedCorrectlyToLua() throws {
        lua.setGlobal(name: "flag", value: true)
        let results = try lua.execute(source: """
            if flag == true then
                return "yes"
            else
                return "no"
            end
        """)
        XCTAssertEqual(results.first as? String, "yes")
    }

    func testBooleanFalsePassedCorrectlyToLua() throws {
        lua.setGlobal(name: "flag", value: false)
        let results = try lua.execute(source: """
            if flag == false then
                return "no"
            else
                return "yes"
            end
        """)
        XCTAssertEqual(results.first as? String, "no")
    }

    // MARK: - Complex Scripts

    func testFibonacci() throws {
        try lua.execute(source: """
            function fib(n)
                if n <= 1 then return n end
                return fib(n - 1) + fib(n - 2)
            end
        """)
        let result = try lua.call(function: "fib", parameters: [Int64(10)])
        XCTAssertEqual(result as? Int64, 55)
    }

    func testStringManipulation() throws {
        let results = try lua.execute(source: """
            local s = "Hello, World!"
            return string.len(s), string.upper(s), string.sub(s, 1, 5)
        """)
        XCTAssertEqual(results.count, 3)
        XCTAssertEqual(results[0] as? Int64, 13)
        XCTAssertEqual(results[1] as? String, "HELLO, WORLD!")
        XCTAssertEqual(results[2] as? String, "Hello")
    }

    func testMathOperations() throws {
        let results = try lua.execute(source: """
            return math.max(1, 5, 3), math.min(1, 5, 3), math.abs(-42)
        """)
        XCTAssertEqual(results.count, 3)
        XCTAssertEqual(results[0] as? Int64, 5)
        XCTAssertEqual(results[1] as? Int64, 1)
        XCTAssertEqual(results[2] as? Int64, 42)
    }

    // MARK: - Multiple Independent Instances

    func testMultipleLuaInstances() throws {
        let lua2 = Lua()
        defer { lua2.cleanup() }

        lua.setGlobal(name: "x", value: Int64(10))
        lua2.setGlobal(name: "x", value: Int64(20))

        let r1 = try lua.execute(source: "return x")
        let r2 = try lua2.execute(source: "return x")

        XCTAssertEqual(r1.first as? Int64, 10)
        XCTAssertEqual(r2.first as? Int64, 20)
    }

    // MARK: - LuaError Descriptions

    func testLuaErrorDescriptions() {
        let loadErr = LuaError.loadError("bad syntax")
        XCTAssertTrue(loadErr.localizedDescription.contains("bad syntax"))

        let execErr = LuaError.executionError("runtime boom")
        XCTAssertTrue(execErr.localizedDescription.contains("runtime boom"))

        let fileErr = LuaError.fileNotFound("/some/path")
        XCTAssertTrue(fileErr.localizedDescription.contains("/some/path"))

        let typeErr = LuaError.unexpectedType("table")
        XCTAssertTrue(typeErr.localizedDescription.contains("table"))

        let regErr = LuaError.registrationFailed("oops")
        XCTAssertTrue(regErr.localizedDescription.contains("oops"))
    }
}
