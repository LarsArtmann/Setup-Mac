{
  mkGoTool,
  src,
}:
mkGoTool {
  inherit src;
  pname = "terraform-to-d2";
  vendorHash = "sha256-cxzscyEZYOMoLIJ9SpDprnG0BLyv6RB8488QNbfj5TA=";
  description = "Visualize cloud infrastructure as D2 diagrams from Terraform HCL code";
}
