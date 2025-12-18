{ lib, pkgs, ... }:
{
  # Use common Nix settings - eliminate duplication
  imports = [ ../common/core/nix-settings.nix ];

  # Darwin-specific Nix settings only
  nix.extraOptions = ''
    # Darwin-specific overlay paths
    darwin.extra-sandbox-paths = "/System/Library/Frameworks /System/Library/PrivateFrameworks /usr/lib /usr/include /dev /bin/sh /bin/bash /bin/csh /bin/tcsh /bin/zsh /bin/ksh"
  '';
}