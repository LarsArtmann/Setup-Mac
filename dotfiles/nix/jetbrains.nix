{ pkgs, lib, nix-jetbrains-plugins, ... }:

let
  system = pkgs.stdenv.hostPlatform.system;
  
  # Convenience function from nix-jetbrains-plugins
  buildIdeWithPlugins = nix-jetbrains-plugins.lib."${system}".buildIdeWithPlugins;
  
  # Common plugins that are useful across most JetBrains IDEs
  # Plugin IDs from JetBrains Marketplace (shown at bottom of plugin pages)
  commonPluginIds = [
    "com.intellij.plugins.watcher"        # File Watcher - monitor file changes
    "mobi.hsz.idea.gitignore"             # .ignore - gitignore and other ignore files support
    "org.jetbrains.plugins.github"       # GitHub integration (if not built-in)
  ];
  
  # Popular additional plugins (using proper plugin IDs)
  enhancementPluginIds = [
    "IdeaVIM"                             # Vim emulation (plugin ID: IdeaVIM)
    "String Manipulation"                 # String manipulation utilities
  ];

in
{
  environment.systemPackages = with pkgs; [
    # Start with the most commonly used IDEs
    
    # IntelliJ IDEA Ultimate - primary IDE for Java/Kotlin development
    (buildIdeWithPlugins jetbrains "idea-ultimate" commonPluginIds)
    
    # WebStorm - for web development (JavaScript, TypeScript, etc.)
    (buildIdeWithPlugins jetbrains "webstorm" commonPluginIds)
    
    # Uncomment additional IDEs as needed:
    # GoLand for Go development
    # (buildIdeWithPlugins jetbrains "goland" commonPluginIds)
    
    # Rider for .NET development  
    # (buildIdeWithPlugins jetbrains "rider" commonPluginIds)
  ];
  
  # Note: Plugin IDs can be found at the bottom of JetBrains Marketplace pages
  # Example: https://plugins.jetbrains.com/plugin/7374-gitignore -> ID: mobi.hsz.idea.gitignore
}