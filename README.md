# HAI Operator OS — Installer

One command to set up the HAI Operator OS. Handles everything: Homebrew, GitHub CLI, authentication, and the full operator toolkit.

## Install

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/joinhandshake/claude-operators-installer/main/install.sh)
```

## What it does

1. Installs [Homebrew](https://brew.sh) (if missing) — may prompt for your macOS password
2. Installs [GitHub CLI](https://cli.github.com) (if missing)
3. Authenticates GitHub CLI via browser (if not already logged in)
4. Runs the full operator install from the private [claude-operators](https://github.com/joinhandshake/claude-operators) repo

## After install

Open a new terminal, then:

```bash
claude-operator
```

## Troubleshooting

If something goes wrong, re-run the install command above. It's idempotent — safe to run multiple times.

For persistent issues:

```bash
claude-operator doctor
```
