"""Extract the newest play-by-play snapshot per BBL game from the NAS Hermes archive.

Runs ON THE NAS with the stock Python 3 (no third-party modules), reading the
incremental collection bundles the Hermes ingest service archives under the
RAID root. Writes one JSON list to the path given as the first argument (or
/tmp/bbl_snapshots.json). Only games whose snapshot carries official stats and
actions are kept. Pair it with build_bbl_lineups.py:

    ssh nas python3 - /tmp/bbl_snapshots.json < scripts/extract_bbl_snapshots_nas.py
    scp nas:/tmp/bbl_snapshots.json .
    python scripts/build_bbl_lineups.py bbl_snapshots.json bbl/lineups-data.json
"""

import glob
import json
import os
import sys

RAW = "/srv/dev-disk-by-uuid-d2d6a3b9-0028-4483-b517-6a31615190e8/hermes-pipeline/raw"


def team(block):
    block = block or {}
    return {"seasonTeamId": block.get("seasonTeamId"), "teamId": block.get("teamId"), "name": block.get("name")}


def main():
    output = sys.argv[1] if len(sys.argv) > 1 else "/tmp/bbl_snapshots.json"
    latest = {}
    for run in sorted(glob.glob(RAW + "/*.json"), key=os.path.getmtime):
        try:
            with open(run, encoding="utf-8") as stream:
                bundle = json.load(stream)
        except (OSError, ValueError):
            continue
        for entry in bundle.get("files", []):
            path = entry.get("path", "")
            if "spiele_" not in path:
                continue
            document = entry.get("document")
            if isinstance(document, str):
                try:
                    document = json.loads(document)
                except ValueError:
                    continue
            payload = (document or {}).get("payload") or {}
            data = payload.get("initialGameData") or {}
            game_id = str(data.get("id") or path.split("spiele_")[1].split("-")[0])
            record = {"game_id": game_id, "retrieved_at": document.get("retrieved_at"),
                      "competition": data.get("competition"), "status": data.get("status"),
                      "scheduledTime": data.get("scheduledTime"), "home": team(data.get("homeTeam")),
                      "guest": team(data.get("guestTeam")), "stats": payload.get("initialGameStats")}
            previous = latest.get(game_id)
            if previous is None or (record["retrieved_at"] or "") >= (previous["retrieved_at"] or ""):
                latest[game_id] = record
    kept = [game for game in latest.values() if game["stats"] and game["stats"].get("actions")]
    with open(output, "w", encoding="utf-8") as stream:
        json.dump(kept, stream)
    print(f"{len(latest)} games seen, {len(kept)} with play-by-play written to {output}")


if __name__ == "__main__":
    main()
