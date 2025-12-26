# Home Manager Verification Template

**Deployment Date:** [FILL IN DATE]
**Deployer:** [FILL IN NAME]
**Configuration:** Home Manager for Darwin (macOS)

---

## Deployment Summary

### Deployment Command
```bash
# Command used
sudo darwin-rebuild switch --flake .
```

### Deployment Output
[PASTE DEPLOYMENT OUTPUT HERE]

### New Generation
- **Generation Number:** [FILL IN]
- **Store Path:** [FILL IN /nix/store/...]
- **Activation Time:** [FILL IN TIME]

---

## Verification Results

### 1. Build Verification
- [ ] Deployment completed without errors
- [ ] New generation activated successfully
- [ ] No assertion failures
- [ ] No warnings during activation

### 2. Starship Prompt Verification

#### Visual Check
- [ ] Starship prompt appears in terminal
- [ ] Git branch indicator shows (if in git repo)
- [ ] Current directory displays correctly
- [ ] Character symbol at end of prompt (usually ➜)

#### Version Check
```bash
# Output: [PASTE OUTPUT]
starship --version
```
- [ ] Version >= 1.0.0

#### Config Check
```bash
# Output: [PASTE OUTPUT OR "N/A" if empty]
cat ~/.config/starship.toml
```
- [ ] Config file exists
- [ ] Settings from `platforms/common/programs/starship.nix` applied

#### Performance
- [ ] Prompt loads instantly (< 1 second)
- [ ] No lag when changing directories
- [ ] No flickering or visual glitches

### 3. Fish Shell Verification

#### Shell Check
```bash
# Output: [PASTE OUTPUT]
echo $SHELL
```
- [ ] Fish shell is active
- [ ] Shell path points to Nix store

#### Version Check
```bash
# Output: [PASTE OUTPUT]
fish --version
```
- [ ] Version >= 3.0.0

#### Config Check
```bash
# Output: [PASTE KEY SETTINGS OR "N/A"]
cat ~/.config/fish/config.fish | grep -E "(shellAliases|shellInit|interactiveShellInit)"
```
- [ ] Config file exists
- [ ] Common aliases loaded (l, t)
- [ ] Darwin-specific aliases loaded (nixup, nixbuild, nixcheck)
- [ ] Carapace completions enabled

#### Alias Tests
```bash
# Output: [PASTE OUTPUT OR "Command not found" if fails]
type nixup
```
- [ ] `nixup` alias works (should show: `darwin-rebuild switch --flake .`)

```bash
# Output: [PASTE OUTPUT OR "Command not found" if fails]
type nixbuild
```
- [ ] `nixbuild` alias works (should show: `darwin-rebuild build --flake .`)

```bash
# Output: [PASTE OUTPUT OR "Command not found" if fails]
type nixcheck
```
- [ ] `nixcheck` alias works (should show: `darwin-rebuild check --flake .`)

```bash
# Output: [PASTE OUTPUT OR "Command not found" if fails]
type l
```
- [ ] `l` alias works (should show: `ls -laSh`)

```bash
# Output: [PASTE OUTPUT OR "Command not found" if fails]
type t
```
- [ ] `t` alias works (should show: `tree -h -L 2 -C --dirsfirst`)

#### Completions Check
```bash
# Output: [PASTE OUTPUT OR "No completions" if fails]
git <TAB>
```
- [ ] Tab completion works for `git`
- [ ] No errors when pressing TAB

```bash
# Output: [PASTE PATH]
which carapace
```
- [ ] Carapace is installed
- [ ] Carapace path points to Nix store

#### Integration Checks
- [ ] Homebrew integration works (if using Homebrew)
- [ ] Fish greeting disabled (for faster startup)
- [ ] Fish history settings configured
- [ ] No errors on shell startup

### 4. Tmux Verification

#### Launch Test
```bash
# Output: [PASTE OUTPUT OR "Error" if fails]
tmux new-session
```
- [ ] Tmux launches without errors
- [ ] New terminal session opens in Tmux

#### Version Check
```bash
# Output: [PASTE OUTPUT]
tmux -V
```
- [ ] Version >= 3.0

#### Config Check
```bash
# Output: [PASTE OUTPUT OR "File not found" if missing]
cat ~/.config/tmux/tmux.conf
```
- [ ] Config file exists
- [ ] Settings from `platforms/common/programs/tmux.nix` applied

#### Keybinding Tests
```bash
# Press Ctrl+B then D to exit
```
- [ ] Exit keybinding works (Ctrl+B then D)

```bash
# Test copy mode (if configured)
# Press Ctrl+B then [
```
- [ ] Copy mode keybinding works (if configured)

```bash
# Test split pane (if configured)
# Press Ctrl+B then %
```
- [ ] Split pane keybinding works (if configured)

#### Functionality Tests
- [ ] Can create new session
- [ ] Can kill session
- [ ] Can detach from session
- [ ] Can reattach to session
- [ ] Mouse support works (if enabled)

### 5. Environment Variables Verification

#### EDITOR Check
```bash
# Output: [PASTE OUTPUT]
echo $EDITOR
```
- [ ] `EDITOR` is set to `micro`
- [ ] No errors when accessing

#### LANG Check
```bash
# Output: [PASTE OUTPUT]
echo $LANG
```
- [ ] `LANG` is set to `en_GB.UTF-8`

#### LC_ALL Check
```bash
# Output: [PASTE OUTPUT]
echo $LC_ALL
```
- [ ] `LC_ALL` is set to `en_GB.UTF-8`

#### PATH Check
```bash
# Output: [PASTE PATH - check for these directories]
echo $PATH | tr ':' '\n' | grep -E "(local/bin|go/bin|bun/bin)"
```
- [ ] `~/.local/bin` is in PATH
- [ ] `~/go/bin` is in PATH
- [ ] `~/.bun/bin` is in PATH

#### Additional Variables
```bash
# Output: [PASTE ADDITIONAL VARIABLES OR "None"]
env | sort | grep -E "(GOPRIVATE|GH_PAGER)"
```
- [ ] `GOPRIVATE` is set to `github.com/LarsArtmann/*` (from bash)
- [ ] `GH_PAGER` is set to `` (from bash)
- [ ] No conflicting environment variables

### 6. Home Manager System Verification

#### HM Version Check
```bash
# Output: [PASTE OUTPUT OR CHECK NIX STORE PATH]
ls ~/.local/state/home-manager | head -5
```
- [ ] Home Manager state directory exists
- [ ] Home Manager is managing configuration

#### Activation Check
```bash
# Output: [CHECK FOR ACTIVATION ERRORS IN DEPLOYMENT OUTPUT]
```
- [ ] No activation errors
- [ ] All activations completed successfully

#### Backup Check
- [ ] Old configuration backed up (backup extension)
- [ ] No conflicts during activation

#### Generation Check
```bash
# Output: [PASTE OUTPUT]
darwin-rebuild --list-generations | head -5
```
- [ ] New generation appears in list
- [ ] Generation path is correct

---

## Overall Status

### Passed Tests
- [ ] Build verification
- [ ] Starship prompt
- [ ] Fish shell
- [ ] Tmux
- [ ] Environment variables
- [ ] Home Manager system

### Failed Tests
- [ ] List any failed tests below:
  - [ ] Test name: [DESCRIBE ISSUE]
  - [ ] Test name: [DESCRIBE ISSUE]
  - [ ] Test name: [DESCRIBE ISSUE]

### Issues Encountered
[DESCRIBE ANY ISSUES BELOW]

---

## Notes

[ADDITIONAL NOTES OR OBSERVATIONS]

---

## Next Steps

### If All Tests Pass
1. ✅ Mark Phase 2 as complete
2. ✅ Proceed to Phase 3: NixOS verification
3. ✅ Create final verification report
4. ✅ Update documentation files

### If Tests Fail
1. ❌ Document specific failure
2. ❌ Troubleshoot using deployment guide
3. ❌ Fix issues
4. ❌ Redeploy and re-verify

---

**Template Version:** 1.0
**Created:** 2025-12-26 23:50 UTC
**For Use:** After manual `darwin-rebuild switch` deployment
