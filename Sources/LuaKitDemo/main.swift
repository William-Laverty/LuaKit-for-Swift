//
//  LuaKitDemo.swift
//  Demonstrates integration of Lua with Swift using LuaKit.
//  Created by William Laverty on 14/12/2023.
//

import Foundation
import lua
import LuaKit

// Define a Lua function
@LuaFunction
func helloWorld() {
    print("Hello world (from Swift)")
}

do {
    // Create a Lua instance
    let lua = Lua()

    // Use Lua instance with unchanged stack
    try lua.withUnchangedStack {
        try _register(lua: lua) // Registers Swift functions into Lua (Behind the scenes)

        // Define Lua source code
        let source = #"""
        print("Hello world (from Lua)")
        helloWorld()
        """#

        // Execute Lua code using the Lua instance
        lua.execute(source: source)
    }
}
