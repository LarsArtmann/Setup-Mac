{
  mkGoTool,
  src,
}:
mkGoTool {
  inherit src;
  pname = "template-readme";
  vendorHash = "";
  description = "Enterprise-grade README generation workflow orchestration platform";
  mainProgram = "readme-generator";
}
