#!/usr/bin/env bash
# Shell Startup Performance Benchmark Script
# Measures Fish, Zsh, and Bash shell startup times
# Usage: ./scripts/benchmark-shell-startup.sh

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
RUNS=5  # Number of benchmark runs per shell
WARMUP_RUNS=2  # Number of warmup runs before benchmarking

# Benchmark results storage
FISH_TIMES=()
ZSH_TIMES=()
BASH_TIMES=()

# Function to get current time in milliseconds (using Python)
get_time_ms() {
  python3 -c "import time; print(int(time.time() * 1000))"
}

# Function to print header
print_header() {
  echo ""
  echo -e "${BLUE}═════════════════════════════════════════════════════${NC}"
  echo -e "${BLUE} Shell Startup Performance Benchmark${NC}"
  echo -e "${BLUE}═════════════════════════════════════════════════════${NC}"
  echo ""
  echo "Configuration: $RUNS benchmark runs per shell, $WARMUP_RUNS warmup runs"
  echo "Date: $(date '+%Y-%m-%d %H:%M:%S')"
  echo ""
}

# Function to benchmark shell startup
benchmark_shell() {
  local shell="$1"
  local shell_cmd="$2"
  local test_cmd="$3"
  local times=()

  echo -e "${CYAN}Benchmarking $shell...${NC}"

  # Warmup runs (not measured)
  for i in $(seq 1 $WARMUP_RUNS); do
    /usr/bin/env -i $shell_cmd -c "$test_cmd" >/dev/null 2>&1 || true
  done

  # Benchmark runs
  for i in $(seq 1 $RUNS); do
    local start end elapsed

    # Measure startup time using Python for millisecond precision
    start=$(get_time_ms)
    /usr/bin/env -i $shell_cmd -c "$test_cmd" >/dev/null 2>&1 || true
    end=$(get_time_ms)
    elapsed=$((end - start))

    times+=($elapsed)
    echo -e "  Run $i/$RUNS: ${elapsed}ms"
  done

  # Calculate statistics
  local sum=0
  local min=${times[0]}
  local max=${times[0]}

  for time in "${times[@]}"; do
    sum=$((sum + time))
    if [[ $time -lt $min ]]; then
      min=$time
    fi
    if [[ $time -gt $max ]]; then
      max=$time
    fi
  done

  local avg=$((sum / ${#times[@]}))

  # Store results
  if [[ "$shell" == "Fish" ]]; then
    FISH_TIMES=("${times[@]}")
  elif [[ "$shell" == "Zsh" ]]; then
    ZSH_TIMES=("${times[@]}")
  elif [[ "$shell" == "Bash" ]]; then
    BASH_TIMES=("${times[@]}")
  fi

  # Print statistics
  echo -e "  ${GREEN}✓${NC} Min: ${min}ms | Max: ${max}ms | Avg: ${avg}ms"
  echo ""
}

# Function to print benchmark results summary
print_summary() {
  echo ""
  echo -e "${BLUE}═════════════════════════════════════════════════════${NC}"
  echo -e "${BLUE} Benchmark Results Summary${NC}"
  echo -e "${BLUE}═════════════════════════════════════════════════════${NC}"
  echo ""

  # Calculate average for each shell
  local fish_avg=0 zsh_avg=0 bash_avg=0

  if [[ ${#FISH_TIMES[@]} -gt 0 ]]; then
    local fish_sum=0
    for time in "${FISH_TIMES[@]}"; do
      fish_sum=$((fish_sum + time))
    done
    fish_avg=$((fish_sum / ${#FISH_TIMES[@]}))
  fi

  if [[ ${#ZSH_TIMES[@]} -gt 0 ]]; then
    local zsh_sum=0
    for time in "${ZSH_TIMES[@]}"; do
      zsh_sum=$((zsh_sum + time))
    done
    zsh_avg=$((zsh_sum / ${#ZSH_TIMES[@]}))
  fi

  if [[ ${#BASH_TIMES[@]} -gt 0 ]]; then
    local bash_sum=0
    for time in "${BASH_TIMES[@]}"; do
      bash_sum=$((bash_sum + time))
    done
    bash_avg=$((bash_sum / ${#BASH_TIMES[@]}))
  fi

  # Find fastest and slowest
  local fastest_shell=""
  local fastest_time=999999
  local slowest_shell=""
  local slowest_time=0

  if [[ $fish_avg -gt 0 ]]; then
    if [[ $fish_avg -lt $fastest_time ]]; then
      fastest_time=$fish_avg
      fastest_shell="Fish"
    fi
    if [[ $fish_avg -gt $slowest_time ]]; then
      slowest_time=$fish_avg
      slowest_shell="Fish"
    fi
  fi

  if [[ $zsh_avg -gt 0 ]]; then
    if [[ $zsh_avg -lt $fastest_time ]]; then
      fastest_time=$zsh_avg
      fastest_shell="Zsh"
    fi
    if [[ $zsh_avg -gt $slowest_time ]]; then
      slowest_time=$zsh_avg
      slowest_shell="Zsh"
    fi
  fi

  if [[ $bash_avg -gt 0 ]]; then
    if [[ $bash_avg -lt $fastest_time ]]; then
      fastest_time=$bash_avg
      fastest_shell="Bash"
    fi
    if [[ $bash_avg -gt $slowest_time ]]; then
      slowest_time=$bash_avg
      slowest_shell="Bash"
    fi
  fi

  # Print results
  echo -e "${BLUE}🐟 Fish Shell${NC}"
  echo "  Average Startup Time: ${fish_avg}ms"
  echo ""

  echo -e "${BLUE}🅼️  Zsh Shell${NC}"
  echo "  Average Startup Time: ${zsh_avg}ms"
  echo ""

  echo -e "${BLUE}🅱️  Bash Shell${NC}"
  echo "  Average Startup Time: ${bash_avg}ms"
  echo ""

  # Performance evaluation
  echo -e "${BLUE}Performance Evaluation${NC}"
  echo -e "  Fastest: ${GREEN}${fastest_shell}${NC} (${fastest_time}ms)"
  echo -e "  Slowest: ${RED}${slowest_shell}${NC} (${slowest_time}ms)"

  # Compare against ADR-002 targets
  # Define reasonable targets: < 100ms = Excellent, < 200ms = Good, < 500ms = Acceptable
  echo ""
  echo -e "${BLUE}Performance Targets (ADR-002)${NC}"

  local fish_status="" zsh_status="" bash_status=""
  if [[ $fish_avg -lt 100 ]]; then
    fish_status="${GREEN}✓ EXCELLENT${NC}"
  elif [[ $fish_avg -lt 200 ]]; then
    fish_status="${YELLOW}⊘ GOOD${NC}"
  elif [[ $fish_avg -lt 500 ]]; then
    fish_status="${RED}✖ ACCEPTABLE${NC}"
  else
    fish_status="${RED}✖ SLOW${NC}"
  fi

  if [[ $zsh_avg -lt 100 ]]; then
    zsh_status="${GREEN}✓ EXCELLENT${NC}"
  elif [[ $zsh_avg -lt 200 ]]; then
    zsh_status="${YELLOW}⊘ GOOD${NC}"
  elif [[ $zsh_avg -lt 500 ]]; then
    zsh_status="${RED}✖ ACCEPTABLE${NC}"
  else
    zsh_status="${RED}✖ SLOW${NC}"
  fi

  if [[ $bash_avg -lt 100 ]]; then
    bash_status="${GREEN}✓ EXCELLENT${NC}"
  elif [[ $bash_avg -lt 200 ]]; then
    bash_status="${YELLOW}⊘ GOOD${NC}"
  elif [[ $bash_avg -lt 500 ]]; then
    bash_status="${RED}✖ ACCEPTABLE${NC}"
  else
    bash_status="${RED}✖ SLOW${NC}"
  fi

  echo -e "  Fish: $fish_status"
  echo -e "  Zsh: $zsh_status"
  echo -e "  Bash: $bash_status"
  echo ""
}

# Main execution
main() {
  print_header

  # Check if Python 3 is available
  if ! python3 --version &>/dev/null; then
    echo -e "${RED}Error: Python 3 not found${NC}"
    echo "Please install Python 3 for millisecond precision timing"
    exit 1
  fi

  # Benchmark Fish
  if command -v fish &>/dev/null; then
    benchmark_shell "Fish" "fish" "type l"
  else
    echo -e "${YELLOW}⊘${NC} Fish: Shell not installed"
    echo ""
  fi

  # Benchmark Zsh
  if command -v zsh &>/dev/null; then
    benchmark_shell "Zsh" "zsh" "type l"
  else
    echo -e "${YELLOW}⊘${NC} Zsh: Shell not installed"
    echo ""
  fi

  # Benchmark Bash
  if command -v bash &>/dev/null; then
    benchmark_shell "Bash" "bash" "type l"
  else
    echo -e "${YELLOW}⊘${NC} Bash: Shell not installed"
    echo ""
  fi

  # Print summary
  print_summary
}

# Run main function
main
