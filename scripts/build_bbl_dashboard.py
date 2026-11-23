"""Build public weekly BBL dashboard data from an exported NAS box score snapshot."""

import argparse
import csv
import json
from collections import defaultdict
from datetime import date, datetime, timedelta
from pathlib import Path
from zoneinfo import ZoneInfo

BERLIN = ZoneInfo("Europe/Berlin")
STATS = ("points", "total_rebounds", "assists", "steals", "blocks", "efficiency")


def possessions(row):
    return (row["field_goals_attempted"] + .44 * row["free_throws_attempted"]
            - row["offensive_rebounds"] + row["turnovers"])


def ratings(totals):
    return {
        team: {"games": games, "possessions": round(pos, 1),
               "offense": round(100 * points / pos, 1),
               "defense": round(100 * allowed / pos, 1),
               "net": round(100 * (points - allowed) / pos, 1)}
        for team, (games, pos, points, allowed) in totals.items()
    }


def build_dashboard(source, standings_rows):
    standings_by_week = defaultdict(list)
    teams = {}
    for row in standings_rows:
        team = row["bbl_season_team_id"]
        teams[team] = row["team"]
        standings_by_week[row["week_ending"]].append({
            "team": team, **{field: int(row[field]) for field in
                             ("rank", "games", "wins", "losses", "point_difference")},
        })

    games_by_week = defaultdict(list)
    for game in source["games"]:
        day = datetime.fromisoformat(game["scheduled_time"]).astimezone(BERLIN).date()
        sunday = day + timedelta(days=6 - day.weekday())
        games_by_week[sunday.isoformat()].append(game)

    team_box = defaultdict(dict)
    for row in source["teams"]:
        team_box[row["game_id"]][str(row["franchise_id"])] = row
    player_box = defaultdict(list)
    for row in source["players"]:
        player_box[row["game_id"]].append(row)

    season_totals = defaultdict(lambda: [0, 0., 0, 0])
    players = {}
    weeks = []
    game_count = 0
    for sunday, standing in sorted(standings_by_week.items()):
        if date.fromisoformat(sunday).weekday() != 6 or {r["team"] for r in standing} != teams.keys():
            raise ValueError(f"Invalid standings snapshot for {sunday}")
        week_totals = defaultdict(lambda: [0, 0., 0, 0])
        weekly_players = {}
        for game in games_by_week[sunday]:
            game_id = game["game_id"]
            home, away = str(game["home_franchise_id"]), str(game["guest_franchise_id"])
            box = team_box[game_id]
            if set(box) != {home, away} or not player_box[game_id]:
                raise ValueError(f"Incomplete box scores for game {game_id}")
            scores = {home: game["home_final_score"], away: game["guest_final_score"]}
            if any(box[team]["points"] != scores[team] for team in box):
                raise ValueError(f"Team points do not reconcile for game {game_id}")
            # Average the two estimates so both teams use the same game pace.
            pace = sum(possessions(row) for row in box.values()) / 2
            if pace <= 0:
                raise ValueError(f"Invalid estimated possessions for game {game_id}")
            for team, opponent in ((home, away), (away, home)):
                for totals in (week_totals, season_totals):
                    current = totals[team]
                    current[0] += 1
                    current[1] += pace
                    current[2] += scores[team]
                    current[3] += scores[opponent]
            for row in player_box[game_id]:
                if row["seconds_played"] is None and not any(row[stat] for stat in STATS):
                    continue
                if row["seconds_played"] == 0 and not any(row[stat] for stat in STATS):
                    continue
                player = str(row["bbl_real_player_id"])
                if player == "None" or any(row[stat] is None for stat in STATS):
                    raise ValueError(f"Incomplete player stats for game {game_id}")
                players[player] = row["player_name"]
                total = weekly_players.setdefault(player, {"games": 0, "teams": [], **dict.fromkeys(STATS, 0)})
                team = str(row["franchise_id"])
                if team not in total["teams"]:
                    total["teams"].append(team)
                total["games"] += 1
                for stat in STATS:
                    total[stat] += row[stat]
            game_count += 1
        if any(row["games"] != season_totals[row["team"]][0] for row in standing):
            raise ValueError(f"Standings and box scores use different cutoffs for {sunday}")
        season_ratings = ratings({team: total for team, total in season_totals.items() if total[0]})
        weeks.append({"ending": sunday, "standings": standing, "players": weekly_players,
                      "weeklyRatings": ratings(week_totals), "seasonRatings": season_ratings})
    return {"season": "2026/27", "gameCount": game_count, "teams": teams,
            "players": players, "weeks": weeks}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("box_scores", type=Path)
    parser.add_argument("standings", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()
    with args.standings.open(encoding="utf-8", newline="") as stream:
        standings = list(csv.DictReader(stream))
    dashboard = build_dashboard(json.loads(args.box_scores.read_text(encoding="utf-8")), standings)
    serialized = json.dumps(dashboard, ensure_ascii=False, separators=(",", ":")) + "\n"
    args.output.write_text(serialized, encoding="utf-8")
    print(f"{len(dashboard['weeks'])} weeks, {dashboard['gameCount']} league games.")


if __name__ == "__main__":
    main()
