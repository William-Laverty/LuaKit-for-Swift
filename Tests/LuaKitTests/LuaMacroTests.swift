//
//  LuaMacroTests.swift
//  Tests for the @LuaFunction macro expansion.
//  Created by William Laverty on 14/12/2023.
//

import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest
import LuaKitMacros

let testMacros: [String: Macro.Type] = [
    "LuaFunction": LuaFunctionMacro.self,
]

final class LuaMacroTests: XCTestCase {

    func testMacroExpandsSimpleFunction() {
        assertMacroExpansion(
            """
            @LuaFunction
            func helloWorld() {
                print("Test")
            }
            """,
            expandedSource: """
            func helloWorld() {
                print("Test")
            }

            func _register(lua: Lua) throws {
                try lua.register(function: "helloWorld") { lua in
                    helloWorld()
                    return 1
                }
            }
            """,
            macros: testMacros
        )
    }

    func testMacroExpandsFunctionWithDifferentName() {
        assertMacroExpansion(
            """
            @LuaFunction
            func calculateSum() {
                let _ = 1 + 2
            }
            """,
            expandedSource: """
            func calculateSum() {
                let _ = 1 + 2
            }

            func _register(lua: Lua) throws {
                try lua.register(function: "calculateSum") { lua in
                    calculateSum()
                    return 1
                }
            }
            """,
            macros: testMacros
        )
    }

    func testMacroOnNonFunctionProducesDiagnostic() {
        assertMacroExpansion(
            """
            @LuaFunction
            struct NotAFunction {}
            """,
            expandedSource: """
            struct NotAFunction {}
            """,
            diagnostics: [
                DiagnosticSpec(message: "@LuaFunction can only be applied to functions", line: 1, column: 1)
            ],
            macros: testMacros
        )
    }

    func testMacroOnClassProducesDiagnostic() {
        assertMacroExpansion(
            """
            @LuaFunction
            class NotAFunction {}
            """,
            expandedSource: """
            class NotAFunction {}
            """,
            diagnostics: [
                DiagnosticSpec(message: "@LuaFunction can only be applied to functions", line: 1, column: 1)
            ],
            macros: testMacros
        )
    }

    func testMacroOnVariableProducesDiagnostic() {
        assertMacroExpansion(
            """
            @LuaFunction
            var notAFunction = 42
            """,
            expandedSource: """
            var notAFunction = 42
            """,
            diagnostics: [
                DiagnosticSpec(message: "@LuaFunction can only be applied to functions", line: 1, column: 1)
            ],
            macros: testMacros
        )
    }

    func testMacroExpandsEmptyFunction() {
        assertMacroExpansion(
            """
            @LuaFunction
            func doNothing() {
            }
            """,
            expandedSource: """
            func doNothing() {
            }

            func _register(lua: Lua) throws {
                try lua.register(function: "doNothing") { lua in
                    doNothing()
                    return 1
                }
            }
            """,
            macros: testMacros
        )
    }
}
