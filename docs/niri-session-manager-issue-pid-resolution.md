# Feature: Resolve window PIDs to actual process commands for accurate restore

## Problem

When restoring a session, `niri-session-manager` spawns apps by their `app_id` (e.g. `kitty`, `foot`). For terminals, this always opens a bare shell — losing whatever was running inside (e.g. `btop`, `nvim`, a project-specific `cd` + build command, a `ssh` session).

This is listed as a TODO in the README: "Use PID to fetch the actual process command."

## Proposed Solution

During the **save** phase, walk `/proc` for each terminal window's PID to capture:

1. **Child process command** — skip intermediate shells (fish, bash, zsh, sh, dash) and find the actual foreground process (btop, nvim, ssh, etc.)
2. **Child process CWD** — `readlink /proc/<child_pid>/cwd`
3. **Original spawn args** — `/proc/<pid>/cmdline` (split by `\0`) to detect `-e` flags like `kitty -e btop`

During the **restore** phase, re-spawn terminals with the recovered command:

```bash
kitty --directory /path/to/project -e sh -c "btop; exec fish"
```

### Process tree walking algorithm

```text
For each terminal window PID:
1. Read /proc/<pid>/cmdline → original spawn args
2. Walk children via /proc/<pid>/task/<tid>/children or pgrep -P
3. For each child:
   a. Read /proc/<child>/comm → process name
   b. If comm matches known shells (fish|bash|zsh|sh|dash) → descend further
   c. If comm matches known terminals' internal helpers (kitten) → descend further
   d. Otherwise → this is the foreground process; capture its cmdline + cwd
4. Fallback: read /proc/<child>/stat field 8 (tpgid) for foreground process group
5. Filter out shell startup artifacts (e.g. __atexit__ commands from fish)
```

### Edge cases

- **No child process** → restore bare terminal (current behavior)
- **Shell-only** (user just has fish running) → restore bare terminal
- **Multiple nesting levels** (e.g. kitty → fish → sudo → btop) → walk up to 20 levels, skip shells/sudo/doas
- **Process exited between save and restore** → gracefully fall back to bare terminal
- **`__atexit__` commands** → filter these out (fish startup artifact, not a real command)

## Proof of Concept

I have a working bash implementation that does exactly this in a NixOS config:

**Save** (walks `/proc` for kitty windows): [niri-session-save.sh](https://github.com/LarsArtmann/SystemNix/blob/master/scripts/niri-session-save.sh)
**Restore** (re-spawns kitty with recovered command + CWD): [niri-session-restore.sh](https://github.com/LarsArtmann/SystemNix/blob/master/scripts/niri-session-restore.sh)

Key excerpt from the save script (kitty PID → child command resolution):
```bash
child_cmd=""
child_cwd=""
current=$pid
for _ in $(seq 1 20); do
  [ -d "/proc/$current" ] || break
  children=$(pgrep -P "$current" 2>/dev/null || true)
  if [ -z "$children" ]; then
    # Fallback: check tpgid for foreground process group
    tpgid_field=$(cat "/proc/$current/stat" 2>/dev/null | cut -d' ' -f8)
    # ... resolve foreground process via tpgid
    break
  fi
  current=$(echo "$children" | head -1)
  proc_name=$(cat "/proc/$current/comm" 2>/dev/null || echo "")
  if echo "$proc_name" | grep -qxE '(fish|bash|zsh|sh|dash)'; then
    continue  # descend into shell
  fi
  child_cmd=$(cat "/proc/$current/cmdline" 2>/dev/null | tr '\0' ' ')
  child_cwd=$(readlink "/proc/$current/cwd" 2>/dev/null")
  break
done
```

Key excerpt from restore:
```bash
if [ -n "$child_cmd" ]; then
  cwd_arg=()
  [ -n "$child_cwd" ] && [ "$child_cwd" != "$HOME" ] && cwd_arg=(--directory "$child_cwd")
  kitty "${cwd_arg[@]}" -e sh -c "$child_safe; exec fish" &
elif [ -n "$has_e" ]; then
  kitty -e "${e_args[@]}" &
else
  kitty &
fi
```

## Scope

- Linux-only (`/proc` filesystem) — this is fine since niri is Linux/Wayland
- Terminal-specific: kitty, foot, wezterm, ghostty, alacritty, etc. (configurable list?)
- Could be a separate "terminal state" section in `session.json` (same pattern as our `kitty-state.json`)

## Configuration

Could be exposed via TOML config:

```toml
[terminal_state]
# Enable /proc-based terminal state recovery (Linux only)
enabled = true

# Terminal app IDs that support -e flag for command execution
terminal_app_ids = ["kitty", "foot", "org.wezfurlong.wezterm", "com.mitchellh.ghostty"]

# Shell names to skip when walking process tree
shell_names = ["fish", "bash", "zsh", "sh", "dash", "-fish", "-bash", "-zsh"]

# Max depth for process tree walking
max_walk_depth = 20
```

## Questions for maintainer

- Should terminal state be a separate feature flag or always-on for Linux?
- Should the process tree walking be per-terminal-type (kitty vs foot have different internal helpers)?
- Would you prefer the `/proc` reading to be behind a feature gate in Cargo?
