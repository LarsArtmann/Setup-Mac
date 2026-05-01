{
  mkGoTool,
  src,
}:
mkGoTool {
  inherit src;
  pname = "go-auto-upgrade";
  vendorHash = "sha256-Ej5RdNg6kqmSlOWkBR7tMoyZ8GkIENh829ToqOHHcHw=";
  description = "Automate Go library upgrades with import rewrites and breaking change detection";
}
