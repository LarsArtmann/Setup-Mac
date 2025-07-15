# Report about missing/under-specified/confusing information

Date: 2025-07-15T12:59:41+02:00

I was asked to perform:
- Debug and optimize terminal shell performance from 13+ seconds to <73.9ms target
- Implement Fish + Carapace + Starship via Nix for ultimate "min-max" performance
- Create comprehensive benchmarks and verify performance improvements
- Follow git workflow with commits after each smallest change
- Manage GitHub issues and create comprehensive documentation

I was given these context information's:
- Performance budget: <500ms 95%tile, <250ms 50%tile (corrected from 1250ms)
- Starship timeout adjustments: 400ms command timeout, 100ms scan timeout
- Nix configuration structure and existing files
- User's preference for Fish + Carapace + Starship combination
- Existing ZSH performance issues with compinit taking 25+ seconds

I was missing these information:
- Clear verification procedures for each deployment step
- Proper rollback strategies before making system changes
- Understanding that timeout during darwin-rebuild doesn't mean failure
- Knowledge that user would need to manually set Fish as default shell
- Integration testing procedures for Fish + Carapace + Starship combination
- Clear git workflow integration with system configuration changes

I was confused by:
- Whether darwin-rebuild timeout indicated success or failure
- How to properly verify Fish shell is set as default after deployment
- When to use nix-darwin programs.* vs manual configuration files
- How to handle system-level changes like /etc/shells modifications
- Which packages might have valgrind dependencies causing build failures
- Whether to commit during or after system deployment phases

What I wish for the future is:
- Explicit success/failure criteria for each deployment step
- Automated verification scripts that check system state post-deployment
- Clear separation between Nix configuration and system activation steps
- Better understanding of macOS shell change procedures requiring user interaction
- Pre-deployment dependency analysis to avoid build failures
- Integration of git workflow with configuration management lifecycle
- Emergency rollback procedures documented before making changes

Best regards,
Claude Code Assistant