{
  mkGoTool,
  src,
}:
mkGoTool {
  inherit src;
  pname = "code-duplicate-analyzer";
  vendorHash = "";
  description = "High-performance Go CLI for AST-based duplicate code detection across projects";
}
