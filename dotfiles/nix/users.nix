{ pkgs, ... }: {
  users = {
    # TODO: https://mynixos.com/nix-darwin/options/users
    #error: The option `users.defaultUserShell' does not exist.?? defaultUserShell = pkgs.nushell;
    users.larsartmann = {
      shell = pkgs.fish;
    };
  };
}
