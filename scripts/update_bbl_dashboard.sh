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
# Fails loudly (non-zero exit, ERROR line) when: the lake is not mounted, the
# published database is missing or older than MAX_AGE_HOURS, any build step
# fails, the push fails, or the previous data push has still not reached main
# after MERGE_GRACE_HOURS (the GitHub merge did not happen).
#
#   scripts/update_bbl_dashboard.sh            # build, commit, push
#   scripts/update_bbl_dashboard.sh --dry-run  # build and show the diff only
set -uo pipefail
cd "$(dirname "$0")/.."

LAKE="${BBL_LAKE:-/mnt/data_lake}"
SEASON="${BBL_SEASON:-2026-27}"
PYTHON="${PYTHON:-python3}"
MAX_AGE_HOURS="${BBL_MAX_AGE_HOURS:-36}"
MERGE_GRACE_HOURS="${BBL_MERGE_GRACE_HOURS:-20}"
STATE_FILE="${BBL_STATE_FILE:-$HOME/.config/bbl-newsletter/dashboard-last-push}"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
dry_run=0
[ "${1:-}" = "--dry-run" ] && dry_run=1

fail() { echo "ERROR: $*"; exit 1; }

echo "=== bbl dashboard update $(date -Is) ==="
mountpoint -q "$LAKE" || fail "data lake not mounted at $LAKE"
CURRENT="$LAKE/sqlite/bbl/current.json"
[ -r "$CURRENT" ] || fail "no published BBL database: $CURRENT missing"
DATABASE="$LAKE/sqlite/bbl/$("$PYTHON" -c 'import json,sys; print(json.load(open(sys.argv[1]))["database"])' "$CURRENT")"
[ -r "$DATABASE" ] || fail "published database not readable: $DATABASE"
age_hours=$("$PYTHON" - "$CURRENT" <<'EOF'
import json, sys
from datetime import datetime, timezone
built = datetime.fromisoformat(json.load(open(sys.argv[1]))["built_at_utc"])
print(int((datetime.now(timezone.utc) - built).total_seconds() // 3600))
EOF
) || fail "cannot read built_at_utc from $CURRENT"
echo "database: $DATABASE (published ${age_hours}h ago)"
[ "$age_hours" -le "$MAX_AGE_HOURS" ] || fail "published BBL database is ${age_hours}h old (limit ${MAX_AGE_HOURS}h): the mule collector did not run"

# Keep the editions checkout level with main, which already contains every
# merged edition, so the scripts and data files here are current.
git fetch -q origin || fail "git fetch failed"
git checkout -q editions || fail "cannot check out editions"
git merge -q --ff-only origin/editions 2>/dev/null || git merge -q --no-edit origin/editions || fail "cannot update editions"
git merge -q --no-edit origin/main || { git merge --abort; fail "cannot merge main into editions"; }

# The previous data push must have been merged by GitHub; otherwise the site
# is not updating even though pushes succeed.
if [ -r "$STATE_FILE" ]; then
    read -r last_commit last_epoch < "$STATE_FILE"
    if ! git merge-base --is-ancestor "$last_commit" origin/main 2>/dev/null; then
        hours=$(( ($(date +%s) - last_epoch) / 3600 ))
        if [ "$hours" -ge "$MERGE_GRACE_HOURS" ]; then
            fail "previous dashboard push $last_commit (${hours}h ago) was never merged into main; check the edition-checks workflow"
        fi
        echo "note: previous dashboard push $last_commit not yet on main (${hours}h ago)"
    fi
fi

# Standings, player leaders and team ratings from the box scores.
"$PYTHON" scripts/export_bbl_dashboard_source.py "$DATABASE" "$WORK/box.json" "$WORK/standings.csv" || fail "box-score export failed"
"$PYTHON" scripts/build_bbl_dashboard.py "$WORK/box.json" "$WORK/standings.csv" bbl/dashboard-data.json || fail "dashboard build failed"

# Five-man lineups from the archived game pages.
"$PYTHON" scripts/extract_bbl_snapshots_lake.py "$LAKE" "$WORK/snapshots.json" --season "$SEASON" || fail "raw archive extraction failed"
"$PYTHON" scripts/build_bbl_lineups.py "$WORK/snapshots.json" bbl/lineups-data.json || fail "lineup build failed"

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
git commit -q -m "BBL dashboard data $(date +%F) (automated)" || fail "commit failed"
git push -q origin editions || fail "push to editions failed"
mkdir -p "$(dirname "$STATE_FILE")"
echo "$(git rev-parse HEAD) $(date +%s)" > "$STATE_FILE"
echo "dashboard data pushed: $(git rev-parse --short HEAD)"
