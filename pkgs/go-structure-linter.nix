{
  mkGoTool,
  src,
}:
mkGoTool {
  inherit src;
  pname = "go-structure-linter";
  vendorHash = "sha256-TnjSfORBu8J8n3xazgEPsrAvCFn0Hd92OMDl6/AypGE=";
  description = "Validates Go project structure against community best practices";
}
