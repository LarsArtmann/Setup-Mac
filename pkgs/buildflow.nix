{
  mkGoTool,
  src,
}:
mkGoTool {
  inherit src;
  pname = "buildflow";
  vendorHash = "sha256-l8zFhMIfyHYRfWqPwwOfFO2JVj9VU3ja7bO61JYLTVk=";
  description = "Zero-configuration build automation tool for Go projects with 40 type-safe steps";
  mainProgram = "buildflow";
}
