//
//  LuaIntegrationTests.swift
//  Tests for Lua integration using macros.
//  Created by William Laverty on 14/12/2023.
//

import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest
import LuaKitMacros

// Dictionary mapping test macros
let testMacros: [String: Macro.Type] = [
    "LuaFunction": LuaFunctionMacro.self,
]

// Test class for LuaFunctionMacro
final class LuaFunctionMacroTests: XCTestCase {
    
    // Test method for macro without attributes
    func testMacroNoAttributes() {
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
}
