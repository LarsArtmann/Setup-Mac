{
  mkGoTool,
  src,
}:
mkGoTool {
  inherit src;
  pname = "projects-management-automation";
  vendorHash = "sha256-duYSf8bA3lVMp49BBuNSVQB91u8tgrD4UYnKbSZvHWE=";
  description = "CLI tool for discovering and managing multiple projects with automated Git operations and AI-powered commits";
}
