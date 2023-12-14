# Lua Integration in Swift

## Overview
This Swift Package allows seamless integration of Lua scripting capabilities within Swift applications. It provides a comprehensive suite of functionalities, utilities, and examples to facilitate the interaction between Swift and Lua scripts.

## File Details

### LuaBridge.swift
- **Purpose**: Provides bridging functionality between Lua and Swift.
- **Contents**:
  - `pushUserData(value: T)`: Pushes Swift values to Lua stack as user data.
  - `getUserData<T>(state: OpaquePointer, type: T.Type, index: Int32) -> T`: Retrieves user data from Lua stack.

### LuaKit.swift
- **Purpose**: Central module for Lua interaction in Swift.
- **Contents**:
  - `init()`: Initializes Lua environment.
  - `execute(source: String)`: Executes Lua script from a string.
  - `execute(url: URL)`: Executes Lua code from a file URL.
  - `register(function: String, body: @escaping (Lua) -> Int32) throws`: Registers Swift functions within Lua.

### LuaStackDump.swift
- **Purpose**: Prints Lua stack information for debugging.
- **Contents**:
  - `dumpStack(note: String?)`: Prints Lua stack information with an optional note.

### Macros.swift
- **Purpose**: Defines macros/utilities for Lua functions.
- **Contents**:
  - *Contains various utility functions or macros.*

### LuaDemo.swift
- **Purpose**: Demonstrates basic Lua usage in a Swift executable.
- **Usage**: Provides an example of using Lua functionalities within a Swift executable.

### LuaIntegrationDemo.swift
- **Purpose**: Demonstrates advanced Lua integration in Swift.
- **Usage**: Example of intricate interactions between Lua and Swift in a complex scenario.

### LuaIntegrationTests
- **Purpose**: Contains unit tests for Lua integration functionalities.
- **Usage**: Ensures correctness and reliability of Lua functionalities.

## Usage Guide
# Integrating Lua Integration in Xcode

## Prerequisites
- **Xcode**: Ensure you have Xcode installed on your system.
- **Swift Package Manager (SPM)**: The Lua Integration package uses SPM for dependency management.

## Integration Steps
1. **Clone or Download**:
   - Clone the Lua Integration repository or download the source files.

2. **Open Xcode Project**:
   - Open your Xcode project or create a new project.

3. **Add Swift Package**:
   - Click on your Xcode project in the Navigator.
   - Select your target, navigate to the `Swift Packages` tab.
   - Click the `+` button and choose `Add Package Dependency`.
   - Enter the URL of the Lua Integration GitHub repository or the local path to the package directory.
   - Click `Next`, specify the version or branch, then click `Finish`.

4. **Import Lua Integration**:
   - In your Swift files where you want to use Lua functionalities, import the necessary modules:
     ```swift
      import LuaKit
      
      // A class to manage Lua interpretation
      public class LuaInterpreter {
          let lua = Lua()
      
          // Enum for handling Lua execution errors
          enum LuaError: Error {
              case executionError(String)
          }
      
          // Function to interpret Lua code
          func interpret(luaCode: String) throws -> String {
              do {
                  // Execute Lua code
                  try lua.withUnchangedStack {
                      lua.execute(source: luaCode)
                  }
                  return "Code executed successfully"
              } catch let error {
                  // Throw custom error if Lua execution fails
                  throw LuaError.executionError("Error executing Lua code: \(error.localizedDescription)")
              }
          }
      }
      
      // A SwiftUI View demonstrating Lua code execution
      struct ContentView: View {
          let luaInterpreter = LuaInterpreter()
          let fileContent = "your_lua_code_here" // Replace with your Lua code
      
          @State private var output: String = ""
      
          var body: some View {
              Text(output)
                  .onAppear {
                      do {
                          // Attempt to execute Lua code
                          output = try luaInterpreter.interpret(luaCode: fileContent)
                      } catch {
                          // Handle errors during Lua code execution
                          output = "Error executing Lua code: \(error.localizedDescription)"
                      }
                  }
          }
      }

     ```

5. **Usage**:
   - Utilize the provided functionalities according to your requirements. For instance:
     - Use `LuaKit.swift` for managing Lua interaction.
     - Refer to `LuaDemo.swift` and `LuaIntegrationDemo.swift` for examples of Lua usage in Swift.

6. **Run and Test**:
   - Run your project to test Lua Integration functionalities.
   - Refer to the `LuaIntegrationTests` directory for unit tests and to verify the functionalities.

## Troubleshooting
- **Dependency Errors**:
  - Ensure your package dependencies are correctly specified in the `Package.swift` file.
  - Check for any missing or incorrect dependencies.
  
- **Build Issues**:
  - If you encounter build issues related to Lua Integration, review the import statements and ensure proper module usage.

## Contributing
- Contributions are welcome! Fork the repository, make your changes, and submit a pull request.

## License
This project is licensed under [MIT License] - see the [MIT License]([LICENSE_FILE](https://github.com/William-Laverty/LuaKit-for-Swift/blob/main/LICENSE)) for details.
