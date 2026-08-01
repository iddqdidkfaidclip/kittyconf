#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
DEST="${XDG_CONFIG_HOME:-$HOME/.config}/kitty"
ZSHRC="${ZDOTDIR:-$HOME}/.zshrc"

echo "==> Installing into: $DEST"
mkdir -p "$DEST"

for f in kitty.conf iddqdkittyconf.conf; do
  target="$DEST/$f"
  if [[ -e "$target" || -L "$target" ]]; then
    backup="${target}.bak.$(date +%Y%m%d-%H%M%S)"
    echo "==> Backup: $backup"
    mv "$target" "$backup"
  fi
  ln -s "$REPO_DIR/$f" "$target"
  echo "==> Linked $f"
done

if ! command -v kitty >/dev/null 2>&1 && [[ ! -x /Applications/kitty.app/Contents/MacOS/kitty ]]; then
  echo "==> kitty not found. Install: brew install --cask kitty"
fi

if [[ "$(uname)" == "Darwin" ]]; then
  if ! ls "$HOME/Library/Fonts"/Hack*.ttf >/dev/null 2>&1 \
     && ! ls /Library/Fonts/Hack*.ttf >/dev/null 2>&1 \
     && ! ls /System/Library/Fonts/**/Hack* >/dev/null 2>&1; then
    echo "==> Hack not found. Install: brew install --cask font-hack"
  fi
fi

# --- zsh-autosuggestions (серые подсказки при вводе) ---
if command -v brew >/dev/null 2>&1; then
  if ! brew list zsh-autosuggestions >/dev/null 2>&1; then
    echo "==> Installing zsh-autosuggestions"
    brew install zsh-autosuggestions
  else
    echo "==> zsh-autosuggestions already installed"
  fi

  autosuggest_src='source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh'
  touch "$ZSHRC"

  if ! grep -qF 'zsh-autosuggestions.zsh' "$ZSHRC"; then
    echo "==> Adding zsh-autosuggestions to $ZSHRC"
    {
      echo ''
      echo '# iddqdkittyconf: gray autosuggestions (uses kitty color8)'
      echo "ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8'"
      echo "$autosuggest_src"
    } >> "$ZSHRC"
  else
    if ! grep -qF 'ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE' "$ZSHRC"; then
      echo "==> Adding ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE to $ZSHRC"
      # insert style line before the source line
      tmp="$(mktemp)"
      awk -v style="ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8'" '
        /zsh-autosuggestions\.zsh/ && !done {
          print style
          done=1
        }
        { print }
      ' "$ZSHRC" > "$tmp"
      mv "$tmp" "$ZSHRC"
    else
      echo "==> zsh-autosuggestions already configured in $ZSHRC"
    fi
  fi
else
  echo "==> brew not found — skip zsh-autosuggestions"
  echo "    Manual: brew install zsh-autosuggestions"
fi

echo "==> Done. Reload kitty: Ctrl+Cmd+,"
echo "    Reload shell: source ~/.zshrc  (или новая вкладка)"
