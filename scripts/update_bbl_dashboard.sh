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

# This script merges main into the checkout while running, which can rewrite
# this very file under bash. Run from a private copy so the merge cannot
# change the code mid-run; the merged version is used from the next run on.
if [ -z "${BBL_UPDATE_COPY:-}" ]; then
    self="$(readlink -f "$0")"
    copy="$(mktemp)"
    cp "$self" "$copy"
    BBL_UPDATE_SELF="$self" BBL_UPDATE_COPY="$copy" exec bash "$copy" "$@"
fi
cd "$(dirname "$BBL_UPDATE_SELF")/.." || exit 1

LAKE="${BBL_LAKE:-/mnt/data_lake}"
SEASON="${BBL_SEASON:-2026-27}"
PYTHON="${PYTHON:-python3}"
MAX_AGE_HOURS="${BBL_MAX_AGE_HOURS:-36}"
MERGE_GRACE_HOURS="${BBL_MERGE_GRACE_HOURS:-20}"
STATE_FILE="${BBL_STATE_FILE:-$HOME/.config/bbl-newsletter/dashboard-last-push}"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK" "$BBL_UPDATE_COPY"' EXIT
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

# Build everything in the work folder first; the files in bbl/ are replaced
# only once every step has succeeded, so a failure leaves the current data
# (and the live site) exactly as it was.
"$PYTHON" scripts/export_bbl_dashboard_source.py "$DATABASE" "$WORK/box.json" "$WORK/standings.csv" || fail "box-score export failed"
"$PYTHON" scripts/build_bbl_dashboard.py "$WORK/box.json" "$WORK/standings.csv" "$WORK/dashboard-data.json" || fail "dashboard build failed"
"$PYTHON" scripts/extract_bbl_snapshots_lake.py "$LAKE" "$WORK/snapshots.json" --season "$SEASON" || fail "raw archive extraction failed"
"$PYTHON" scripts/build_bbl_lineups.py "$WORK/snapshots.json" "$WORK/lineups-data.json" || fail "lineup build failed"
for name in dashboard-data.json lineups-data.json; do
    "$PYTHON" -c 'import json,sys; json.load(open(sys.argv[1]))' "$WORK/$name" || fail "$name is not valid JSON"
done
cp "$WORK/dashboard-data.json" "$WORK/lineups-data.json" bbl/

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
# The newsletter's own push to editions a few minutes earlier may still be
# going through GitHub (edition-checks -> merge -> Pages deploy). Two Pages
# deployments landing within a minute of each other made run #99 fail on
# 2026-11-24 ("No artifacts named github-pages-1"), so wait for the queue to
# drain before pushing. Read-only public API, no token. If the API cannot be
# read or the wait runs out, push anyway: the deploy concurrency group still
# serialises, and the 20 h merge check catches a lost deployment tomorrow.
REPO_API="${BBL_REPO_API:-https://api.github.com/repos/AaronMartin78/aaron-martin-phd.dev}"
busy_runs() {
    curl -fsS --max-time 20 "$REPO_API/actions/runs?per_page=10" 2>/dev/null \
      | "$PYTHON" -c 'import json,sys; runs=json.load(sys.stdin)["workflow_runs"]; print(sum(1 for r in runs if r["name"] in ("Edition checks","Deploy site") and r["status"]!="completed"))' 2>/dev/null \
      || echo "?"
}
for attempt in $(seq 1 30); do
    busy=$(busy_runs)
    [ "$busy" = "0" ] && break
    [ "$busy" = "?" ] && { echo "note: GitHub API not readable; not waiting"; break; }
    [ "$attempt" -eq 1 ] && echo "waiting for $busy GitHub run(s) to finish before pushing"
    sleep 30
done

git add bbl/dashboard-data.json bbl/lineups-data.json
git commit -q -m "BBL dashboard data $(date +%F) (automated)" || fail "commit failed"
git push -q origin editions || fail "push to editions failed"
mkdir -p "$(dirname "$STATE_FILE")"
echo "$(git rev-parse HEAD) $(date +%s)" > "$STATE_FILE"
echo "dashboard data pushed: $(git rev-parse --short HEAD)"
