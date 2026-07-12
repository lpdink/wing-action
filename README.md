# Wing Action

Run [wing-agent](https://github.com/lpdink/wing-action) in GitHub Actions — an AI-powered autonomous agent for code review, refactoring, debugging, and more.

## Features

- **🤖 Generic Agent Executor**: Not limited to code review — pass any prompt and system instructions
- **🎨 Custom Bot Identity**: Actions appear under your own GitHub App with custom name and avatar
- **🔒 Secure by Default**: Isolated `runner.temp` HOME, token masking, thorough cleanup, prompt injection defenses
- **⚙️ Full Control**: Configure system prompt, model, tools, and max turns in your workflow

## Quick Start

### 1. Create a GitHub App

Follow the [setup guide](./docs/setup-github-app.md) to create a GitHub App. You'll need:

- **App ID** → stored as repository variable `WING_APP_ID`
- **App Private Key** → stored as repository secret `WING_APP_PRIVATE_KEY`
- **LLM API Key** → stored as repository secret `LLM_API_KEY`

### 2. Add a Workflow

Create `.github/workflows/wing-review.yml`:

```yaml
name: Wing Code Review

permissions: {}

on:
  pull_request_target:
    types: [opened, reopened]
    branches: [main]

jobs:
  review:
    runs-on: ubuntu-latest
    if: contains(fromJSON('["OWNER", "COLLABORATOR"]'), github.event.pull_request.author_association)
    permissions:
      contents: read
      pull-requests: write
    steps:
      - uses: actions/checkout@v4
        with:
          ref: ${{ github.event.repository.default_branch }}
          fetch-depth: 0

      - uses: lpdink/wing-action@v1
        timeout-minutes: 30
        with:
          app_id: ${{ vars.WING_APP_ID }}
          app_private_key: ${{ secrets.WING_APP_PRIVATE_KEY }}
          llm_api_key: ${{ secrets.LLM_API_KEY }}
          prompt: |
            Review PR #${{ github.event.pull_request.number }} in ${{ github.repository }}.
            GITHUB_REPOSITORY: ${{ github.repository }}
            PR_NUMBER: ${{ github.event.pull_request.number }}
          append_system_prompt: |
            You are a code reviewer. Focus on logic bugs, security, and performance. Be constructive.
```

### 3. Try It Out

Open a Pull Request and watch your bot in action! 🎉

## Configuration Reference

### Inputs

| Name | Description | Required | Default |
|------|-------------|----------|---------|
| `app_id` | GitHub App ID. | **Yes** | — |
| `app_private_key` | GitHub App private key (PEM). | **Yes** | — |
| `llm_api_key` | LLM API key. | **Yes** | — |
| `prompt` | Instructions for wing (passed to `-p`). Dynamic user message. | **Yes** | — |
| `system_prompt` | Replace the system prompt entirely. | No | — |
| `append_system_prompt` | Append instructions to the system prompt. | No | — |
| `llm_base_url` | OpenAI-compatible API base URL. | No | `https://api.openai.com/v1` |
| `model` | Model name override. | No | *(wing config default)* |
| `wing_version` | wing-agent pip version. Empty = latest. | No | *(latest)* |
| `max_turns` | Maximum agent loop turns. | No | `500` |
| `timeout_minutes` | Maximum execution time in minutes. | No | `60` |

### Outputs

| Name | Description |
|------|-------------|
| `result` | Final text output from wing-agent. |
| `error` | Error message if execution failed. |

## Examples

| Workflow | Description | Source |
|----------|-------------|--------|
| **Auto Review** | Multi-trigger PR review (opened, unlabeled, @wing review, manual). | [`code-review.yml`](./examples/code-review.yml) |
| **Comment Trigger** | Review when `@wing review` is commented on a PR. | [`review-on-comment.yml`](./examples/review-on-comment.yml) |

## How It Works

1. **Install wing CLI** — `pip install wing-agent`
2. **Authenticate** — Generate installation token via `actions/create-github-app-token@v3`
3. **Isolate** — Set `HOME` to `${{ runner.temp }}/wing-home` to avoid polluting the runner
4. **Configure** — Write `~/.wing/core/config.yaml` with LLM credentials and tool registrations
5. **Execute** — Run `wing -p "<prompt>" --append-system-prompt "<instructions>" --yolo --max-turns N`
6. **Cleanup** — Reset git remote, remove isolated HOME and config (runs `if: always()`)

## Security Model

- **Isolated HOME**: All wing state lives in `${{ runner.temp }}/wing-home`, cleaned up after execution
- **Token masking**: Installation token registered via `::add-mask::`
- **Debug redaction**: When `runner.debug == '1'`, output is redacted (GitHub PATs, API keys, AWS keys, Bearer tokens)
- **Cleanup**: Git remote URL reset, HOME directory removal — runs even on failure
- **`pull_request_target`**: Workflow runs on base branch, PR diff fetched via `gh` API

## License

[MIT](./LICENSE)
