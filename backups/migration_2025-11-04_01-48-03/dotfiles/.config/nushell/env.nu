# env.nu for nushell
# Environment variables configuration

# Ensure nushell inherits the system PATH from nix-darwin
# This approach ensures consistency across shells

# Get the system PATH from the environment
# This will capture the PATH set by nix-darwin
let system_path = $env.PATH?

# If we have a system PATH, use it
if $system_path != null {
  # PATH is already a list in nushell
  $env.PATH = $system_path
} else {
  # Fallback minimal PATH if system PATH is not available
  $env.PATH = [
    "/opt/homebrew/bin"
    "/opt/homebrew/sbin"
    "/usr/local/bin"
    "/usr/bin"
    "/bin"
    "/usr/sbin"
    "/sbin"
  ]
}

# Set other environment variables as needed
$env.EDITOR = "nano"
$env.LANG = "en_GB.UTF-8"

# Fix GitHub CLI pager issues by disabling pager
$env.GH_PAGER = ""

# Set JAVA_HOME explicitly since it's not being set by nix-darwin
$env.JAVA_HOME = (which java | get path | path dirname | path dirname)

# Debug: Uncomment to see the PATH when nushell starts
# print $"PATH: ($env.PATH | str join ':')"
