# WrapperTemplates.nix - TEMPLATE SYSTEM FOR WRAPPER GENERATION
# AUTOMATED TEMPLATE-BASED WRAPPER CREATION

{ lib, pkgs, State, Types, Validation, ... }:

let
  # TEMPLATE ENGINE - TYPE-SAFE TEMPLATE PROCESSING
  TemplateEngine = { template, variables }:
    let
      requiredVars = lib.filter (v: v.required) variables;
      providedVars = lib.attrNames variables;

      validateVariables = var:
        let
          isProvided = lib.any (pv: pv.name == var.name) providedVars;
          hasDefault = var.default != null;
        in isProvided || hasDefault;

      allValid = lib.all validateVariables requiredVars;
      missingVars = lib.filter (v: !validateVariables v) requiredVars;

      processTemplate = content: vars:
        let
          replaceVar = content: varName:
            let
              var = lib.findSingle (v: v.name == varName) vars;
              value = if var != null then var.default else "";
            in
              if builtins.isString content then
                builtins.replaceStrings ["${${varName}}"] [value] content
              else content;

          processedContent = lib.foldl' replaceVar content (lib.attrNames vars);
        in processedContent;

    in {
      allValid = allValid;
      missingVars = missingVars;
      process = processTemplate;
    };

  # TEMPLATE GENERATORS - TYPE-SAFE TEMPLATES

  # CLI Tool Template
  CliToolTemplate = {
    name = "cli-tool";
    type = "cli-tool";
    template = ./templates/cli-tool.nix;
    variables = [
      {
        name = "packageName";
        type = "str";
        required = true;
        description = "Package name in nixpkgs";
      }
      {
        name = "wrapperName";
        type = "str";
        required = true;
        description = "Wrapper name identifier";
      }
      {
        name = "description";
        type = "str";
        default = "Command-line tool wrapper";
        description = "Wrapper description";
      }
      {
        name = "additionalPackages";
        type = "list";
        default = [];
        description = "Additional dependencies";
      }
      {
        name = "aliasName";
        type = "str";
        default = "";
        description = "Optional alias name";
      }
    ];
    examples = [
      {
        name = "starship-wrapper";
        type = "cli-tool";
        package = pkgs.starship;
        config = {
          additionalPackages = [pkgs.fish];
          aliasName = "sp";
          description = "Starship prompt wrapper with Fish integration";
        };
      }
      {
        name = "rg-wrapper";
        type = "cli-tool";
        package = pkgs.ripgrep;
        config = {
          additionalPackages = [pkgs.bat];
          aliasName = "rgb";
          description = "Ripgrep wrapper with bat output";
        };
      }
    ];
  };

  # GUI App Template
  GuiAppTemplate = {
    name = "gui-app";
    type = "gui-app";
    template = ./templates/gui-app.nix;
    variables = [
      {
        name = "appName";
        type = "str";
        required = true;
        description = "Application bundle name";
      }
      {
        name = "packageSource";
        type = "enum";
        required = true;
        description = "Package source (nixpkgs, url, local)";
        values = ["nixpkgs" "url" "local"];
      }
      {
        name = "configFiles";
        type = "list";
        default = [];
        description = "Configuration files to manage";
      }
      {
        name = "createIcon";
        type = "bool";
        default = true;
        description = "Create desktop icon";
      }
      {
        name = "createCliWrapper";
        type = "bool";
        default = true;
        description = "Create CLI wrapper for GUI app";
      }
    ];
    examples = [
      {
        name = "sublime-text-wrapper";
        type = "gui-app";
        package = pkgs.sublime-text;
        config = {
          packageSource = "nixpkgs";
          configFiles = ["Preferences.sublime-settings"];
          createIcon = true;
          createCliWrapper = true;
        };
      }
    ];
  };

  # Shell Template
  ShellTemplate = {
    name = "shell";
    type = "shell";
    template = ./templates/shell.nix;
    variables = [
      {
        name = "shellName";
        type = "str";
        required = true;
        description = "Shell name (fish, bash, zsh, nushell)";
      }
      {
        name = "shellPackage";
        type = "package";
        required = true;
        description = "Shell package";
      }
      {
        name = "shellAliases";
        type = "attrs";
        default = {};
        description = "Shell aliases to include";
      }
      {
        name = "shellFunctions";
        type = "attrs";
        default = {};
        description = "Shell functions to include";
      }
      {
        name = "completionPackages";
        type = "list";
        default = [];
        description = "Completion packages";
      }
    ];
    examples = [
      {
        name = "fish-enhanced";
        type = "shell";
        package = pkgs.fish;
        config = {
          shellName = "fish";
          shellAliases = {
            l = "ls -laSh";
            t = "tree -h -L 2";
          };
          shellFunctions = {
            mkcd = "mkdir -p $1 && cd $1";
          };
          completionPackages = [pkgs.fish-completions pkgs.carapace];
        };
      }
    ];
  };

  # Development Environment Template
  DevEnvTemplate = {
    name = "dev-env";
    type = "dev-env";
    template = ./templates/dev-env.nix;
    variables = [
      {
        name = "envName";
        type = "str";
        required = true;
        description = "Environment name (go, node, python, rust)";
      }
      {
        name = "languagePackage";
        type = "package";
        required = true;
        description = "Language package";
      }
      {
        name = "tools";
        type = "list";
        default = [];
        description = "Development tools to include";
      }
      {
        name = "environmentVariables";
        type = "attrs";
        default = {};
        description = "Environment variables";
      }
      {
        name = "pathAdditions";
        type = "list";
        default = [];
        description = "PATH additions";
      }
    ];
    examples = [
      {
        name = "go-enhanced";
        type = "dev-env";
        package = pkgs.go;
        config = {
          envName = "go";
          languagePackage = pkgs.go;
          tools = [pkgs.gopls pkgs.delve pkgs.air];
          environmentVariables = {
            GOPATH = "$HOME/go";
            GOBIN = "$HOME/go/bin";
          };
          pathAdditions = ["$HOME/go/bin"];
        };
      }
    ];
  };

  # Template Registry
  TemplateRegistry = {
    cli-tool = CliToolTemplate;
    gui-app = GuiAppTemplate;
    shell = ShellTemplate;
    dev-env = DevEnvTemplate;
  };

  # Template Generation Functions
  generateWrapper = templateType: wrapperConfig:
    let
      template = TemplateRegistry.${templateType} or (builtins.throw "Unknown template type: ${templateType}");
      engine = TemplateEngine {
        template = template.template;
        variables = template.variables;
      };

      # Merge template defaults with wrapper config
      mergedConfig = lib.recursiveUpdate template.defaultConfig or {} wrapperConfig;

      # Validate configuration against template
      validation = Validation.validateWrapper {
        name = wrapperConfig.name or "";
        package = wrapperConfig.package or null;
        type = templateType;
        config = mergedConfig;
      } "standard";

      # Process template with variables
      processedTemplate = if validation.overall.valid then
        engine.process (builtins.readFile template.template) {
          packageName = lib.getName (wrapperConfig.package or pkgs.hello);
          wrapperName = wrapperConfig.name or "unknown";
          description = wrapperConfig.description or "";
          additionalPackages = lib.concatStringsSep " " (map (p: lib.getName p) (wrapperConfig.additionalPackages or []));
        }
      else builtins.throw "Template validation failed: ${lib.concatStringsSep ", " (map (r: r.message) (lib.filter (r: !r.valid) validation.validationResults or []))}";

    in {
      template = template;
      config = mergedConfig;
      validation = validation;
      generated = processedTemplate;
      success = validation.overall.valid;
    };

  generateAllWrappers = wrapperConfigs:
    let
      generateSingle = config: generateWrapper config.type config;
      results = map generateSingle wrapperConfigs;
      successful = lib.filter (r: r.success) results;
      failed = lib.filter (r: !r.success) results;
    in {
      wrappers = results;
      successful = successful;
      failed = failed;
      successRate = (builtins.length successful) * 100.0 / (builtins.length results);
    };

in {
  inherit TemplateEngine TemplateRegistry generateWrapper generateAllWrappers;
}
