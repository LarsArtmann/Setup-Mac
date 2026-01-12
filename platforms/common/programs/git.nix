{config, pkgs, lib, ...}: {
  programs.git = {
    enable = true;
    lfs.enable = true;

    settings = {
      user = {
        name = "Lars Artmann";
        email = "git@lars.software";
      };

      signing = {
        key = "76687BB69B36BFB1B1C58FA878B4350389C71333";
        signByDefault = true;
      };

      core = {
        autocrlf = "input";
        compression = 9;
        packedGitLimit = "512m";
        packedGitWindowSize = "512m";
        pager = "cat";
        quotePath = false;
        editor = "code --wait";
      };

      commit.gpgsign = true;
      tag.gpgsign = true;

      submodule = {
        fetchJobs = 8;
      };

      http = {
        postBuffer = 524288000;
      };

      ssh = {
        multiplexing = true;
      };

      pull = {
        rebase = true;
      };

      push = {
        autoSetupRemote = true;
      };

      gpg = {
        program = "/run/current-system/sw/bin/gpg";
      };

      "git-town" = {
        "sync-perennial-strategy" = "rebase";
      };

      pager = {
        diff = "bat";
      };

      init = {
        defaultBranch = "master";
      };

      url = {
        "git@github.com:" = {
          insteadOf = "https://github.com/";
        };
      };

      gc = {
        auto = 6700;
        autopacklimit = 50;
        autodetach = true;
        pruneexpire = "2 weeks ago";
      };

      credential = {
        helper = "store";
      };

      "coderabbit" = {
        machineId = "cli/98a25a4615614fc5ae0c8a2718076dca";
      };

      safe = {
        "directory" = [
          "/Users/larsartmann/projects/todo-list-ai"
          "/Users/larsartmann/projects"
        ];
      };

      alias = {
        append = "town append";
        compress = "town compress";
        contribute = "town contribute";
        diff-parent = "town diff-parent";
        hack = "town hack";
        observe = "town observe";
        park = "town park";
        prepend = "town prepend";
        propose = "town propose";
        rename = "town rename";
        repo = "town repo";
        set-parent = "town set-parent";
        ship = "town ship";
        sync = "town sync";
        down = "town down";
        up = "town up";
      };
    };

    ignores = [
      # macOS system files
      ".DS_Store"
      ".DS_Store?"
      "._*"
      ".Spotlight-V100"
      ".Trashes"
      "ehthumbs.db"
      "Thumbs.db"

      # IDE and editor files
      ".vscode/"
      ".idea/"
      "*.swp"
      "*.swo"
      "*~"

      # Temporary files
      "*.tmp"
      "*.temp"
      ".cache/"
      ".temp/"

      # Build artifacts
      "dist/"
      "build/"
      "target/"
      "*.log"
      "*.pid"

      # Node.js
      "node_modules/"
      "npm-debug.log*"
      "yarn-debug.log*"
      "yarn-error.log*"

      # Python
      "__pycache__/"
      "*.py[cod]"
      "*$py.class"
      "*.so"
      ".Python"
      "env/"
      "venv/"
      ".venv/"
      "pip-log.txt"
      "pip-delete-this-directory.txt"

      # Go
      "*.exe"
      "*.exe~"
      "*.dll"
      "*.so"
      "*.dylib"
      "*.test"
      "*.out"
      "go.work"

      # Rust
      "target/"
      "Cargo.lock"

      # Java
      "*.class"
      "*.jar"
      "*.war"
      "*.ear"
      "*.zip"
      "*.tar.gz"
      "*.rar"
      "hs_err_pid*"

      # C/C++
      "*.o"
      "*.a"
      "*.so"
      "*.out"

      # Environment and secrets
      ".env"
      ".env.local"
      ".env.private"
      "*.key"
      "*.pem"
      "*.p12"
      "*.pfx"

      # Backup files
      "*.bak"
      "*.backup"
      "*~"

      # Compressed files
      "*.7z"
      "*.dmg"
      "*.gz"
      "*.iso"
      "*.rar"
      "*.tar"
      "*.zip"

      # Logs
      "logs/"
      "*.log"

      # Generated files
      "*_templ.go" ## https://templ.guide/
      "*.sql.go" ## https://sqlc.dev
    ];
  };
}
