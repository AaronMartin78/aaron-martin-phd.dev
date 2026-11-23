"""Build five-man lineup data for the BBL dashboard from play-by-play snapshots.

Input is either a JSON list of current-season snapshot records (as extracted from
the NAS Hermes raw archive: one record per game with `stats` holding the
official `actions` and `playerStats`) or a directory of gzip-compressed BBL API
detail payloads (the historical `details/<year>/game_<id>.json.gz` files).

Stints are reconstructed from SUBSTITUTION actions and the starting fives, then
checked against the official per-player seconds in the box score. Games whose
reconstruction disagrees with the box score by more than the tolerance are
excluded and reported, never silently used.
"""

import argparse
import gzip
import json
from collections import defaultdict
from datetime import datetime, timedelta
from pathlib import Path
from zoneinfo import ZoneInfo

BERLIN = ZoneInfo("Europe/Berlin")
PERIOD_SECONDS = {1: 600, 2: 600, 3: 600, 4: 600}
OVERTIME_SECONDS = 300
TOLERANCE = 60  # seconds per player
SHOT_TYPES = {"TWO_POINT_THROW", "THREE_POINT_THROW"}
TURNOVER_TYPES = {"TURN_OVER", "TEAM_TURN_OVER"}
# In a SUBSTITUTION action the feed names the player leaving in seasonPlayerId
# and the player entering in assistingSeasonPlayerId (verified against box
# score minutes; see --sub-direction to re-check).
SUB_DIRECTION = {"out": "seasonPlayerId", "in": "assistingSeasonPlayerId"}


def substitution(action):
    return str(action.get(SUB_DIRECTION["in"])), str(action.get(SUB_DIRECTION["out"]))


def period_length(period):
    return PERIOD_SECONDS.get(period, OVERTIME_SECONDS)


def elapsed(action):
    """Seconds since tip-off at the moment of the action."""
    before = sum(period_length(p) for p in range(1, action["period"]))
    parts = [int(part) for part in action["gameTime"].split(":")]
    remaining = parts[-1] + 60 * parts[-2] + (3600 * parts[-3] if len(parts) == 3 else 0)
    return before + period_length(action["period"]) - remaining


def load_games(source):
    """Yield normalised games: ids, date, competition and the official stats block."""
    if source.is_dir():
        for path in sorted(source.glob("*.json.gz")):
            with gzip.open(path, "rt", encoding="utf-8") as stream:
                stats = json.load(stream)
            yield {"game_id": stats["gameId"], "scheduledTime": stats["scheduledTime"],
                   "competition": stats["homeTeam"]["gameStat"].get("competition"), "stats": stats}
        return
    for record in json.loads(source.read_text(encoding="utf-8")):
        yield {"game_id": record["game_id"], "scheduledTime": record["scheduledTime"],
               "competition": record["competition"], "stats": record["stats"]}


def player_name(row):
    person = row.get("seasonPlayer") or {}
    name = " ".join(part for part in (person.get("firstName"), person.get("lastName")) if part)
    return name or person.get("name") or str(person.get("id"))


def reconstruct(game):
    """Return stints and a validation report for one game."""
    stats = game["stats"]
    sides = {stats["homeTeam"]["id"]: "home", stats["guestTeam"]["id"]: "guest"}
    roster = {}
    starters = defaultdict(set)
    official_seconds = {}
    for side in ("homeTeam", "guestTeam"):
        team = stats[side]["id"]
        for row in stats[side]["playerStats"]:
            person = row.get("seasonPlayer") or {}
            pid = str(person.get("id"))
            roster[pid] = (team, player_name(row), str(person.get("realPlayerId") or pid))
            official_seconds[pid] = int(row.get("secondsPlayed") or 0)
            if row.get("isStartingFive"):
                starters[team].add(pid)
    for team, five in starters.items():
        if len(five) != 5:
            return None, {"error": f"team {team} lists {len(five)} starters"}

    actions = sorted(stats["actions"], key=lambda a: (a["period"], a["orderId"]))
    teams = list(sides)
    on_court = {team: set(starters[team]) for team in teams}
    played = defaultdict(float)
    stints = []
    score = {"home": 0, "guest": 0}
    current = {"start": 0.0, "score": dict(score), "lineups": {t: frozenset(on_court[t]) for t in teams},
               "poss": {t: 0.0 for t in teams}}
    problems = []

    def close_stint(now):
        if now > current["start"]:
            for team in teams:
                for pid in current["lineups"][team]:
                    played[pid] += now - current["start"]
            stints.append({"start": current["start"], "end": now, "lineups": dict(current["lineups"]),
                           "points": {s: score[s] - current["score"][s] for s in score},
                           "poss": dict(current["poss"])})
        current["start"] = now
        current["score"] = dict(score)
        current["lineups"] = {t: frozenset(on_court[t]) for t in teams}
        current["poss"] = {t: 0.0 for t in teams}

    # Period starts: lineups can change between periods without substitution
    # events, so infer each period's opening five from who acts before being
    # substituted in.
    by_period = defaultdict(list)
    for action in actions:
        by_period[action["period"]].append(action)
    period_openers = {}
    for period, acts in by_period.items():
        if period == 1:
            continue
        for team in teams:
            seen, subbed_in = [], set()
            for action in acts:
                if action.get("seasonTeamId") != team:
                    continue
                pid = str(action.get("seasonPlayerId"))
                if action.get("type") == "SUBSTITUTION":
                    entering, leaving = substitution(action)
                    subbed_in.add(entering)
                    if leaving not in subbed_in and leaving not in seen and leaving in roster:
                        seen.append(leaving)
                elif pid in roster and pid not in subbed_in and pid not in seen:
                    seen.append(pid)
            period_openers[(period, team)] = seen

    current_period = 1
    for action in actions:
        now = float(elapsed(action))
        if action["period"] != current_period:
            boundary = float(sum(period_length(p) for p in range(1, action["period"])))
            close_stint(boundary)
            for team in teams:
                openers = period_openers.get((action["period"], team), [])
                if len(openers) > 5:
                    problems.append(f"period {action['period']} team {team}: {len(openers)} players act before any substitution")
                    openers = openers[:5]
                lineup = set(openers)
                for pid in sorted(on_court[team]):
                    if len(lineup) == 5:
                        break
                    lineup.add(pid)
                on_court[team] = lineup
            current["lineups"] = {t: frozenset(on_court[t]) for t in teams}
            current_period = action["period"]
        if action.get("type") == "SUBSTITUTION":
            team = action.get("seasonTeamId")
            entering, leaving = substitution(action)
            if team not in on_court:
                continue
            close_stint(now)
            if leaving not in on_court[team]:
                problems.append(f"{action['period']} {action['gameTime']}: {leaving} leaves but was not on court")
            on_court[team].discard(leaving)
            on_court[team].add(entering)
            if len(on_court[team]) != 5:
                problems.append(f"{action['period']} {action['gameTime']}: team {team} has {len(on_court[team])} on court")
            current["lineups"] = {t: frozenset(on_court[t]) for t in teams}
            continue
        if "homeTeamPoints" in action:
            score["home"] = action["homeTeamPoints"]
            score["guest"] = action["guestTeamPoints"]
        team = action.get("seasonTeamId")
        if team in on_court:
            kind = action.get("type")
            if kind in SHOT_TYPES:
                current["poss"][team] += 1
            elif kind == "FREE_THROW":
                current["poss"][team] += 0.44
            elif kind in TURNOVER_TYPES:
                current["poss"][team] += 1
            elif kind == "REBOUND" and "OFFENSIVE" in " ".join(action.get("qualifiers", [])).upper():
                current["poss"][team] -= 1
    total = float(sum(period_length(p) for p in range(1, current_period + 1)))
    close_stint(total)

    deviations = {pid: played[pid] - official_seconds[pid] for pid in official_seconds}
    worst = max((abs(d) for d in deviations.values()), default=0)
    report = {"worst_seconds": round(worst), "problems": problems,
              "players_off": sorted((pid, round(d)) for pid, d in deviations.items() if abs(d) > TOLERANCE)}
    return {"stints": stints, "roster": roster, "sides": sides, "teams": teams}, report


def week_ending(game):
    day = datetime.fromisoformat(game["scheduledTime"].replace("Z", "+00:00")).astimezone(BERLIN).date()
    return (day + timedelta(days=6 - day.weekday())).isoformat()


def build(source, competition="BBL"):
    weekly = defaultdict(lambda: defaultdict(lambda: {"seconds": 0.0, "poss": 0.0, "opp_poss": 0.0,
                                                      "pf": 0, "pa": 0, "games": set()}))
    teams, players = {}, {}
    accepted, rejected = [], []
    for game in load_games(source):
        if competition and game["competition"] != competition:
            continue
        result, report = reconstruct(game)
        if result is None or report["players_off"]:
            rejected.append((game["game_id"], report))
            continue
        accepted.append(game["game_id"])
        stats = game["stats"]
        for side in ("homeTeam", "guestTeam"):
            team = stats[side]["id"]
            teams[team] = (stats[side]["gameStat"].get("seasonTeam") or {}).get("name") or team
        real = {pid: entry[2] for pid, entry in result["roster"].items()}
        for pid, (team, name, real_id) in result["roster"].items():
            players[real_id] = name
        ending = week_ending(game)
        for stint in result["stints"]:
            for team in result["teams"]:
                side = result["sides"][team]
                other = "guest" if side == "home" else "home"
                other_team = next(t for t in result["teams"] if t != team)
                key = (team, tuple(sorted(real[p] for p in stint["lineups"][team])))
                row = weekly[ending][key]
                row["seconds"] += stint["end"] - stint["start"]
                row["poss"] += stint["poss"][team]
                row["opp_poss"] += stint["poss"][other_team]
                row["pf"] += stint["points"][side]
                row["pa"] += stint["points"][other]
                row["games"].add(game["game_id"])
    weeks = []
    for ending in sorted(weekly):
        rows = []
        for (team, lineup), row in weekly[ending].items():
            rows.append({"team": team, "players": list(lineup), "seconds": round(row["seconds"]),
                         "poss": round(row["poss"], 1), "oppPoss": round(row["opp_poss"], 1),
                         "pf": row["pf"], "pa": row["pa"], "games": len(row["games"])})
        weeks.append({"ending": ending, "lineups": rows})
    return {"gameCount": len(accepted), "rejected": [g for g, _ in rejected], "teams": teams,
            "players": players, "weeks": weeks}, rejected


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", type=Path, help="snapshot JSON list or directory of .json.gz payloads")
    parser.add_argument("output", type=Path, nargs="?")
    parser.add_argument("--competition", default="BBL", help="competition to keep (empty for all)")
    parser.add_argument("--validate", action="store_true", help="print the per-game validation report only")
    parser.add_argument("--sub-direction", choices=["player-out", "player-in"], default="player-out",
                        help="which player seasonPlayerId names in a SUBSTITUTION action")
    args = parser.parse_args()
    if args.sub_direction == "player-in":
        SUB_DIRECTION.update({"in": "seasonPlayerId", "out": "assistingSeasonPlayerId"})
    if args.validate:
        games = 0
        clean = 0
        for game in load_games(args.source):
            if args.competition and game["competition"] != args.competition:
                continue
            games += 1
            result, report = reconstruct(game)
            flag = "OK " if result and not report["players_off"] else "BAD"
            clean += flag == "OK "
            print(flag, game["game_id"], game["scheduledTime"][:10], report)
        print(f"{clean} of {games} games reconcile with the box score within {TOLERANCE}s per player")
        return
    data, rejected = build(args.source, args.competition)
    for game_id, report in rejected:
        print("rejected", game_id, report.get("error") or report["players_off"])
    serialized = json.dumps(data, ensure_ascii=False, separators=(",", ":")) + "\n"
    args.output.write_text(serialized, encoding="utf-8")
    print(f"{data['gameCount']} games accepted, {len(rejected)} rejected, {len(data['weeks'])} weeks.")


if __name__ == "__main__":
    main()
