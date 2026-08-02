#!/bin/bash

# MyBookLog Local Coverage Tracking
# Generates comprehensive coverage reports and tracks metrics over time

set -e

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
COVERAGE_DIR="$REPO_ROOT/coverage"
REPORTS_DIR="$COVERAGE_DIR/reports"
METRICS_DIR="$COVERAGE_DIR/metrics"
HTML_DIR="$COVERAGE_DIR/html"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Create necessary directories
mkdir -p "$REPORTS_DIR" "$METRICS_DIR" "$HTML_DIR"

# Function: Print colored output
log_info() {
  echo -e "${GREEN}✓${NC} $1"
}

log_warn() {
  echo -e "${YELLOW}⚠${NC} $1"
}

log_error() {
  echo -e "${RED}✗${NC} $1"
}

# Function: Generate coverage report
generate_coverage() {
  echo "Running tests with coverage..."
  cd "$REPO_ROOT"

  flutter test --coverage --coverage-path=coverage/lcov.info || {
    log_error "Tests failed"
    exit 1
  }

  log_info "Coverage data generated"
}

# Function: Parse and extract coverage percentage
extract_coverage_percentage() {
  if [ -f "$COVERAGE_DIR/lcov.info" ]; then
    lcov --list "$COVERAGE_DIR/lcov.info" | grep "^TOTAL" | awk '{print $2}' | sed 's/%$//'
  else
    echo "0"
  fi
}

# Function: Generate HTML report
generate_html_report() {
  echo "Generating HTML coverage report..."

  if [ -f "$COVERAGE_DIR/lcov.info" ]; then
    genhtml "$COVERAGE_DIR/lcov.info" \
      -o "$HTML_DIR" \
      --prefix "$REPO_ROOT" \
      --precision 2 \
      --config-file "$COVERAGE_DIR/.lcovrc" \
      > /dev/null 2>&1

    log_info "HTML report generated: $HTML_DIR/index.html"
  else
    log_error "Coverage file not found"
    return 1
  fi
}

# Function: Display terminal coverage summary
display_coverage_summary() {
  echo ""
  echo "════════════════════════════════════════════════════════"
  echo "Coverage Summary"
  echo "════════════════════════════════════════════════════════"

  if [ -f "$COVERAGE_DIR/lcov.info" ]; then
    lcov --list "$COVERAGE_DIR/lcov.info" | head -30
  else
    log_error "Coverage file not found"
    return 1
  fi
}

# Function: Track coverage metrics over time
track_coverage_metrics() {
  local timestamp=$(date +%Y-%m-%d\ %H:%M:%S)
  local coverage=$(extract_coverage_percentage)
  local metrics_file="$METRICS_DIR/$(date +%Y-%m-%d).csv"

  # Initialize CSV if it doesn't exist
  if [ ! -f "$metrics_file" ]; then
    echo "timestamp,coverage_percent" > "$metrics_file"
  fi

  # Append current metrics
  echo "$timestamp,$coverage" >> "$metrics_file"

  log_info "Coverage tracked: $coverage% at $timestamp"
  echo "$coverage"
}

# Function: Display coverage trend
show_coverage_trend() {
  local today=$(date +%Y-%m-%d)
  local metrics_file="$METRICS_DIR/$today.csv"

  if [ -f "$metrics_file" ]; then
    echo ""
    echo "Coverage Trend — Today ($today)"
    echo "────────────────────────────────"
    tail -5 "$metrics_file" | awk -F',' 'NR>1 {printf "  %s: %s%%\n", $1, $2}'
  fi
}

# Function: Compare with baseline
compare_with_baseline() {
  local baseline_file="$METRICS_DIR/.baseline"
  local current=$(extract_coverage_percentage)

  if [ -f "$baseline_file" ]; then
    local baseline=$(cat "$baseline_file")
    local diff=$(echo "$current - $baseline" | bc)

    echo ""
    echo "Coverage Comparison"
    echo "────────────────────────────────"
    echo "  Baseline:  ${baseline}%"
    echo "  Current:   ${current}%"

    if (( $(echo "$diff > 0" | bc -l) )); then
      log_info "Improvement: +${diff}%"
    elif (( $(echo "$diff < 0" | bc -l) )); then
      log_warn "Regression: ${diff}%"
    else
      echo "  Status: Unchanged"
    fi
  else
    echo ""
    echo "No baseline found. Set baseline with: coverage.sh set-baseline"
  fi
}

# Function: Set coverage baseline
set_baseline() {
  local coverage=$(extract_coverage_percentage)
  local baseline_file="$METRICS_DIR/.baseline"

  echo "$coverage" > "$baseline_file"
  log_info "Baseline set to $coverage%"
}

# Function: Show help
show_help() {
  cat << EOF
MyBookLog Coverage Tracking

Usage: coverage.sh [COMMAND]

Commands:
  generate      Generate coverage report and display summary (default)
  html          Generate HTML coverage report
  summary       Display terminal coverage summary
  trend         Show coverage trend for today
  compare       Compare with baseline
  baseline      Set current coverage as baseline
  watch         Watch coverage and re-run tests on changes
  help          Show this help message

Examples:
  ./scripts/coverage.sh                    # Generate and display summary
  ./scripts/coverage.sh html               # Generate HTML report
  ./scripts/coverage.sh trend              # Show today's trend
  ./scripts/coverage.sh compare            # Compare with baseline
  ./scripts/coverage.sh baseline           # Set baseline

Output:
  Terminal: Direct output to console
  HTML:     coverage/html/index.html
  CSV:      coverage/metrics/YYYY-MM-DD.csv
  Info:     coverage/reports/

EOF
}

# Main command processing
main() {
  local command="${1:-generate}"

  case "$command" in
    generate)
      generate_coverage
      display_coverage_summary
      track_coverage_metrics > /dev/null
      show_coverage_trend
      compare_with_baseline
      ;;
    html)
      generate_coverage
      generate_html_report
      ;;
    summary)
      display_coverage_summary
      ;;
    trend)
      show_coverage_trend
      ;;
    compare)
      compare_with_baseline
      ;;
    baseline)
      generate_coverage
      set_baseline
      ;;
    watch)
      echo "Watching for changes..."
      while true; do
        inotifywait -r -e modify lib/ test/ --exclude '.dart_tool' > /dev/null 2>&1 && {
          clear
          echo "Changes detected. Regenerating coverage..."
          generate_coverage
          display_coverage_summary
          show_coverage_trend
        }
      done
      ;;
    help|--help|-h)
      show_help
      ;;
    *)
      log_error "Unknown command: $command"
      show_help
      exit 1
      ;;
  esac
}

# Run main function
main "$@"
