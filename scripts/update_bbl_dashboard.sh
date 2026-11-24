#!/usr/bin/env bash
# Refresh the BBL dashboard data files and push them on the editions branch.
#
# Runs on the HUB inside the website clone (~/newsletter/website), after the
# newsletter's daily publish. Everything is read from the NAS data lake
# (mounted at /mnt/data_lake), where the daily BBL collector on the mule
# publishes bbl.db (sqlite/bbl/current.json) and archives the game pages with
# play-by-play (raw/bbl/<season>/). Commits only when a data file changed;
# GitHub's edition-checks workflow then validates, merges and deploys.
#
#   scripts/update_bbl_dashboard.sh            # build, commit, push
#   scripts/update_bbl_dashboard.sh --dry-run  # build and show the diff only
set -uo pipefail
cd "$(dirname "$0")/.."

LAKE="${BBL_LAKE:-/mnt/data_lake}"
SEASON="${BBL_SEASON:-2026-27}"
PYTHON="${PYTHON:-python3}"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
dry_run=0
[ "${1:-}" = "--dry-run" ] && dry_run=1

echo "=== bbl dashboard update $(date -Is) ==="
if ! mountpoint -q "$LAKE"; then
    echo "ERROR: data lake not mounted at $LAKE"
    exit 1
fi
DATABASE="$LAKE/sqlite/bbl/$("$PYTHON" -c 'import json,sys; print(json.load(open(sys.argv[1]))["database"])' "$LAKE/sqlite/bbl/current.json")"
if [ ! -r "$DATABASE" ]; then
    echo "ERROR: published database not readable: $DATABASE"
    exit 1
fi
echo "database: $DATABASE"

# Keep the editions checkout level with main, which already contains every
# merged edition, so the scripts and data files here are current.
git fetch -q origin || { echo "ERROR: git fetch failed"; exit 1; }
git checkout -q editions || exit 1
git merge -q --ff-only origin/editions 2>/dev/null || git merge -q --no-edit origin/editions || { echo "ERROR: cannot update editions"; exit 1; }
git merge -q --no-edit origin/main || { echo "ERROR: cannot merge main into editions"; git merge --abort; exit 1; }

# Standings, player leaders and team ratings from the box scores.
"$PYTHON" scripts/export_bbl_dashboard_source.py "$DATABASE" "$WORK/box.json" "$WORK/standings.csv" || exit 1
"$PYTHON" scripts/build_bbl_dashboard.py "$WORK/box.json" "$WORK/standings.csv" bbl/dashboard-data.json || exit 1

# Five-man lineups from the archived game pages. Optional: the previous file
# stays in place when the raw archive cannot be read.
if "$PYTHON" scripts/extract_bbl_snapshots_lake.py "$LAKE" "$WORK/snapshots.json" --season "$SEASON"; then
    "$PYTHON" scripts/build_bbl_lineups.py "$WORK/snapshots.json" bbl/lineups-data.json || exit 1
else
    echo "WARN: raw archive extraction failed; lineups left unchanged"
fi

if git diff --quiet -- bbl/dashboard-data.json bbl/lineups-data.json; then
    echo "dashboard data unchanged"
    exit 0
fi
git --no-pager diff --stat -- bbl/dashboard-data.json bbl/lineups-data.json
if [ $dry_run -eq 1 ]; then
    echo "dry run: not committing"
    git checkout -q -- bbl/dashboard-data.json bbl/lineups-data.json
    exit 0
fi
git add bbl/dashboard-data.json bbl/lineups-data.json
git commit -q -m "BBL dashboard data $(date +%F) (automated)" || exit 1
git push -q origin editions || { echo "ERROR: push failed"; exit 1; }
echo "dashboard data pushed"
