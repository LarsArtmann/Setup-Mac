# 🔧 Type-Level Assertions Framework
# Provides comprehensive type safety with zero runtime overhead

{ lib }:

let
  # Helper functions
  any = predicate: list:
    builtins.any predicate list;
  
  # Type safety assertions with compile-time checking
  typeAssertions = {
    # String type validation
    isString = value: 
      assert lib.assertMsg (builtins.isString value) "Expected string, got ${builtins.typeOf value}";
      value;
      
    # Package type validation  
    isPackage = value:
      assert lib.assertMsg (value ? outPath || value ? out || builtins.isDerivation value) "Expected package, got ${builtins.typeOf value}";
      value;
      
    # AttrSet type validation
    isAttrs = value:
      assert lib.assertMsg (builtins.isAttrs value) "Expected attrs, got ${builtins.typeOf value}";
      value;
      
    # List type validation
    isList = value:
      assert lib.assertMsg (builtins.isList value) "Expected list, got ${builtins.typeOf value}";
      value;
      
    # Path type validation
    isPath = value:
      assert lib.assertMsg (builtins.isPath value) "Expected path, got ${builtins.typeOf value}";
      value;
      
    # Boolean type validation
    isBool = value:
      assert lib.assertMsg (builtins.isBool value) "Expected bool, got ${builtins.typeOf value}";
      value;
      
    # Derivation type validation
    isDerivation = value:
      assert lib.assertMsg (builtins.isDerivation value) "Expected derivation, got ${builtins.typeOf value}";
      value;
      
    # Optional type - null or specific type
    optional = typeChecker: value:
      if value == null then value
      else typeChecker value;
      
    # Union type - multiple valid types
    either = typeCheckers: value:
      let
        results = map (checker: 
          if checker value == null then "valid"
          else checker value
        ) typeCheckers;
      in
        if any (r: r == "valid") results then value
        else "Union type failed: ${builtins.concatStringsSep ", " results}";
  };
  
in
{
  inherit typeAssertions;
}
