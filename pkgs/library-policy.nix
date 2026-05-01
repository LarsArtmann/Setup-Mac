{
  mkGoTool,
  src,
}:
mkGoTool {
  inherit src;
  pname = "library-policy";
  vendorHash = "sha256-ijC7/7HinLWWO/IAupgkMCCGg3jJlWSc9iOaRkDLt6g=";
  description = "Library governance system for detecting banned/vulnerable Go libraries";
}
