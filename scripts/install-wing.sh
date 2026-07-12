#!/usr/bin/env bash
set -euo pipefail

echo "::group::Installing wing-agent"

# Use isolated HOME if set (from runner.temp)
export HOME="${WING_HOME_DIR:-${HOME}}"

if [[ -n "${WING_VERSION:-}" ]]; then
  echo "Installing wing-agent==${WING_VERSION}..."
  pip install "wing-agent==${WING_VERSION}"
else
  echo "Installing wing-agent (latest)..."
  pip install wing-agent
fi

echo "✓ wing-agent installed"
wing --version 2>/dev/null || true
echo "::endgroup::"
