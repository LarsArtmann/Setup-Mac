# env.nu for nushell
# Environment variables configuration

# Define path components
let home = "/Users/larsartmann"
let homebrew_bin = "/opt/homebrew/bin"
let homebrew_sbin = "/opt/homebrew/sbin"
let google_cloud = "/opt/homebrew/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/bin"
let nix = $"($home)/.nix-profile/bin"
let nix_darwin = "/run/current-system/sw/bin"
let nix_other = "/nix/var/nix/profiles/default/bin"
let user_local_bin = "/usr/local/bin"
let user_bin = "/usr/bin"
let bin = "/bin"
let sbin = "/sbin"
let jet_brains = $"($home)/Library/Application Support/JetBrains/Toolbox/scripts"
let local_bin = $"($home)/.local/bin"
let go_home = $"($home)/go/bin"
let bun_home = $"($home)/.bun/bin"
let turso_home = $"($home)/.turso"

# Set PATH environment variable
$env.PATH = [
  $homebrew_bin
  $homebrew_sbin
  $google_cloud
  $nix
  $nix_darwin
  $nix_other
  $user_local_bin
  $user_bin
  $bin
  $sbin
  $jet_brains
  $local_bin
  $go_home
  $bun_home
  $turso_home
]
