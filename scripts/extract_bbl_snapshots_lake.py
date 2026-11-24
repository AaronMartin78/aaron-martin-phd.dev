"""Collect the newest game page per BBL game from the data lake's raw archive.

The daily BBL collector (Basketball/BBL/daily on the mule) stores each fetched
game page under `raw/bbl/<season>/<run_id>/request-NNN.json.gz` as its two
sports objects, `initialGameData` and `initialGameStats`, and lists every
request with its URL in the run's `source_requests.json`. This script walks
the runs in order, keeps the last page fetched for each game, and writes the
record list that build_bbl_lineups.py reads. Only games whose page carries
official stats with play-by-play actions are kept.

    python scripts/extract_bbl_snapshots_lake.py /mnt/data_lake snapshots.json --season 2026-27
"""

import argparse
import gzip
import json
from pathlib import Path


def team(block):
    block = block or {}
    return {"seasonTeamId": block.get("seasonTeamId"), "teamId": block.get("teamId"), "name": block.get("name")}


def extract(lake_root, season):
    latest = {}
    root = Path(lake_root) / "raw" / "bbl" / season
    for run in sorted(path for path in root.iterdir() if path.is_dir()):
        requests_file = run / "source_requests.json"
        if not requests_file.exists():
            continue
        for request in json.loads(requests_file.read_text(encoding="utf-8")):
            url = request.get("url") or ""
            body = request.get("body_file")
            if "/spiele/" not in url or not body or request.get("error"):
                continue
            with gzip.open(run / body, "rt", encoding="utf-8") as stream:
                page = json.load(stream)
            data = page.get("initialGameData") or {}
            game_id = str(data.get("id") or url.rstrip("/").split("/")[-1])
            latest[game_id] = {
                "game_id": game_id, "retrieved_at": request.get("finished_at_utc"), "run_id": run.name,
                "competition": data.get("competition"), "status": data.get("status"),
                "scheduledTime": data.get("scheduledTime"), "home": team(data.get("homeTeam")),
                "guest": team(data.get("guestTeam")), "stats": page.get("initialGameStats"),
            }
    return [game for game in latest.values() if game["stats"] and game["stats"].get("actions")], len(latest)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("lake_root", type=Path, help="data lake root, e.g. /mnt/data_lake")
    parser.add_argument("output", type=Path)
    parser.add_argument("--season", default="2026-27")
    args = parser.parse_args()
    kept, seen = extract(args.lake_root, args.season)
    args.output.write_text(json.dumps(kept, ensure_ascii=False), encoding="utf-8")
    print(f"{seen} games seen in raw/bbl/{args.season}, {len(kept)} with play-by-play written to {args.output}")


if __name__ == "__main__":
    main()
