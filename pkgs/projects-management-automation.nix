{
  mkGoTool,
  src,
}:
mkGoTool {
  inherit src;
  pname = "projects-management-automation";
  vendorHash = "";
  description = "CLI tool for discovering and managing multiple projects with automated Git operations and AI-powered commits";
}
