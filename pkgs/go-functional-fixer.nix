{
  mkGoTool,
  src,
}:
mkGoTool {
  inherit src;
  pname = "go-functional-fixer";
  vendorHash = "sha256-eaBMnokkIXk5Cv8TOKoWxMunlF+w6C6641C9iLJiQCQ=";
  description = "Detects imperative Go code and transforms loops into functional code using samber/lo";
}
