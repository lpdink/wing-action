#!/usr/bin/env bash
set -euo pipefail

echo "::group::Setting up wing config"

# Use isolated HOME (set by configure_auth step via GITHUB_ENV)
CONFIG_DIR="${HOME}/.wing/core"
CONFIG_FILE="${CONFIG_DIR}/config.yaml"

mkdir -p "${CONFIG_DIR}"

# Determine model
AGENT_MODEL="${MODEL:-gpt-4o}"

# wing >= 0.4.0 replaced the legacy top-level `openai:` section with a
# `providers:` list (multi-provider support, `protocol: openai` keeps the
# OpenAI-compatible endpoint behavior). The agent's `provider` references
# providers[].name.
cat > "${CONFIG_FILE}" <<EOF
providers:
  - name: default
    protocol: openai
    base_url: ${LLM_BASE_URL}
    api_key: ${LLM_API_KEY}
agents:
  - name: default
    model: ${AGENT_MODEL}
    provider: default
    tools:
      - Bash
      - Read
      - Write
      - Edit
yolo: true
EOF

chmod 600 "${CONFIG_FILE}"
echo "✓ Config written to ${CONFIG_FILE} (permissions: 600)"
echo "::endgroup::"
