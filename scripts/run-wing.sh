#!/usr/bin/env bash
set -euo pipefail

echo "::group::Starting wing gateway"

wing start 2>&1 || true

# Wait for gateway port to become reachable
HOST="127.0.0.1"
PORT="32523"
MAX_WAIT=30
WAITED=0

while ! (echo > /dev/tcp/${HOST}/${PORT}) 2>/dev/null; do
  if [[ ${WAITED} -ge ${MAX_WAIT} ]]; then
    echo "::error::Gateway did not become reachable within ${MAX_WAIT}s"
    # Show gateway log for diagnosis
    GW_LOG="${HOME}/.wing/tui/gateway.log"
    if [[ ! -f "${GW_LOG}" ]]; then
      GW_LOG="${HOME}/.wing/gateway.log"
    fi
    if [[ -f "${GW_LOG}" ]]; then
      echo "::group::Gateway log (last 30 lines)"
      tail -30 "${GW_LOG}"
      echo "::endgroup::"
    fi
    exit 1
  fi
  sleep 1
  WAITED=$((WAITED + 1))
done

echo "✓ Gateway ready (${WAITED}s)"
echo "::endgroup::"

echo "::group::Preparing wing execution"

# Build wing command
WING_ARGS=(-p "${WING_PROMPT}" --yolo --max-turns "${WING_MAX_TURNS}" --output-format stream-json)

# System prompt: --system-prompt replaces, --append-system-prompt appends
if [[ -n "${WING_SYSTEM_PROMPT:-}" ]]; then
  WING_ARGS+=(--system-prompt "${WING_SYSTEM_PROMPT}")
fi

if [[ -n "${WING_APPEND_SYSTEM_PROMPT:-}" ]]; then
  WING_ARGS+=(--append-system-prompt "${WING_APPEND_SYSTEM_PROMPT}")
fi

echo "Prompt length: ${#WING_PROMPT} chars"
[[ -n "${WING_SYSTEM_PROMPT:-}" ]] && echo "System prompt: ${#WING_SYSTEM_PROMPT} chars"
[[ -n "${WING_APPEND_SYSTEM_PROMPT:-}" ]] && echo "Append system prompt: ${#WING_APPEND_SYSTEM_PROMPT} chars"
echo "Max turns: ${WING_MAX_TURNS}"
echo "::endgroup::"

# Output file for debug trace
OUTPUT_FILE="$(mktemp /tmp/wing-output-XXXXXX.log)"
ERROR_FILE="$(mktemp /tmp/wing-error-XXXXXX.log)"

echo "::group::Running wing"

set +e
wing "${WING_ARGS[@]}" 2>"${ERROR_FILE}" | tee "${OUTPUT_FILE}"
EXIT_CODE=${PIPESTATUS[0]}
set -e

echo "::endgroup::"

# Read outputs — extract final result text from the last NDJSON line ({"type":"result",...})
RESULT=""
if [[ -s "${OUTPUT_FILE}" ]]; then
  RESULT="$(tail -1 "${OUTPUT_FILE}" | jq -r '.result // empty' 2>/dev/null || true)"
fi

ERROR_MSG=""
if [[ -s "${ERROR_FILE}" ]]; then
  ERROR_MSG="$(cat "${ERROR_FILE}")"
fi

# Write output_file path for debug trace step
echo "output_file=${OUTPUT_FILE}" >> "${GITHUB_OUTPUT}"

# Write result
if [[ -n "${RESULT}" ]]; then
  {
    echo "result<<WING_OUTPUT_EOF"
    echo "${RESULT}"
    echo "WING_OUTPUT_EOF"
  } >> "${GITHUB_OUTPUT}"
fi

# Write error
if [[ -n "${ERROR_MSG}" ]]; then
  {
    echo "error<<WING_ERROR_EOF"
    echo "${ERROR_MSG}"
    echo "WING_ERROR_EOF"
  } >> "${GITHUB_OUTPUT}"
fi

# Handle failure
if [[ ${EXIT_CODE} -ne 0 ]]; then
  echo "::error::wing execution failed with exit code ${EXIT_CODE}"
  if [[ -n "${ERROR_MSG}" ]]; then
    echo "::group::wing stderr (last 20 lines)"
    echo "${ERROR_MSG}" | tail -20
    echo "::endgroup::"
  fi
  exit ${EXIT_CODE}
fi

echo "✓ Wing execution complete"
