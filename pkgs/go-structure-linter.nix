{
  mkGoTool,
  src,
}:
mkGoTool {
  inherit src;
  pname = "go-structure-linter";
  vendorHash = "";
  description = "Validates Go project structure against community best practices";
}
