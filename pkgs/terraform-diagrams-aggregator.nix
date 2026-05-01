{
  mkGoTool,
  src,
}:
mkGoTool {
  inherit src;
  pname = "terraform-diagrams-aggregator";
  vendorHash = "sha256-XL1FvUvkh5FOPOQ13KZvN4v17JKyjIxe0u4eoANyxJA=";
  description = "Generate visual dependency diagrams from Terraform configurations";
}
