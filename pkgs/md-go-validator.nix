{
  mkGoTool,
  src,
}:
mkGoTool {
  inherit src;
  pname = "md-go-validator";
  vendorHash = "sha256-KianSfAsAZGOtu9nLIkmrU02XeKpvZmzl0jriYFAPMY=";
  description = "Validates code blocks in Markdown files (Go, TypeScript, Rust, Nix, HCL, Templ)";
}
