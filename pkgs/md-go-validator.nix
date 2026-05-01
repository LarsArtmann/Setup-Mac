{
  mkGoTool,
  src,
}:
mkGoTool {
  inherit src;
  pname = "md-go-validator";
  vendorHash = "";
  description = "Validates code blocks in Markdown files (Go, TypeScript, Rust, Nix, HCL, Templ)";
}
