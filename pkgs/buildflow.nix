{
  mkGoTool,
  src,
}:
mkGoTool {
  inherit src;
  pname = "buildflow";
  vendorHash = "";
  description = "Zero-configuration build automation tool for Go projects with 40 type-safe steps";
  mainProgram = "buildflow";
}
