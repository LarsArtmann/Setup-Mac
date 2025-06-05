{ pkgs, lib, nix-jetbrains-plugins, ... }:

let
  system = pkgs.stdenv.hostPlatform.system;
  
  # Convenience function from nix-jetbrains-plugins
  buildIdeWithPlugins = nix-jetbrains-plugins.lib."${system}".buildIdeWithPlugins;
  
  # Common plugins that are useful across most JetBrains IDEs
  commonPluginIds = [
    "com.intellij.plugins.watcher"        # File Watcher - monitor file changes
    "com.kstenschke.shifter"              # Shifter - smart text manipulation
    "mobi.hsz.idea.gitignore"             # .ignore - gitignore support
    "String Manipulation"                 # String manipulation utilities
    "org.jetbrains.plugins.github"       # GitHub integration
    "HighlightBracketPair"               # Highlight matching brackets
    "IdeaVIM"                             # Vim emulation
  ];
  
  # Language-specific plugins for relevant IDEs
  kotlinPluginIds = [
    "org.jetbrains.kotlin"                # Kotlin language support
  ];
  
  goPluginIds = [
    "org.jetbrains.plugins.go"           # Go language support
  ];
  
  rustPluginIds = [
    "org.rust.lang"                       # Rust language support
  ];

in
{
  environment.systemPackages = with pkgs; [
    # IntelliJ IDEA Ultimate with plugins
    (buildIdeWithPlugins jetbrains "idea-ultimate" (commonPluginIds ++ kotlinPluginIds))
    
    # WebStorm with common plugins
    (buildIdeWithPlugins jetbrains "webstorm" commonPluginIds)
    
    # GoLand with Go-specific plugins
    (buildIdeWithPlugins jetbrains "goland" (commonPluginIds ++ goPluginIds))
    
    # Rider with common plugins (.NET development)
    (buildIdeWithPlugins jetbrains "rider" commonPluginIds)
  ];
}