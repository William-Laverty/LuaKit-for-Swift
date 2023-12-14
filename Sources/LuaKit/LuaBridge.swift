//
//  LuaBridge.swift
//  Handles bridging functionalities between Lua and Swift.
//  Created by William Laverty on 14/12/2023.
//

import Foundation
import lua

// Pops elements from the Lua stack
public func lua_pop(_ L: OpaquePointer, _ n: Int32) {
    lua_settop(L, -(n) - 1)
}

// Calls a Lua function
public func lua_call(_ L: OpaquePointer, _ n: Int32, _ r: Int32) {
    lua_callk(L, n, r, 0, nil)
}

// Calculates the upvalue index for Lua functions
public func lua_upvalueindex(_ i: Int32) -> Int32 {
    return LUA_REGISTRYINDEX - i
}

// The index of the Lua registry
public let LUA_REGISTRYINDEX = -Int32(LUAI_MAXSTACK + 1_000)
