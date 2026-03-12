#!/usr/bin/env bash
set -e

info() { echo "==> $1"; }

# 1. Homebrew
if ! command -v brew &>/dev/null; then
  info "Installing Homebrew (may ask for your macOS password)..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  [ -f /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# 2. GitHub CLI
if ! command -v gh &>/dev/null; then
  info "Installing GitHub CLI..."
  brew install gh
fi

# 3. Auth + credential helper
if ! gh auth status &>/dev/null 2>&1; then
  info "Log in to GitHub (browser will open)..."
  gh auth login --web -p https
fi
gh auth setup-git

# 4. Install
BRANCH="${BRANCH:-main}"
REF_PARAM=""
[ "$BRANCH" != "main" ] && REF_PARAM="?ref=$BRANCH"
export BRANCH
gh api "repos/joinhandshake/claude-operators/contents/bin/install${REF_PARAM}" --jq '.content' | base64 -d | bash
