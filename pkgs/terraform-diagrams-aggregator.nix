{
  mkGoTool,
  src,
}:
mkGoTool {
  inherit src;
  pname = "terraform-diagrams-aggregator";
  vendorHash = "";
  description = "Generate visual dependency diagrams from Terraform configurations";
}
