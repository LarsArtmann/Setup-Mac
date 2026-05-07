go-output-src: let
  subModules = ["enum" "escape" "table" "sort"];
  owner = "github.com/larsartmann/go-output";
  lines =
    builtins.concatMap (sub: [
      "echo \"require ${owner}/${sub} v0.0.0\" >> go.mod"
      "echo \"replace ${owner}/${sub} => ${go-output-src}/${sub}\" >> go.mod"
    ])
    subModules;
in
  builtins.concatStringsSep "\n    " lines
