# Setting Up Your GitHub App

This guide walks you through creating a GitHub App for wing-action. The App gives your review bot a custom name and avatar.

## Step 1: Create the GitHub App

1. Go to **Settings → Developer settings → GitHub Apps → New GitHub App**
   - For personal accounts: click your avatar → Settings → Developer settings
   - For organizations: Organization → Settings → Developer settings

2. Fill in the registration form:

| Field | Value |
|-------|-------|
| **GitHub App name** | Your bot name (e.g., `my-reviewer-bot`) |
| **Description** | AI code review powered by wing-agent |
| **Homepage URL** | `https://github.com/lpdink/wing-action` |
| **Callback URL** | *(leave empty)* |
| **Expire user authorization tokens** | ☐ Unchecked |
| **Request user authorization (OAuth) during installation** | ☐ Unchecked |
| **Active (Webhook)** | ☐ Unchecked |

3. Set **Permissions**:

| Permission | Access |
|-----------|--------|
| **Repository permissions** | |
| Contents | Read-only |
| Issues | Read & Write |
| Pull requests | Read & Write |
| **Organization permissions** | |
| *(none needed)* | |

4. Under **Where can this GitHub App be installed?**, choose:
   - **Any account** — if you want others to be able to install it
   - **Only on this account** — for private use

5. Click **Create GitHub App**.

## Step 2: Generate a Private Key

1. On your App's settings page, scroll to **Private keys**.
2. Click **Generate a private key**.
3. A `.pem` file will download. Save it securely.

## Step 3: Store Credentials in Your Repository

### App ID (as a variable)

1. On the App settings page, find the **App ID** (a number like `123456`).
2. In your repository: **Settings → Secrets and variables → Actions → Variables**.
3. Click **New repository variable**.
4. Name: `WING_APP_ID`, Value: the App ID number.

### Private Key (as a secret)

1. Open the downloaded `.pem` file in a text editor. Copy the entire contents (including `-----BEGIN RSA PRIVATE KEY-----` and `-----END RSA PRIVATE KEY-----`).
2. In your repository: **Settings → Secrets and variables → Actions → Secrets**.
3. Click **New repository secret**.
4. Name: `WING_APP_PRIVATE_KEY`, Value: paste the entire PEM contents.

### LLM API Key (as a secret)

1. Add another secret for your LLM provider:
   - Name: `LLM_API_KEY`, Value: your API key (e.g., `sk-...`)

## Step 4: Install the App on Your Repository

1. On the App settings page, click **Install App** in the left sidebar.
2. Choose the account/organization where your repository lives.
3. Select **Only select repositories** and choose your target repository.
4. Click **Install**.

## Step 5: Add the Workflow

Copy one of the [example workflows](../examples/) to `.github/workflows/` in your repository.

That's it! Open a PR to see your bot in action. 🎉

## Troubleshooting

| Problem | Solution |
|---------|----------|
| "App not installed" error | Make sure you installed the App on the correct repository (Step 4) |
| "Invalid private key" error | Ensure you copied the entire PEM file contents, including the BEGIN/END lines |
| Bot comments show as `github-actions[bot]` | Verify `WING_APP_ID` is set as a **variable** (not a secret) |
