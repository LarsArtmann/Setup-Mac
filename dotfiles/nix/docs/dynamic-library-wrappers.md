# Advanced Dynamic Library Wrapper System

This document describes the enhanced wrapper system for managing non-Nix binaries with complex dynamic library dependencies on nix-darwin/macOS.

## Overview

While nix-ld is Linux/NixOS-only, this wrapper system provides similar benefits for macOS by:

1. **Transparent library management** - Automatic `DYLD_LIBRARY_PATH` handling
2. **Install name patching** - Using `install_name_tool` to fix hardcoded paths
3. **Environment isolation** - Clean wrapper environments for complex applications
4. **Debugging support** - Verbose mode for troubleshooting library issues

## Core Components

### 1. Dynamic Library Wrapper (`dynamic-libs.nix`)

Advanced wrapper functions for macOS-specific dynamic library management:

```nix
# Basic usage
wrapCliTool {
  name = "enhanced-tool";
  package = pkgs.someTool;
  dynamicLibs = [pkgs.openssl pkgs.curl];
  environment = { TOOL_CONFIG = "$HOME/.config/tool"; };
}
```

**Features:**
- `DYLD_LIBRARY_PATH` and `DYLD_FRAMEWORK_PATH` management
- Automatic `install_name_tool` patching
- Sandbox profile support
- Debug mode (`WRAPPER_DEBUG=1`)
- Local library installation support

### 2. Example Wrappers (`example-wrappers.nix`)

Pre-built wrapper configurations for common applications:

- **VS Code**: Enhanced with Node.js, Python, and Git integration
- **Docker CLI**: With complex library dependencies
- **JetBrains IDEs**: Java framework and library management
- **Database Tools**: PostgreSQL, MySQL client integration
- **Creative Apps**: Graphics and media framework handling

### 3. Downloaded Binary Support

Special wrapper for non-Nix binaries:

```nix
wrapDownloadedBinary {
  name = "custom-tool";
  binaryPath = "/usr/local/bin/custom-tool";
  dynamicLibs = [pkgs.libiconv pkgs.openssl];
  environment = { CONFIG_PATH = "$HOME/.config/custom-tool"; };
}
```

## Integration with Existing System

### Adding New Wrappers

1. Create wrapper in `./wrappers/applications/your-wrapper.nix`
2. Import in `./wrappers/default.nix`
3. Add to `environment.systemPackages`

Example:
```nix
# ./wrappers/applications/my-tool.nix
{ pkgs, lib }:
let inherit (import ./dynamic-libs.nix { inherit pkgs lib; }) wrapCliTool;
in {
  my-tool = wrapCliTool {
    name = "my-tool";
    package = pkgs.my-tool;
    dynamicLibs = [pkgs.openssl];
  };
}

# ./wrappers/default.nix
myToolWrapper = import ./applications/my-tool.nix { inherit pkgs lib; };

environment.systemPackages = [myToolWrapper.my-tool];
```

### Debug Mode

Enable debug output for any wrapper:
```bash
WRAPPER_DEBUG=1 enhanced-tool --help
```

## Best Practices

### 1. Library Detection

Use `otool -L` to inspect binary dependencies:
```bash
# Check what libraries a binary needs
otool -L /path/to/binary

# Check for system framework dependencies
otool -L /Applications/SomeApp.app/Contents/MacOS/app
```

### 2. Install Name Patching

For pre-compiled binaries with hardcoded paths:
```bash
# Change library reference from system to Nix
install_name_tool -change \
  "/usr/lib/libssl.dylib" \
  "${pkgs.openssl}/lib/libssl.dylib" \
  binary_path
```

### 3. Framework Management

macOS applications often need frameworks:
```nix
libSearchPaths = [
  "/System/Library/Frameworks"
  "/Library/Frameworks"
  "${pkgs.somePackage}/Library/Frameworks"
];
```

### 4. Environment Variables

Common useful environment variables:
```nix
environment = {
  # For CLI tools
  TERM = "xterm-256color";
  CLICOLOR = "1";

  # For GUI applications
  NSDocumentRevisionsDebugMode = "YES";

  # For development tools
  DEVELOPMENT_MODE = "1";
};
```

## Troubleshooting

### Common Issues

1. **"Library not found" errors**
   - Enable debug mode: `WRAPPER_DEBUG=1`
   - Check library paths: `otool -L binary`
   - Verify library exists: `ls ${library_path}/libname.dylib`

2. **Code signing issues**
   - Some binaries require valid signatures
   - Use `codesign --remove-signature` for development
   - Add sandbox profile for system access

3. **Framework loading problems**
   - Check `DYLD_FRAMEWORK_PATH`
   - Verify framework bundle structure
   - Use `otool -l` to examine framework commands

### Debug Commands

```bash
# Show all library paths for a wrapper
WRAPPER_DEBUG=1 wrapped-binary --help 2>&1 | grep DYLD

# Test library loading manually
DYLD_LIBRARY_PATH="${nix_lib_path}:$DYLD_LIBRARY_PATH" /path/to/binary

# Check framework loading
otool -l /path/to/binary | grep -A 10 LC_LOAD_DYLIB
```

## Migration from Homebrew

For applications currently managed by Homebrew:

1. Identify library dependencies: `brew deps formula`
2. Create wrapper using Nix equivalents
3. Test with debug mode enabled
4. Gradually migrate from Homebrew to wrapper

## Performance Considerations

- **Startup overhead**: Minimal (one shell script execution)
- **Memory usage**: No additional runtime overhead
- **Library loading**: Same as native macOS behavior
- **Disk usage**: Libraries remain in Nix store (deduplicated)

## Security Features

- **Sandboxing**: Optional sandbox profiles for restricted execution
- **Path validation**: Verifies binary existence before execution
- **Permission control**: No automatic system file modifications
- **Audit trail**: Debug mode provides execution transparency

## Integration with Development Workflow

### Development Environments

Create development-specific wrappers:
```nix
devWrapper = wrapCliTool {
  name = "my-dev-tool";
  package = pkgs.my-tool;
  dynamicLibs = [pkgs.openssl pkgs.postgresql];
  environment = {
    DEV_MODE = "1";
    DEBUG = "1";
    DATABASE_URL = "postgresql://localhost/dev";
  };
};
```

### IDE Integration

Enhance IDE wrappers with development tools:
```nix
jetbrainsEnhanced = jetbrainsWrapper {
  name = "intellij-ultimate";
  package = pkgs.jetbrains.idea-ultimate;
  additionalLibs = [pkgs.maven pkgs.gradle pkgs.nodejs];
};
```

## Future Enhancements

1. **Automatic dependency detection** - Using `otool` output analysis
2. **Template system integration** - With existing wrapper templates
3. **Performance monitoring** - Library loading time tracking
4. **Cross-platform compatibility** - Linux/macOS unified approach
5. **Homebrew bridge** - Automatic migration from Homebrew formulas

This system provides the benefits of nix-ld for macOS users while maintaining the declarative, reproducible nature of Nix.