# 📋 TMUX CONFIGURATION FOR SETUP-MAC
{pkgs, ...}: {
  programs.tmux = {
    enable = true;
    clock24 = true;
    baseIndex = 1;
    sensibleOnTop = true;
    mouse = true;
    terminal = "screen-256color";
    historyLimit = 100000;
    escapeTime = 0;

    plugins = with pkgs; [
      tmuxPlugins.resurrect
      tmuxPlugins.yank
    ];

    extraConfig = ''
      # Setup-Mac specific keybindings
      bind c new-window -c "#{pane_current_path}"
      bind % split-window -h -c "#{pane_current_path}"
      bind '"' split-window -v -c "#{pane_current_path}"
      bind b last-window

      # Setup-Mac development session template
      bind D new-session -d -s Setup-Mac -n just "cd ~/Desktop/Setup-Mac && just" \; \
                       new-window -d -n nvim "cd ~/Desktop/Setup-Mac && nvim" \; \
                       new-window -d -n shell "cd ~/Desktop/Setup-Mac" \; \
                       select-window -t 0

      # Integration with Just commands
      bind J new-window -c "#{pane_current_path}" "cd ~/Desktop/Setup-Mac && just"
      bind T new-window -c "#{pane_current_path}" "cd ~/Desktop/Setup-Mac && just test"
      bind S new-window -c "#{pane_current_path}" "cd ~/Desktop/Setup-Mac && just switch"
      bind B new-window -c "#{pane_current_path}" "cd ~/Desktop/Setup-Mac && just benchmark"
      bind H new-window -c "#{pane_current_path}" "cd ~/Desktop/Setup-Mac && just health"

      # Session persistence for Setup-Mac
      set -g @resurrect-strategy-nvim 'session'
      set -g @resurrect-capture-pane-contents 'on'
      set -g @resurrect-save-bash-history 'on'
      set -g @resurrect-save-command-history 'on'
      set -g @resurrect-dir "$HOME/.local/share/tmux/resurrect"

      # Copy-paste improvements
      setw -g mode-keys vi
      bind P paste-buffer
      bind-key -T copy-mode-vi v send-keys -X begin-selection
      bind-key -T copy-mode-vi y send-keys -X copy-pipe-and-cancel "pbcopy"

      # Status bar customization
      set -g status-interval 1
      set -g status-justify centre
      set -g status-bg "#1e1e2e"
      set -g status-fg "#d4d4d4"
      set -g status-left "#[fg=green]#S#[fg=default] #I:#W "
      set -g status-right "#[fg=green]#(date '+%Y-%m-%d %H:%M')#[fg=default]"

      # Window/pane customization
      setw -g window-status-current-bg "#4a4a4a"
      setw -g window-status-current-fg "#ffffff"
      setw -g pane-active-border-style fg="#61afef"
      setw -g pane-border-style fg="#3b4252"

      # Pain-control enhancements
      bind-key -n M-left select-pane -L
      bind-key -n M-right select-pane -R
      bind-key -n M-up select-pane -U
      bind-key -n M-down select-pane -D

      # Mouse wheel scrolling
      bind -n WheelUpPane if-shell -F -t "#{pane_in_mode}" "send -M" "copy-mode -e"
      bind -n WheelDownPane if-shell -F -t "#{pane_in_mode}" "send -M" "copy-mode -e"
    '';
  };
}
