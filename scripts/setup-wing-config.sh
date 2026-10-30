#!/usr/bin/env bash
set -euo pipefail

echo "::group::Setting up wing config"

# Use isolated HOME (set by configure_auth step via GITHUB_ENV)
CONFIG_DIR="${HOME}/.wing/core"
CONFIG_FILE="${CONFIG_DIR}/config.yaml"

: "${LLM_BASE_URL:?LLM_BASE_URL is required}"
: "${LLM_API_KEY:?LLM_API_KEY is required}"

mkdir -p "${CONFIG_DIR}"

# The model catalog lives in configuration only: every provider declares the
# models it serves (`providers[].models`) and `agents[].model` references one of
# those ids. A provider without `models` leaves the gateway in setup mode and
# `wing` refuses to start a session (exit 78), so the model the action was told to
# run on has to be declared on the provider, not only on the agent.
#
# The document is rendered through PyYAML (a wing-agent dependency) rather than a
# heredoc: model names are user input and may carry YAML metacharacters
# (`Qwen/Qwen3.5:32B`, `#`, quotes) that hand-written quoting would mangle.
python3 - "${CONFIG_FILE}" <<'PY'
import os
import sys

import yaml

model = os.environ.get("MODEL") or "gpt-4o"
document = {
    "providers": [
        {
            "name": "default",
            "protocol": "openai",
            "base_url": os.environ["LLM_BASE_URL"],
            "api_key": os.environ["LLM_API_KEY"],
            "models": [{"name": model}],
        }
    ],
    "agents": [
        {
            "name": "default",
            "model": model,
            "tools": ["Bash", "Read", "Write", "Edit"],
        }
    ],
    "yolo": True,
}

with open(sys.argv[1], "w", encoding="utf-8") as handle:
    yaml.safe_dump(document, handle, sort_keys=False, allow_unicode=True)
PY

chmod 600 "${CONFIG_FILE}"
echo "✓ Config written to ${CONFIG_FILE} (permissions: 600)"
echo "::endgroup::"