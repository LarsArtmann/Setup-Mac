#!/bin/bash

# Comprehensive Maintenance Script for Setup-Mac Project
# =====================================================
# Automated maintenance tasks for optimal system performance
# Includes scheduling, reporting, and safety checks

set -euo pipefail

# Configuration
DRY_RUN=false
VERBOSE=false
SCHEDULE_MODE=false
FORCE_MODE=false
MAINTENANCE_LEVEL="normal"  # minimal, normal, full

# Default maintenance intervals (in days)
CLEANUP_INTERVAL=7
OPTIMIZATION_INTERVAL=30
HEALTH_CHECK_INTERVAL=1
BACKUP_INTERVAL=7

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_verbose() {
    if [[ "$VERBOSE" == "true" ]]; then
        echo -e "${BLUE}[VERBOSE]${NC} $1"
    fi
}

# Help function
show_help() {
    cat << EOF
Comprehensive Maintenance Script

USAGE:
    $0 [OPTIONS] [TASKS...]

OPTIONS:
    --dry-run                     Preview maintenance tasks without executing
    --verbose                     Show detailed information about operations
    --schedule                    Set up automated maintenance schedule
    --force                       Force maintenance even if not due
    --level LEVEL                 Maintenance level: minimal, normal, full (default: normal)
    --cleanup-interval DAYS       Days between cleanup runs (default: 7)
    --optimization-interval DAYS  Days between optimization runs (default: 30)
    --health-interval DAYS        Days between health checks (default: 1)
    --backup-interval DAYS        Days between backups (default: 7)
    --help                        Show this help message

MAINTENANCE LEVELS:
    minimal                       Basic cleanup and health checks only
    normal                        Standard maintenance with optimization review
    full                          Comprehensive maintenance with all optimizations

AVAILABLE TASKS:
    cleanup                       Run system cleanup
    optimize                      Run performance optimizations
    health-check                  Run system health check
    backup                        Create system backup
    update                        Update packages and dependencies
    security-check                Run security verification
    performance-test              Run performance benchmarks
    all                           Run all maintenance tasks

EXAMPLES:
    $0                           Run normal maintenance
    $0 --level full              Run full maintenance
    $0 cleanup health-check      Run specific tasks only
    $0 --schedule               Set up automated maintenance
    $0 --dry-run --verbose      Preview maintenance with details

SCHEDULING:
    When using --schedule, the script will set up cron jobs for:
    - Daily health checks
    - Weekly cleanup
    - Monthly optimizations
    - Weekly backups
EOF
}

# Parse command line arguments
TASKS=()
while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        --schedule)
            SCHEDULE_MODE=true
            shift
            ;;
        --force)
            FORCE_MODE=true
            shift
            ;;
        --level)
            MAINTENANCE_LEVEL="$2"
            shift 2
            ;;
        --cleanup-interval)
            CLEANUP_INTERVAL="$2"
            shift 2
            ;;
        --optimization-interval)
            OPTIMIZATION_INTERVAL="$2"
            shift 2
            ;;
        --health-interval)
            HEALTH_CHECK_INTERVAL="$2"
            shift 2
            ;;
        --backup-interval)
            BACKUP_INTERVAL="$2"
            shift 2
            ;;
        --help)
            show_help
            exit 0
            ;;
        cleanup|optimize|health-check|backup|update|security-check|performance-test|all)
            TASKS+=("$1")
            shift
            ;;
        *)
            log_error "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Validate maintenance level
case "$MAINTENANCE_LEVEL" in
    minimal|normal|full)
        log_verbose "Using maintenance level: $MAINTENANCE_LEVEL"
        ;;
    *)
        log_error "Invalid maintenance level: $MAINTENANCE_LEVEL"
        echo "Valid levels: minimal, normal, full"
        exit 1
        ;;
esac

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Maintenance tracking
MAINTENANCE_LOG="$PROJECT_DIR/.maintenance.log"
LAST_RUN_FILE="$PROJECT_DIR/.last_maintenance"

# Function to execute command with dry-run support
execute_command() {
    local cmd="$1"
    local description="$2"

    if [[ "$DRY_RUN" == "true" ]]; then
        log_warning "[DRY-RUN] Would execute: $cmd"
        log_warning "[DRY-RUN] Description: $description"
        return 0
    else
        log_verbose "Executing: $cmd"
        log_info "$description"
        if eval "$cmd"; then
            log_success "✓ $description completed"
            return 0
        else
            log_error "✗ $description failed"
            return 1
        fi
    fi
}

# Function to log maintenance activity
log_maintenance() {
    local task="$1"
    local status="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    if [[ "$DRY_RUN" != "true" ]]; then
        echo "$timestamp [$status] $task" >> "$MAINTENANCE_LOG"
    fi
}

# Function to check if task is due
is_task_due() {
    local task="$1"
    local interval_days="$2"

    if [[ "$FORCE_MODE" == "true" ]]; then
        return 0
    fi

    local last_run_file="$PROJECT_DIR/.last_${task//-/_}"

    if [[ ! -f "$last_run_file" ]]; then
        log_verbose "Task $task has never been run"
        return 0
    fi

    local last_run=$(cat "$last_run_file" 2>/dev/null || echo "0")
    local current_time=$(date +%s)
    local interval_seconds=$((interval_days * 86400))

    if [[ $((current_time - last_run)) -gt $interval_seconds ]]; then
        log_verbose "Task $task is due (last run: $(date -r $last_run 2>/dev/null || echo 'unknown'))"
        return 0
    else
        log_verbose "Task $task not due yet"
        return 1
    fi
}

# Function to mark task as completed
mark_task_completed() {
    local task="$1"
    local timestamp=$(date +%s)

    if [[ "$DRY_RUN" != "true" ]]; then
        echo "$timestamp" > "$PROJECT_DIR/.last_${task//-/_}"
    fi
}

# Cleanup task
run_cleanup() {
    if ! is_task_due "cleanup" "$CLEANUP_INTERVAL"; then
        log_info "Cleanup not due yet (use --force to override)"
        return 0
    fi

    log_info "Running system cleanup..."

    local cleanup_cmd="$SCRIPT_DIR/cleanup.sh"
    local cleanup_args=""

    if [[ "$VERBOSE" == "true" ]]; then
        cleanup_args+=" --verbose"
    fi

    case "$MAINTENANCE_LEVEL" in
        minimal)
            cleanup_args+=" --cache-retention 7 --log-retention 14"
            ;;
        normal)
            cleanup_args+=" --cache-retention 3 --log-retention 7"
            ;;
        full)
            cleanup_args+=" --cache-retention 1 --log-retention 3"
            ;;
    esac

    if execute_command "$cleanup_cmd $cleanup_args" "System cleanup"; then
        mark_task_completed "cleanup"
        log_maintenance "cleanup" "SUCCESS"
    else
        log_maintenance "cleanup" "FAILED"
        return 1
    fi
}

# Optimization task
run_optimize() {
    if ! is_task_due "optimize" "$OPTIMIZATION_INTERVAL"; then
        log_info "Optimization not due yet (use --force to override)"
        return 0
    fi

    log_info "Running performance optimization..."

    local optimize_cmd="$SCRIPT_DIR/optimize.sh"
    local optimize_args=""

    if [[ "$VERBOSE" == "true" ]]; then
        optimize_args+=" --verbose"
    fi

    case "$MAINTENANCE_LEVEL" in
        minimal)
            optimize_args+=" --profile conservative"
            ;;
        normal)
            optimize_args+=" --profile balanced"
            ;;
        full)
            optimize_args+=" --profile aggressive"
            ;;
    esac

    # Always run optimization in dry-run first for safety
    if [[ "$DRY_RUN" != "true" && "$MAINTENANCE_LEVEL" == "full" ]]; then
        log_info "Running optimization preview first..."
        $optimize_cmd --dry-run $optimize_args >/dev/null 2>&1 || {
            log_warning "Optimization preview failed, skipping optimization"
            return 1
        }
    fi

    if execute_command "$optimize_cmd $optimize_args" "Performance optimization"; then
        mark_task_completed "optimize"
        log_maintenance "optimize" "SUCCESS"
    else
        log_maintenance "optimize" "FAILED"
        return 1
    fi
}

# Health check task
run_health_check() {
    if ! is_task_due "health-check" "$HEALTH_CHECK_INTERVAL"; then
        log_info "Health check not due yet (use --force to override)"
        return 0
    fi

    log_info "Running system health check..."

    local health_cmd="$SCRIPT_DIR/health-check.sh"
    local health_args="--alert"

    if [[ "$VERBOSE" == "true" ]]; then
        health_args+=" --verbose"
    fi

    if [[ "$MAINTENANCE_LEVEL" == "full" ]]; then
        health_args+=" --comprehensive"
    fi

    if execute_command "$health_cmd $health_args" "System health check"; then
        mark_task_completed "health-check"
        log_maintenance "health-check" "SUCCESS"
    else
        log_maintenance "health-check" "WARNING"
        log_warning "Health check detected issues (exit code: $?)"
    fi
}

# Backup task
run_backup() {
    if ! is_task_due "backup" "$BACKUP_INTERVAL"; then
        log_info "Backup not due yet (use --force to override)"
        return 0
    fi

    log_info "Creating system backup..."

    # Create backup directory
    local backup_dir="maintenance-backup-$(date +%Y%m%d_%H%M%S)"

    if [[ "$DRY_RUN" == "true" ]]; then
        log_warning "[DRY-RUN] Would create backup: $backup_dir"
    else
        mkdir -p "$backup_dir"

        # Backup critical files
        [[ -f "$HOME/.zshrc" ]] && cp "$HOME/.zshrc" "$backup_dir/"
        [[ -f "$HOME/.bashrc" ]] && cp "$HOME/.bashrc" "$backup_dir/"
        [[ -f "$HOME/.claude.json" ]] && cp "$HOME/.claude.json" "$backup_dir/"

        # Backup project files
        cp -r "$PROJECT_DIR/dotfiles" "$backup_dir/" 2>/dev/null || true
        cp -r "$PROJECT_DIR/scripts" "$backup_dir/" 2>/dev/null || true

        # Create backup manifest
        cat > "$backup_dir/backup_manifest.txt" << EOF
Backup created: $(date)
Maintenance level: $MAINTENANCE_LEVEL
Project directory: $PROJECT_DIR
Files included:
$(find "$backup_dir" -type f | sort)
EOF

        log_success "✓ Backup created: $backup_dir"
        echo "$backup_dir" > "$PROJECT_DIR/.last_backup_location"
    fi

    mark_task_completed "backup"
    log_maintenance "backup" "SUCCESS"
}

# Update task
run_update() {
    log_info "Running system updates..."

    # Update Nix flake
    if [[ -f "$PROJECT_DIR/flake.nix" ]]; then
        execute_command "cd $PROJECT_DIR && nix flake update" "Updating Nix flake"
    fi

    # Update Homebrew
    if command -v brew >/dev/null 2>&1; then
        execute_command "brew update" "Updating Homebrew"

        if [[ "$MAINTENANCE_LEVEL" == "full" ]]; then
            execute_command "brew upgrade" "Upgrading Homebrew packages"
        fi
    fi

    # Update Go modules (if in Go project)
    if [[ -f "go.mod" ]]; then
        execute_command "go get -u ./..." "Updating Go modules"
    fi

    # Update Claude
    if command -v bun >/dev/null 2>&1; then
        execute_command "bun update -g @anthropic-ai/claude-code" "Updating Claude"
    fi

    log_maintenance "update" "SUCCESS"
}

# Security check task
run_security_check() {
    log_info "Running security verification..."

    # Check system integrity
    if command -v csrutil >/dev/null 2>&1; then
        execute_command "csrutil status" "Checking System Integrity Protection"
    fi

    # Check for security updates
    execute_command "softwareupdate -l" "Checking for security updates"

    # Verify file permissions
    execute_command "ls -la $PROJECT_DIR/scripts/" "Checking script permissions"

    log_maintenance "security-check" "SUCCESS"
}

# Performance test task
run_performance_test() {
    log_info "Running performance benchmarks..."

    local benchmark_file="performance_$(date +%Y%m%d_%H%M%S).txt"

    execute_command "$PROJECT_DIR/shell-performance-benchmark.sh > $benchmark_file" "Running shell performance benchmark"

    if [[ -f "$benchmark_file" && "$DRY_RUN" != "true" ]]; then
        log_success "✓ Performance results saved to: $benchmark_file"
    fi

    log_maintenance "performance-test" "SUCCESS"
}

# Set up automated maintenance schedule
setup_schedule() {
    log_info "Setting up automated maintenance schedule..."

    if [[ "$DRY_RUN" == "true" ]]; then
        log_warning "[DRY-RUN] Would set up the following cron jobs:"
        echo "# Daily health check at 2 AM"
        echo "0 2 * * * cd $PROJECT_DIR && $0 health-check --level $MAINTENANCE_LEVEL"
        echo "# Weekly cleanup on Sunday at 3 AM"
        echo "0 3 * * 0 cd $PROJECT_DIR && $0 cleanup --level $MAINTENANCE_LEVEL"
        echo "# Monthly optimization on 1st at 1 AM"
        echo "0 1 1 * * cd $PROJECT_DIR && $0 optimize --level $MAINTENANCE_LEVEL"
        echo "# Weekly backup on Sunday at 4 AM"
        echo "0 4 * * 0 cd $PROJECT_DIR && $0 backup"
        return 0
    fi

    # Create cron jobs
    local temp_cron=$(mktemp)
    crontab -l 2>/dev/null > "$temp_cron" || true

    # Remove existing maintenance jobs
    grep -v "# Setup-Mac maintenance" "$temp_cron" > "${temp_cron}.new" || true
    mv "${temp_cron}.new" "$temp_cron"

    # Add new maintenance jobs
    cat >> "$temp_cron" << EOF
# Setup-Mac maintenance jobs
0 2 * * * cd $PROJECT_DIR && $0 health-check --level $MAINTENANCE_LEVEL # Setup-Mac maintenance
0 3 * * 0 cd $PROJECT_DIR && $0 cleanup --level $MAINTENANCE_LEVEL # Setup-Mac maintenance
0 1 1 * * cd $PROJECT_DIR && $0 optimize --level $MAINTENANCE_LEVEL # Setup-Mac maintenance
0 4 * * 0 cd $PROJECT_DIR && $0 backup # Setup-Mac maintenance
EOF

    # Install cron jobs
    crontab "$temp_cron"
    rm -f "$temp_cron"

    log_success "✓ Automated maintenance schedule installed"
    log_info "Schedule:"
    log_info "  • Daily health checks at 2:00 AM"
    log_info "  • Weekly cleanup on Sundays at 3:00 AM"
    log_info "  • Monthly optimization on 1st at 1:00 AM"
    log_info "  • Weekly backup on Sundays at 4:00 AM"

    log_info "To view scheduled jobs: crontab -l"
    log_info "To remove scheduled jobs: crontab -e (then delete lines ending with '# Setup-Mac maintenance')"
}

# Get default tasks based on maintenance level
get_default_tasks() {
    case "$MAINTENANCE_LEVEL" in
        minimal)
            echo "health-check cleanup"
            ;;
        normal)
            echo "health-check cleanup optimize"
            ;;
        full)
            echo "health-check cleanup optimize backup update security-check"
            ;;
    esac
}

# Main maintenance function
main_maintenance() {
    log_info "Starting maintenance routine..."
    log_info "Maintenance level: $MAINTENANCE_LEVEL"

    if [[ "$DRY_RUN" == "true" ]]; then
        log_warning "DRY-RUN MODE: No changes will be applied"
    fi

    if [[ "$SCHEDULE_MODE" == "true" ]]; then
        setup_schedule
        return 0
    fi

    # Determine tasks to run
    local tasks_to_run=()
    if [[ ${#TASKS[@]} -eq 0 ]]; then
        # Use default tasks for maintenance level
        read -ra tasks_to_run <<< "$(get_default_tasks)"
    else
        tasks_to_run=("${TASKS[@]}")
    fi

    # Handle 'all' task
    if [[ " ${tasks_to_run[*]} " =~ " all " ]]; then
        tasks_to_run=("health-check" "cleanup" "optimize" "backup" "update" "security-check" "performance-test")
    fi

    log_info "Running tasks: ${tasks_to_run[*]}"
    echo

    # Record maintenance start
    if [[ "$DRY_RUN" != "true" ]]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') [START] Maintenance started (level: $MAINTENANCE_LEVEL)" >> "$MAINTENANCE_LOG"
    fi

    # Run tasks
    local failed_tasks=()
    local completed_tasks=()

    # Initialize arrays properly
    failed_tasks=()
    completed_tasks=()

    for task in "${tasks_to_run[@]}"; do
        case "$task" in
            cleanup)
                if run_cleanup; then
                    completed_tasks+=("$task")
                else
                    failed_tasks+=("$task")
                fi
                ;;
            optimize)
                if run_optimize; then
                    completed_tasks+=("$task")
                else
                    failed_tasks+=("$task")
                fi
                ;;
            health-check)
                if run_health_check; then
                    completed_tasks+=("$task")
                else
                    failed_tasks+=("$task")
                fi
                ;;
            backup)
                if run_backup; then
                    completed_tasks+=("$task")
                else
                    failed_tasks+=("$task")
                fi
                ;;
            update)
                if run_update; then
                    completed_tasks+=("$task")
                else
                    failed_tasks+=("$task")
                fi
                ;;
            security-check)
                if run_security_check; then
                    completed_tasks+=("$task")
                else
                    failed_tasks+=("$task")
                fi
                ;;
            performance-test)
                if run_performance_test; then
                    completed_tasks+=("$task")
                else
                    failed_tasks+=("$task")
                fi
                ;;
            *)
                log_warning "Unknown task: $task"
                failed_tasks+=("$task")
                ;;
        esac
        echo
    done

    # Record maintenance completion
    if [[ "$DRY_RUN" != "true" ]]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') [END] Maintenance completed" >> "$MAINTENANCE_LOG"
        echo "$(date +%s)" > "$LAST_RUN_FILE"
    fi

    # Summary
    log_info "Maintenance summary:"
    log_info "  • Completed tasks: ${#completed_tasks[@]}"
    log_info "  • Failed tasks: ${#failed_tasks[@]}"

    if [[ ${#completed_tasks[@]} -gt 0 ]]; then
        log_success "✓ Completed: ${completed_tasks[*]}"
    fi

    if [[ ${#failed_tasks[@]} -gt 0 ]]; then
        log_error "✗ Failed: ${failed_tasks[*]}"
    fi

    if [[ ${#failed_tasks[@]} -eq 0 ]]; then
        log_success "🎉 All maintenance tasks completed successfully!"
    else
        log_warning "Some maintenance tasks failed. Check logs for details."
    fi

    # Recommendations
    echo
    log_info "Next steps:"
    log_info "  • View maintenance log: cat $MAINTENANCE_LOG"
    log_info "  • Check system health: $SCRIPT_DIR/health-check.sh"

    if [[ ! "$SCHEDULE_MODE" == "true" ]]; then
        log_info "  • Set up automated maintenance: $0 --schedule"
    fi
}

# Run main maintenance
main_maintenance "$@"

# Exit with appropriate code
if [[ ${#failed_tasks[@]} -gt 0 ]]; then
    exit 1
else
    exit 0
fi