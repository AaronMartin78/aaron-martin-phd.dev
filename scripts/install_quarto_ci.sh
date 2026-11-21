#!/usr/bin/env bash
set -euo pipefail

# Quarto 1.11.9, the version used by the successful archive render.
# The release-asset API avoids repeated 504s at the browser download URL,
# but unauthenticated API calls from shared runners hit the rate limit (403),
# so send the workflow token when it is available and fall back to the
# browser download URL if the API still refuses.
installer="$RUNNER_TEMP/quarto-1.11.9-linux-amd64.deb"
auth=()
if [[ -n "${GH_TOKEN:-}" ]]; then
  auth=(--header "Authorization: Bearer $GH_TOKEN")
fi

fetch() {
  curl --fail --location --retry 3 --connect-timeout 15 --max-time 120 \
    "$@" --output "$installer"
}

fetch "${auth[@]}" --header 'Accept: application/octet-stream' \
  https://api.github.com/repos/quarto-dev/quarto-cli/releases/assets/692632703 \
|| fetch https://github.com/quarto-dev/quarto-cli/releases/download/v1.11.9/quarto-1.11.9-linux-amd64.deb

echo "64078d1623d9ab89da766591f3410a0756f3737a37efb0897c7e84b863bf092a  $installer" | sha256sum --check
sudo dpkg -i "$installer"
quarto --version
