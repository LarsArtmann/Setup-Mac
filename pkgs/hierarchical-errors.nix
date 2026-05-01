{
  mkGoTool,
  src,
}:
mkGoTool {
  inherit src;
  pname = "hierarchical-errors";
  vendorHash = "sha256-3Nz+BRK3SBOYke6UItJBnlR8jZ6gZrWIY0mRjBF8Pxc=";
  description = "Static analysis tool for error handling patterns, hierarchies, and violations in Go";
}
