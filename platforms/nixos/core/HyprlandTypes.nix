# Ghost Systems: Hyprland Type Safety Module
# Comprehensive type definitions and validation for Hyprland configuration
{lib}: let
  # ---------------------------------------------------------------------------
  # Validation Functions (defined first, used by other helpers)
  # ---------------------------------------------------------------------------
  # Validate Hyprland configuration syntax and semantics
  validateHyprlandConfig = config: let
    # Extract relevant config sections
    variables = config.variables or {};
    monitors = lib.toList (config.monitor or []);
    workspaces = config.workspaces or [];

    # Check for required variables
    requiredVars = ["$mod"];
    missingVars = lib.filter (var: !builtins.hasAttr var variables) requiredVars;

    # Validate monitor format: name,resolution,position,scale
    validMonitorFormat = monitor: let
      parts = lib.splitString "," monitor;
    in
      builtins.length parts >= 3;

    invalidMonitors = lib.filter (m: !validMonitorFormat m) monitors;

    # Validate workspace format: id[,name:Name]
    validWorkspaceFormat = workspace: let
      parts = lib.splitString "," workspace;
      idStr = builtins.head parts;
    in
      builtins.match "^[0-9]+" idStr != null;

    invalidWorkspaces = lib.filter (w: !validWorkspaceFormat w) workspaces;

    # Validate bezier curve format: name,x1,y1,x2,y2
    validBezierFormat = bezier: let
      parts = lib.splitString "," bezier;
    in
      builtins.length parts
      == 5
      && builtins.match "^[0-9\\.]+$" (builtins.elemAt parts 1) != null
      && builtins.match "^[0-9\\.]+$" (builtins.elemAt parts 2) != null
      && builtins.match "^[0-9\\.]+$" (builtins.elemAt parts 3) != null
      && builtins.match "^[0-9\\.]+$" (builtins.elemAt parts 4) != null;

    bezier = (config.animations or {}).bezier or "";
    bezierValid = bezier == "" || validBezierFormat bezier;
  in {
    # Overall validity
    valid =
      builtins.length missingVars
      == 0
      && builtins.length invalidMonitors == 0
      && builtins.length invalidWorkspaces == 0
      && bezierValid;

    # Detailed error information
    errors = {
      missingVars =
        if builtins.length missingVars > 0
        then "Missing required variables: ${builtins.toJSON missingVars}"
        else null;

      invalidMonitors =
        if builtins.length invalidMonitors > 0
        then "Invalid monitor format: ${builtins.toJSON invalidMonitors}"
        else null;

      invalidWorkspaces =
        if builtins.length invalidWorkspaces > 0
        then "Invalid workspace format: ${builtins.toJSON invalidWorkspaces}"
        else null;

      invalidBezier =
        if !bezierValid
        then "Invalid bezier format: ${bezier}"
        else null;
    };

    # Human-readable error messages
    errorMessages = lib.filter (msg: msg != null) [
      (
        if builtins.length missingVars > 0
        then "❌ Missing required variables: ${lib.concatStringsSep ", " missingVars}"
        else null
      )
      (
        if builtins.length invalidMonitors > 0
        then "❌ Invalid monitor format: ${lib.concatStringsSep ", " invalidMonitors}"
        else null
      )
      (
        if builtins.length invalidWorkspaces > 0
        then "❌ Invalid workspace format: ${lib.concatStringsSep ", " invalidWorkspaces}"
        else null
      )
      (
        if !bezierValid
        then "❌ Invalid bezier curve format"
        else null
      )
    ];
  };
in {
  # ---------------------------------------------------------------------------
  # Type Definitions
  # ---------------------------------------------------------------------------

  # Hyprland configuration type with full type safety
  HyprlandConfig = lib.types.submodule {
    options = {
      # Variable definitions ($mod, $terminal, etc.)
      variables = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;
        default = {
          "$mod" = "SUPER";
          "$terminal" = "kitty";
          "$menu" = "rofi -show drun -show-icons";
        };
        description = "Hyprland variable definitions (e.g., $mod, $terminal)";
        example = {
          "$mod" = "SUPER";
          "$terminal" = "kitty";
          "$menu" = "rofi -show drun";
        };
      };

      # Monitor configuration
      monitor = lib.mkOption {
        type = lib.types.oneOf [
          lib.types.str
          (lib.types.listOf lib.types.str)
        ];
        default = [];
        description = "Monitor configuration(s) in format: name,resolution,position,scale";
        example = "HDMI-A-1,preferred,auto,1.25";
      };

      # Workspace definitions
      workspaces = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        description = "Workspace definitions with optional naming";
        example = [
          "1, name:💻 Dev"
          "2, name:🌐 Web"
        ];
      };

      # Window rules (windowrulev2)
      windowRules = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        description = "Window rule definitions";
        example = [
          "float, class:^(pavucontrol)$"
          "workspace 5, class:^(discord)$"
        ];
      };

      # Keybindings (bind)
      keybindings = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        description = "Keybinding definitions";
        example = [
          "$mod, Return, exec, kitty"
          "$mod, D, exec, rofi -show drun"
        ];
      };

      # Mouse bindings (bindm)
      mouseBindings = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        description = "Mouse binding definitions";
        example = [
          "$mod, mouse:272, movewindow"
          "$mod, mouse:273, resizewindow"
        ];
      };

      # General settings
      general = lib.mkOption {
        type = lib.types.submodule {
          options = {
            gaps_in = lib.mkOption {
              type = lib.types.int;
              default = 5;
              description = "Inner gaps between windows";
            };
            gaps_out = lib.mkOption {
              type = lib.types.int;
              default = 20;
              description = "Outer gaps between windows";
            };
            border_size = lib.mkOption {
              type = lib.types.int;
              default = 2;
              description = "Border size";
            };
            layout = lib.mkOption {
              type = lib.types.str;
              default = "dwindle";
              description = "Layout algorithm";
            };
          };
        };
        default = {};
        description = "General Hyprland settings";
      };

      # Decoration settings
      decoration = lib.mkOption {
        type = lib.types.submodule {
          options = {
            rounding = lib.mkOption {
              type = lib.types.int;
              default = 8;
              description = "Corner rounding";
            };
            blur = lib.mkOption {
              type = lib.types.submodule {
                options = {
                  enabled = lib.mkOption {
                    type = lib.types.bool;
                    default = true;
                    description = "Enable blur effect";
                  };
                  size = lib.mkOption {
                    type = lib.types.int;
                    default = 3;
                    description = "Blur radius";
                  };
                  passes = lib.mkOption {
                    type = lib.types.int;
                    default = 1;
                    description = "Number of blur passes";
                  };
                };
              };
              default = {};
              description = "Blur settings";
            };
          };
        };
        default = {};
        description = "Decoration settings";
      };

      # Animation settings
      animations = lib.mkOption {
        type = lib.types.submodule {
          options = {
            enabled = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = "Enable animations";
            };
            bezier = lib.mkOption {
              type = lib.types.str;
              default = "myBezier, 0.25, 0.46, 0.45, 0.94";
              description = "Bezier curve definitions";
            };
            animation = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [];
              description = "Animation definitions";
            };
          };
        };
        default = {};
        description = "Animation settings";
      };

      # Input settings
      input = lib.mkOption {
        type = lib.types.submodule {
          options = {
            kb_layout = lib.mkOption {
              type = lib.types.str;
              default = "us";
              description = "Keyboard layout";
            };
            follow_mouse = lib.mkOption {
              type = lib.types.int;
              default = 1;
              description = "Mouse follow behavior";
            };
            repeat_delay = lib.mkOption {
              type = lib.types.int;
              default = 250;
              description = "Keyboard repeat delay (ms)";
            };
            repeat_rate = lib.mkOption {
              type = lib.types.int;
              default = 40;
              description = "Keyboard repeat rate (keys/s)";
            };
          };
        };
        default = {};
        description = "Input settings";
      };

      # Exec-once commands
      execOnce = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        description = "Commands to execute on startup";
        example = [
          "waybar"
          "dunst"
        ];
      };
    };
  };

  # ---------------------------------------------------------------------------
  # Type-Safe Helper Functions
  # ---------------------------------------------------------------------------
  inherit validateHyprlandConfig;

  # Create a type-safe keybinding
  mkKeybinding = mod: key: action: let
    parts = lib.splitString "," action;
    prefix = "${mod}, ${key}";
  in
    if builtins.length parts >= 2
    then lib.concatStringsSep ", " ([prefix] ++ parts)
    else "${prefix}, ${action}";

  # Create a type-safe workspace definition
  mkWorkspace = id: name: let
    namePart =
      if name != null
      then ", name:${name}"
      else "";
  in "${builtins.toString id}${namePart}";

  # Create a type-safe window rule
  mkWindowRule = rule: selector: let
    parts = lib.splitString "," selector;
  in
    if builtins.length parts >= 2
    then lib.concatStringsSep ", " ([rule] ++ parts)
    else "${rule}, ${selector}";

  # ---------------------------------------------------------------------------
  # Assertion Helpers
  # ---------------------------------------------------------------------------

  # Create assertion for Hyprland configuration
  mkAssertion = config: {
    assertion = (validateHyprlandConfig config).valid;
    message =
      lib.concatStringsSep "\n" ((validateHyprlandConfig config).errorMessages
        ++ ["\n💡 Use 'nix flake show' or 'just test-fast' to debug"]);
  };

  # ---------------------------------------------------------------------------
  # Nix Integration Helpers
  # ---------------------------------------------------------------------------

  # Convert Nix attrs to Hyprland-compatible configuration
  # This is used internally by Home Manager's lib.generators.toHyprlang
  toHyprlang = lib.generators.toHyprlang {};
}
