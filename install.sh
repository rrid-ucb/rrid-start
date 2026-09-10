#!/bin/bash
# Gets the rrid Mac login far enough to clone the private team setup.
# No secrets. No Brewfile. Run only after you have switched to the rrid account.
#
#   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/rrid-ucb/rrid-start/main/install.sh)"
#
# Do NOT chown /opt/homebrew. Do NOT chmod -R g+w. Do NOT sudo brew as root.
# Do NOT run the official Homebrew installer from this login if a prefix exists.
set -euo pipefail

REPO="${BOOTSTRAP_REPO:-rrid-ucb/bootstrap}"
DEST="${BOOTSTRAP_DIR:-$HOME/src/bootstrap}"
EXPECT_USER="rrid"

prefix=""
if [[ -d /opt/homebrew ]]; then
  prefix=/opt/homebrew
elif [[ -d /usr/local/Homebrew ]]; then
  prefix=/usr/local
fi

brew_bin=""
if [[ -n "$prefix" && -x "$prefix/bin/brew" ]]; then
  brew_bin="$prefix/bin/brew"
fi

owner=""
if [[ -n "$prefix" ]]; then
  owner="$(stat -f '%Su' "$prefix")"
fi

me="$(whoami)"

echo "==> rrid-ucb/rrid-start"
echo "    user=$me  will clone $REPO -> $DEST"
echo ""

if [[ "$(uname -s)" != Darwin ]]; then
  echo "This installer is macOS-only." >&2
  exit 1
fi

if [[ "$me" != "$EXPECT_USER" ]]; then
  echo "Run this inside the $EXPECT_USER login (Fast User Switch). You are $me." >&2
  exit 1
fi

if ! xcode-select -p >/dev/null 2>&1; then
  echo "==> Installing Xcode Command Line Tools (click Install in the dialog)"
  xcode-select --install || true
  echo "Re-run this script after the Command Line Tools finish installing." >&2
  exit 1
fi

if [[ -n "$prefix" && -z "$brew_bin" ]]; then
  echo "Prefix $prefix exists but brew is missing." >&2
  echo "Do not run the official installer as $me — it can chown the prefix." >&2
  echo "Fix this while logged into the intended owner: $owner." >&2
  exit 1
fi

if [[ -z "$brew_bin" ]]; then
  echo "No Homebrew prefix found." >&2
  echo "Install Homebrew from https://brew.sh while logged into your *personal* admin," >&2
  echo "then Fast User Switch back to $EXPECT_USER and re-run this script." >&2
  echo "Do NOT install brew as $me if a personal account should own the prefix." >&2
  exit 1
fi

eval "$("$brew_bin" shellenv)"

as_owner() {
  if [[ "$owner" == "$me" ]]; then
    "$brew_bin" "$@"
  else
    echo "    brew $*  (as $owner)"
    sudo -Hu "$owner" "$brew_bin" "$@"
  fi
}

echo "==> Homebrew"
echo "    prefix=$prefix  owner=$owner  you=$me"
if [[ "$owner" == "$me" ]]; then
  echo "    role=owner  (unusual for a team login; brew writes run as you)"
else
  echo "    role=delegate  (writes: sudo -Hu $owner $brew_bin …)"
fi

echo "==> Installing gh, git, just (missing-only)"
as_owner install gh git just

if ! command -v gh >/dev/null 2>&1; then
  echo "gh is not on PATH after install. Open a new shell or check $prefix/bin." >&2
  exit 1
fi

if ! gh auth status >/dev/null 2>&1; then
  echo ""
  echo "==> GitHub login"
  echo "    Use YOUR GitHub user (the one invited to rrid-ucb), not a shared account."
  echo "    Safari is fine; Chrome profiles do not exist yet on this login."
  echo ""
  gh auth login --hostname github.com --git-protocol https --web
fi
gh auth setup-git

mkdir -p "$(dirname "$DEST")"
if [[ -d "$DEST/.git" ]]; then
  echo "==> $DEST already cloned; pulling"
  git -C "$DEST" pull --ff-only
else
  echo "==> Cloning $REPO -> $DEST"
  gh repo clone "$REPO" "$DEST"
fi

echo ""
echo "==> Running $DEST/script/setup"
exec "$DEST/script/setup"
