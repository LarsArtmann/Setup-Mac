{
  mkGoTool,
  src,
}:
mkGoTool {
  inherit src;
  pname = "auto-deduplicate";
  vendorHash = "";
  description = "Automated file deduplication tool with content-addressable storage";
}
