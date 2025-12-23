# 🔧 Module-Level Assertions Framework
# Provides fine-grained validation for each wrapper and system component
{lib, ...}: let
  # Module validation assertions
  moduleAssertions = wrapper: let
    name = wrapper.name or "unknown";
  in [
    (
      lib.assertMsg
      (wrapper.package != null)
      "Wrapper ${name}: package cannot be null"
    )
    (
      lib.assertMsg
      (wrapper.configFiles != null)
      "Wrapper ${name}: configFiles must be defined"
    )
    (
      lib.assertMsg
      (lib.hasAttr "environment" wrapper)
      "Wrapper ${name}: environment must be defined"
    )
    (
      lib.assertMsg
      (wrapper.configFiles != {})
      "Wrapper ${name}: configFiles cannot be empty"
    )
    (
      lib.assertMsg
      (wrapper.package ? outPath || wrapper.package ? out || builtins.isDerivation wrapper.package)
      "Wrapper ${name}: package must be valid Nix package"
    )
  ];
in {
  # Add assertions to each wrapper module
  addAssertions = wrapper:
    wrapper
    // {
      assertions = moduleAssertions wrapper;
    };
}
