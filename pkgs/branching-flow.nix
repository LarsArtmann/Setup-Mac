{
  mkGoTool,
  src,
}:
mkGoTool {
  inherit src;
  pname = "branching-flow";
  vendorHash = "sha256-eQALDafez+UVw51P/mtuJ3IV/vNpsB2tX4eZdDvAJ+o=";
  description = "Go CLI analyzer for code quality issues: error context loss, type safety, structural patterns, duplication";
}
