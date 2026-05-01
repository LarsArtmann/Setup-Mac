{
  mkGoTool,
  src,
}:
mkGoTool {
  inherit src;
  pname = "branching-flow";
  vendorHash = "";
  description = "Go CLI analyzer for code quality issues: error context loss, type safety, structural patterns, duplication";
}
