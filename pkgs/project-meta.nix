{
  mkGoTool,
  src,
}:
mkGoTool {
  inherit src;
  pname = "project-meta";
  vendorHash = "sha256-kon/uDx/Nx3IJjUCvegotGbpnIBVsB7/R8xEK2SjnC0=";
  description = "Per-project metadata management tool with tags and importance ratings";
  mainProgram = "meta";
}
