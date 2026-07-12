#!/usr/bin/env bash
set -euo pipefail

echo "::group::Preparing wing execution"

# Build wing command
WING_ARGS=(-p "${WING_PROMPT}" --yolo --max-turns "${WING_MAX_TURNS}")

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
wing "${WING_ARGS[@]}" >"${OUTPUT_FILE}" 2>"${ERROR_FILE}"
EXIT_CODE=$?
set -e

echo "::endgroup::"

# Read outputs
RESULT=""
if [[ -s "${OUTPUT_FILE}" ]]; then
  RESULT="$(cat "${OUTPUT_FILE}")"
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
    # Print last 20 lines of stderr for quick diagnosis
    echo "::group::wing stderr (last 20 lines)"
    echo "${ERROR_MSG}" | tail -20
    echo "::endgroup::"
  fi
  exit ${EXIT_CODE}
fi

echo "✓ Wing execution complete"
