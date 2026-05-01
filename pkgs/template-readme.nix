{
  mkGoTool,
  src,
}:
mkGoTool {
  inherit src;
  pname = "template-readme";
  vendorHash = "sha256-VEdbG6QrAfGBTXCrH5crQ1gg8M0ewlPQjQ/UsDYMFEs=";
  description = "Enterprise-grade README generation workflow orchestration platform";
  mainProgram = "readme-generator";
}
