{ pkgs, ... }: {
  users = {
    #error: The option `users.defaultUserShell' does not exist.?? defaultUserShell = pkgs.nushell;
    users.larsartmann = {
      shell = pkgs.nushell;
    };
  };
}
