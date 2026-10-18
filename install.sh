#!/bin/sh
# Pulsar host installer:  curl -fsSL https://agentdeck.finnova.com.au/install.sh | sh
set -e
BASE="https://agentdeck.finnova.com.au"
if ! command -v node >/dev/null 2>&1; then
  echo "This Terminal installer needs Node.js 20 or newer."
  echo "Easier: download the Pulsar Mac app (no Node needed) from https://agentdeck.finnova.com.au/mac"
  exit 1
fi
MAJOR=$(node -p 'process.versions.node.split(".")[0]')
if [ "$MAJOR" -lt 20 ]; then
  echo "Pulsar needs Node.js 20 or newer (you have $(node -v))."
  exit 1
fi
DIR="$HOME/.agentdeck/bin"
mkdir -p "$DIR"
echo "Downloading Pulsar host…"
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
# Wait for the host to answer, then show the pairing code right away (browser window + Terminal QR).
for i in 1 2 3 4 5 6 7 8 9 10; do
  curl -fs http://127.0.0.1:48632/api/health >/dev/null 2>&1 && break
  sleep 1
done
echo ""
echo "Pulsar is running and starts with your computer."
echo "Scan this with the Pulsar app on your phone (or type the code shown under it):"
node "$DIR/agentdeck-host.cjs" pair || true
if command -v open >/dev/null 2>&1; then open "http://localhost:48632/pair" >/dev/null 2>&1 || true
elif command -v xdg-open >/dev/null 2>&1; then xdg-open "http://localhost:48632/pair" >/dev/null 2>&1 || true
fi
