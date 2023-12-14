# Lua Integration in Swift

## Overview
This allows seamless integration of Lua scripting capabilities within Swift applications. It provides a comprehensive suite of functionalities, utilities, and examples to facilitate the interaction between Swift and Lua scripts.

## File Structure

### Package.swift
- **Description**: Defines Swift Package manifest and dependencies for Lua integration.
- **Purpose**: Configures the package, its targets, dependencies, and products.

### Sources/
- **LuaKit/**
  - **LuaBridge.swift**: Bridges functionality between Lua and Swift.
  - **LuaKit.swift**: Handles Lua interaction and script execution.
  - **LuaStackDump.swift**: Prints Lua stack information.
  - **Macros.swift**: Contains macros/utilities for Lua functions.

### LuaDemo/
- **LuaDemo.swift**: Demonstrates basic Lua usage within a Swift executable.

### LuaIntegrationDemo/
- **LuaIntegrationDemo.swift**: Demonstrates advanced Lua-Swift interaction.

### Tests/
- **LuaIntegrationTests/**: Contains unit tests for Lua integration functionalities.

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

### LuaIntegrationTests/
- **Purpose**: Contains unit tests for Lua integration functionalities.
- **Usage**: Ensures correctness and reliability of Lua functionalities.

## Usage Guide
1. **Integration Steps**:
   - Review `Package.swift` for dependencies.
2. **Basic Usage**:
   - Refer to `LuaDemo.swift` for basic Lua integration.
3. **Advanced Usage**:
   - Explore `LuaIntegrationDemo.swift` for advanced Lua-Swift interaction.
4. **Testing**:
   - Run tests in `LuaIntegrationTests` to verify functionality.

## Contributing
- Contributions are welcome! Fork the repository, make your changes, and submit a pull request.

## License
This project is licensed under [LICENSE_NAME] - see the [LICENSE_FILE](LICENSE_FILE) for details.

## Acknowledgments
- Acknowledge contributors or external libraries used.
- Any additional acknowledgments or credits.

## Support
- Contact information for support or inquiries.
- Guidelines for issue reporting or feature requests.

