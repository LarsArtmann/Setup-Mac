{
  mkGoTool,
  src,
}:
mkGoTool {
  inherit src;
  pname = "terraform-to-d2";
  vendorHash = "";
  description = "Visualize cloud infrastructure as D2 diagrams from Terraform HCL code";
}
