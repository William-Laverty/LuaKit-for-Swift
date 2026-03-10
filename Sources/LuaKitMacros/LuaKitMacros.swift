//
//  LuaKitMacros.swift
//  Defines a macro for integrating Lua functions using SwiftSyntax.
//  Created by William Laverty on 14/12/2023.
//

import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

@main
struct LuaKitMacrosPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        LuaFunctionMacro.self,
    ]
}

public struct LuaFunctionMacro {
}

extension LuaFunctionMacro: PeerMacro {
    public static func expansion(of node: AttributeSyntax, providingPeersOf declaration: some DeclSyntaxProtocol, in context: some MacroExpansionContext) throws -> [DeclSyntax] {
        guard let funcDecl = declaration.as(FunctionDeclSyntax.self) else {
            let diagnostic = Diagnostic(
                node: node,
                message: LuaKitDiagnostic.notAFunction
            )
            context.diagnose(diagnostic)
            return []
        }

        let functionName = funcDecl.name.trimmedDescription

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

enum LuaKitDiagnostic: String, DiagnosticMessage {
    case notAFunction

    var severity: DiagnosticSeverity { .error }

    var message: String {
        switch self {
        case .notAFunction:
            return "@LuaFunction can only be applied to functions"
        }
    }

    var diagnosticID: MessageID {
        MessageID(domain: "LuaKit", id: rawValue)
    }
}
