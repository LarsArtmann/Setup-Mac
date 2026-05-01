{
  mkGoTool,
  src,
}:
mkGoTool {
  inherit src;
  pname = "auto-deduplicate";
  vendorHash = "sha256-hbzFZ6mZDm+EAfWpIYwyy9QtRI7uiqtJXmAGkKCNhWo=";
  description = "Automated file deduplication tool with content-addressable storage";
}
