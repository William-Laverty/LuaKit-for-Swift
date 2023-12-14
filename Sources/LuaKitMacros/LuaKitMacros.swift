//
//  LuaKitMacros.swift
//  Defines a macro for integrating Lua functions using SwiftSyntax.
//  Created by William Laverty on 14/12/2023.
//

import Metal
import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

// Main struct defining a CompilerPlugin for supporting macros
@main
struct MetalSupportMacrosPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        LuaFunctionMacro.self,
    ]
}

// Struct defining LuaFunctionMacro conforming to PeerMacro protocol
public struct LuaFunctionMacro {
}

extension LuaFunctionMacro: PeerMacro {
    // Expansion of the LuaFunctionMacro
    public static func expansion(of node: AttributeSyntax, providingPeersOf declaration: some DeclSyntaxProtocol, in context: some MacroExpansionContext) throws -> [DeclSyntax] {

        print("#####", Self.self, #function)
        
        // Guarding and handling FunctionDeclSyntax
        guard let funcDecl = declaration.as(FunctionDeclSyntax.self) else {
            return []
        }

        let functionName = funcDecl.name.trimmedDescription

        // Return an array with a dynamically generated Swift function based on Lua function call
        return [
            """
            func _register(lua: Lua) throws {
                try lua.register(function: "\(raw: functionName)") { lua in
                    \(raw: functionName)()
                    return 1
                }
            }
            """
        ]
    }
}
