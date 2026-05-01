{
  mkGoTool,
  src,
}:
mkGoTool {
  inherit src;
  pname = "project-meta";
  vendorHash = "";
  description = "Per-project metadata management tool with tags and importance ratings";
  mainProgram = "meta";
}
