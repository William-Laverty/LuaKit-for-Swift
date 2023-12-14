//
//  Macros.swift
//  Defines a LuaFunction macro using LuaKitMacros.
//  Created by William Laverty on 14/12/2023.
//

import Foundation

// Defines a macro named LuaFunction, attached to LuaKitMacros as LuaFunctionMacro
@attached(peer, names: named(_register))
public macro LuaFunction() = #externalMacro(module: "LuaKitMacros", type: "LuaFunctionMacro")
