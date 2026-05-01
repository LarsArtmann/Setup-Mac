{
  mkGoTool,
  src,
}:
mkGoTool {
  inherit src;
  pname = "go-auto-upgrade";
  vendorHash = "";
  description = "Automate Go library upgrades with import rewrites and breaking change detection";
}
