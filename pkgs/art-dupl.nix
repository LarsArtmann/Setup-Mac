{
  mkGoTool,
  src,
}:
mkGoTool {
  inherit src;
  pname = "art-dupl";
  vendorHash = "sha256-0nXCPvE9BJVcqTKGy1Nwy0KUbC5+mZ5YUwqin8EdIWU=";
  description = "Fast, type-safe code duplication detector for Go projects";
}
