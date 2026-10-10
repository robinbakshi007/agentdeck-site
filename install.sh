#!/bin/sh
# AgentDeck host installer:  curl -fsSL https://robinbakshi007.github.io/agentdeck-site/install.sh | sh
set -e
BASE="https://robinbakshi007.github.io/agentdeck-site"
if ! command -v node >/dev/null 2>&1; then
  echo "AgentDeck needs Node.js 20 or newer. Install it from https://nodejs.org (or: brew install node), then run this again."
  exit 1
fi
MAJOR=$(node -p 'process.versions.node.split(".")[0]')
if [ "$MAJOR" -lt 20 ]; then
  echo "AgentDeck needs Node.js 20 or newer (you have $(node -v))."
  exit 1
fi
DIR="$HOME/.agentdeck/bin"
mkdir -p "$DIR"
echo "Downloading AgentDeck host…"
curl -fsSL "$BASE/agentdeck-host.cjs" -o "$DIR/agentdeck-host.cjs.tmp"
curl -fsSL "$BASE/agentdeck-host.cjs.sha256" -o "$DIR/agentdeck-host.cjs.sha256"
EXPECTED=$(cut -d' ' -f1 "$DIR/agentdeck-host.cjs.sha256")
ACTUAL=$(shasum -a 256 "$DIR/agentdeck-host.cjs.tmp" 2>/dev/null || sha256sum "$DIR/agentdeck-host.cjs.tmp")
ACTUAL=$(echo "$ACTUAL" | cut -d' ' -f1)
if [ "$EXPECTED" != "$ACTUAL" ]; then
  rm -f "$DIR/agentdeck-host.cjs.tmp"
  echo "Download checksum mismatch; aborting."
  exit 1
fi
mv "$DIR/agentdeck-host.cjs.tmp" "$DIR/agentdeck-host.cjs"
chmod +x "$DIR/agentdeck-host.cjs"
# Stop an older copy if one is running, then install the login item (starts it now and at every login).
node "$DIR/agentdeck-host.cjs" uninstall >/dev/null 2>&1 || true
node "$DIR/agentdeck-host.cjs" install
echo ""
echo "Next: open http://localhost:48632 and tap 'Show pairing code', then scan it with the AgentDeck app."
