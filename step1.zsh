# Sudo
sudo -i

# Nix
sh <(curl -L https://nixos.org/nix/install)

# LnL7/nix-darwin
sudo mkdir -p /etc/nix-darwin
sudo chown $(id -nu):$(id -ng) /etc/nix-darwin
cd /etc/nix-darwin

# To use Nixpkgs:
nix --extra-experimental-features "nix-command flakes" flake init -t nix-darwin/master

sed -i '' "s/simple/$(scutil --get LocalHostName)/" flake.nix

nix --extra-experimental-features "nix-command flakes" run nix-darwin/master#darwin-rebuild -- switch

/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"

