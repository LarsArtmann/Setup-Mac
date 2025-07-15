{ lib, ... }: {
  # STARSHIP CONFIGURATION: Performance-optimized for Fish + Carapace + Starship
  programs.starship = {
    enable = true;
    settings = {
      # PERFORMANCE: Optimized for 500ms 95%tile budget
      command_timeout = 400; # Parallel execution, max 400ms total
      scan_timeout = 100; # Thorough project detection

      # FORMAT: Enhanced prompt with performance budget
      format = lib.concatStrings [
        "$directory"
        "$git_branch"
        "$git_status"
        "$golang"
        "$nodejs"
        "$cmd_duration"
        "$character"
      ];

      # DIRECTORY: Minimal path display
      directory = {
        truncation_length = 1;
        truncation_symbol = "";
        truncate_to_repo = false;
        style = "bold cyan";
        read_only = " 🔒";
      };

      # GIT BRANCH: Fast git operations
      git_branch = {
        symbol = "";
        style = "bold green";
        format = "[$symbol$branch]($style)";
        truncation_length = 10;
        truncation_symbol = "…";
      };

      # GIT STATUS: Simplified status with fast checks
      git_status = {
        format = "[$all_status]($style)";
        style = "bold green";
        ahead = "⇡";
        behind = "⇣";
        diverged = "⇕";
        conflicted = "=";
        deleted = "✘";
        renamed = "»";
        modified = "+";
        staged = "+";
        untracked = "?";
        ignore_submodules = true; # Disable slow operations
      };

      # GOLANG: Show when in Go projects
      golang = {
        disabled = false;
        symbol = "🐹 ";
        style = "bold cyan";
      };

      # NODEJS: Show when in Node projects
      nodejs = {
        disabled = false;
        symbol = "⬢ ";
        style = "bold green";
      };

      # COMMAND DURATION: Show for long commands
      cmd_duration = {
        disabled = false;
        min_time = 2000; # Show duration for commands >2s
        style = "bold yellow";
      };

      # CHARACTER: Simple prompt character
      character = {
        success_symbol = "[❯](bold green)";
        error_symbol = "[❯](bold red)";
        vicmd_symbol = "[❮](bold yellow)";
      };

      # DISABLE ALL UNNECESSARY MODULES for maximum performance
      aws.disabled = true;
      azure.disabled = true;
      battery.disabled = true;
      buf.disabled = true;
      c.disabled = true;
      cmake.disabled = true;
      cobol.disabled = true;
      conda.disabled = true;
      container.disabled = true;
      crystal.disabled = true;
      daml.disabled = true;
      dart.disabled = true;
      deno.disabled = true;
      docker_context.disabled = true;
      dotnet.disabled = true;
      elixir.disabled = true;
      elm.disabled = true;
      env_var.disabled = true;
      erlang.disabled = true;
      gcloud.disabled = true;
      git_commit.disabled = true;
      git_state.disabled = true;
      haskell.disabled = true;
      helm.disabled = true;
      hostname.disabled = true;
      java.disabled = true;
      julia.disabled = true;
      kotlin.disabled = true;
      kubernetes.disabled = true;
      line_break.disabled = true;
      lua.disabled = true;
      memory_usage.disabled = true;
      nim.disabled = true;
      nix_shell.disabled = true;
      ocaml.disabled = true;
      openstack.disabled = true;
      package.disabled = true;
      perl.disabled = true;
      php.disabled = true;
      pulumi.disabled = true;
      purescript.disabled = true;
      python.disabled = true;
      red.disabled = true;
      ruby.disabled = true;
      rust.disabled = true;
      scala.disabled = true;
      shell.disabled = true;
      shlvl.disabled = true;
      singularity.disabled = true;
      swift.disabled = true;
      terraform.disabled = true;
      time.disabled = true;
      username.disabled = true;
      vagrant.disabled = true;
      vlang.disabled = true;
      vcsh.disabled = true;
      zig.disabled = true;
    };
  };
}
