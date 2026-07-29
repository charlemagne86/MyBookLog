#!/bin/bash

# Check that code coverage meets minimum threshold
# Usage: check_coverage.sh <THRESHOLD_PERCENT>

set -e

THRESHOLD=${1:-80}
LCOV_FILE="coverage/lcov.info"

if [ ! -f "$LCOV_FILE" ]; then
  echo "❌ Coverage file not found: $LCOV_FILE"
  exit 1
fi

# Extract coverage percentage from lcov file
# Format: TOTAL    COVERAGE%
COVERAGE=$(lcov --list "$LCOV_FILE" | grep "^TOTAL" | awk '{print $2}' | sed 's/%$//')

if [ -z "$COVERAGE" ]; then
  echo "❌ Could not parse coverage from lcov report"
  exit 1
fi

# Compare coverage to threshold
if (( $(echo "$COVERAGE < $THRESHOLD" | bc -l) )); then
  echo "❌ Coverage ${COVERAGE}% is below minimum threshold ${THRESHOLD}%"
  echo ""
  echo "Coverage Details:"
  lcov --list "$LCOV_FILE"
  exit 1
else
  echo "✅ Coverage ${COVERAGE}% meets minimum threshold ${THRESHOLD}%"
  echo ""
  echo "Coverage Details:"
  lcov --list "$LCOV_FILE" | head -20
  exit 0
fi
