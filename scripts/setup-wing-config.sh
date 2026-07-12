#!/usr/bin/env bash
set -euo pipefail

echo "::group::Setting up wing config"

# Use isolated HOME (set by configure_auth step via GITHUB_ENV)
CONFIG_DIR="${HOME}/.wing/core"
CONFIG_FILE="${CONFIG_DIR}/config.yaml"

mkdir -p "${CONFIG_DIR}"

# Determine model
AGENT_MODEL="${MODEL:-gpt-4o}"

cat > "${CONFIG_FILE}" <<EOF
openai:
  base_url: ${LLM_BASE_URL}
  api_key: ${LLM_API_KEY}
agents:
  - name: default
    model: ${AGENT_MODEL}
    tools:
      - Bash
      - Read
      - Write
      - Edit
    yolo: true
yolo: true
EOF

chmod 600 "${CONFIG_FILE}"
echo "✓ Config written to ${CONFIG_FILE} (permissions: 600)"
echo "::endgroup::"
