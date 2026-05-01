{
  mkGoTool,
  src,
}:
mkGoTool {
  inherit src;
  pname = "art-dupl";
  vendorHash = "";
  description = "Fast, type-safe code duplication detector for Go projects";
}
