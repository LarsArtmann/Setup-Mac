{
  mkGoTool,
  src,
}:
mkGoTool {
  inherit src;
  pname = "go-functional-fixer";
  vendorHash = "";
  description = "Detects imperative Go code and transforms loops into functional code using samber/lo";
}
