#!/usr/bin/env bash
set -euo pipefail

# Quarto 1.11.9, the version used by the successful archive render.
# The release-asset API avoids repeated 504s at the browser download URL.
installer="$RUNNER_TEMP/quarto-1.11.9-linux-amd64.deb"
curl --fail --location --retry 3 --connect-timeout 15 --max-time 120 \
  --header 'Accept: application/octet-stream' \
  https://api.github.com/repos/quarto-dev/quarto-cli/releases/assets/692632703 \
  --output "$installer"
echo "64078d1623d9ab89da766591f3410a0756f3737a37efb0897c7e84b863bf092a  $installer" | sha256sum --check
sudo dpkg -i "$installer"
quarto --version
