{
  mkGoTool,
  src,
}:
mkGoTool {
  inherit src;
  pname = "library-policy";
  vendorHash = "";
  description = "Library governance system for detecting banned/vulnerable Go libraries";
}
