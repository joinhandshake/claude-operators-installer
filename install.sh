#!/usr/bin/env bash
set -e

info() { echo "==> $1"; }
die()  { echo "error: $1" >&2; exit 1; }

INSTALL_DIR="$HOME/.claude-operator"
BIN_DIR="$INSTALL_DIR/bin"
REPO_DIR="$INSTALL_DIR/repo"
GITHUB_REPO="joinhandshake/claude-operators"
BRANCH="${BRANCH:-main}"

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

# 3. Auth
if ! gh auth status &>/dev/null 2>&1; then
  info "Log in to GitHub (browser will open)..."
  gh auth login --web -p https
fi
gh auth setup-git

# 4. Download Go binary from latest release
mkdir -p "$BIN_DIR"
ARCH=$(uname -m)
case "$ARCH" in
  arm64|aarch64) ARCH="arm64" ;;
  x86_64)        ARCH="amd64" ;;
  *) die "Unsupported architecture: $ARCH" ;;
esac
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ASSET="claude-operator-${OS}-${ARCH}"

info "Downloading claude-operator binary..."
gh release download --repo "$GITHUB_REPO" --pattern "$ASSET" --dir "$BIN_DIR" --clobber \
  || die "Failed to download binary. Check gh auth and repo access."
mv "$BIN_DIR/$ASSET" "$BIN_DIR/claude-operator"
chmod +x "$BIN_DIR/claude-operator"

# 5. Clone repo (plugins + configs)
if [ -d "$REPO_DIR/.git" ]; then
  git -C "$REPO_DIR" fetch origin --quiet
  git -C "$REPO_DIR" checkout -B "$BRANCH" "origin/$BRANCH" --quiet
  git -C "$REPO_DIR" reset --hard "origin/$BRANCH" --quiet
else
  info "Cloning operator plugins..."
  gh repo clone "https://github.com/$GITHUB_REPO.git" "$REPO_DIR" -- --branch "$BRANCH" --quiet
fi

# 6. PATH
case "$SHELL" in
  */zsh)  SHELL_RC="$HOME/.zshrc" ;;
  */bash) SHELL_RC="$HOME/.bashrc" ;;
  *)      SHELL_RC="$HOME/.profile" ;;
esac

for old_rc in "$HOME/.zshenv" "$HOME/.bash_profile"; do
  [ "$old_rc" = "$SHELL_RC" ] && continue
  sed -i '' '/claude-operator\/bin/d' "$old_rc" 2>/dev/null || true
done

if ! grep -q 'claude-operator/bin' "$SHELL_RC" 2>/dev/null; then
  echo 'export PATH="$HOME/.claude-operator/bin:$PATH"' >> "$SHELL_RC"
  info "Added ~/.claude-operator/bin to PATH in $(basename "$SHELL_RC")"
fi

# 7. Configs
mkdir -p "$INSTALL_DIR"
ln -sf "$REPO_DIR/plugins/hai-operators/scripts/configs/CLAUDE.md" "$INSTALL_DIR/CLAUDE.md"
[ ! -f "$INSTALL_DIR/settings.json" ] && \
  cp "$REPO_DIR/plugins/hai-operators/scripts/configs/settings.json" "$INSTALL_DIR/settings.json"

echo ""
info "Install complete!"
echo ""
echo "  Activate in this terminal:  source $SHELL_RC"
echo "  Start Operator OS:          claude-operator"
echo "  Check environment health:   claude-operator doctor"
echo ""
