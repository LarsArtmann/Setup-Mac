# Crush-Patched Update

## Update to New Version

1. Edit `pkgs/crush-patched.nix`
2. Update `version` and source `sha256`

```bash
# Get new version's hash
nix-prefetch-url --type sha256 \
  https://github.com/charmbracelet/crush/archive/refs/tags/v0.39.3.tar.gz
```

3. Set `vendorHash = null;` (Nix will compute it)
4. Build and copy the hash from error message:

```bash
nix build .#crush-patched
```

Output shows:
```
got:    sha256-uo9VelhRjtWiaYI88+eTk9PxAUE18Tu2pNq4qQqoTwk=
```

5. Paste the hash into `vendorHash = "sha256-...";`
6. Build again: `nix build .#crush-patched`
7. Install: `just switch`

That's it. No scripts, no automation needed.
