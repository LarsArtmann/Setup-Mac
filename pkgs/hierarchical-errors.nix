{
  mkGoTool,
  src,
}:
mkGoTool {
  inherit src;
  pname = "hierarchical-errors";
  vendorHash = "";
  description = "Static analysis tool for error handling patterns, hierarchies, and violations in Go";
}
