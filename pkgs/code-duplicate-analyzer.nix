{
  mkGoTool,
  src,
}:
mkGoTool {
  inherit src;
  pname = "code-duplicate-analyzer";
  vendorHash = "sha256-cLl6aMnnDYXgHbOhoUEeLjO+6HS3ZYAic8+O5FvhOO8=";
  description = "High-performance Go CLI for AST-based duplicate code detection across projects";
}
