"""Export the dashboard build inputs from the canonical BBL SQLite database.

Writes two files that build_bbl_dashboard.py consumes:

* a box-score JSON with `games`, `teams` and `players` rows for every official
  main-round game of the season, taken from `games`, `game_team_stats` and
  `game_player_stats`;
* a weekly standings CSV with one row per team per completed week (Sunday),
  reconstructed from results with the BBL tie-break order (section 20:
  league points, head-to-head wins, head-to-head difference, overall
  difference, scoring ratio), the same rule validated against the official
  table in the Basketball project's backfill_bbl_weekly_standings.py.

The database is opened read-only.
"""

import argparse
import csv
import json
import sqlite3
from datetime import date, datetime, timedelta
from fractions import Fraction
from itertools import groupby
from pathlib import Path
from zoneinfo import ZoneInfo

BERLIN = ZoneInfo("Europe/Berlin")
TEAM_FIELDS = ("points", "field_goals_attempted", "free_throws_attempted", "offensive_rebounds", "turnovers")
PLAYER_FIELDS = ("seconds_played", "points", "total_rebounds", "assists", "steals", "blocks", "efficiency")


def record(games, team):
    wins = losses = points_for = points_against = 0
    for _, home, away, home_score, away_score in games:
        if team == home:
            scored, allowed = home_score, away_score
        elif team == away:
            scored, allowed = away_score, home_score
        else:
            continue
        wins += scored > allowed
        losses += scored < allowed
        points_for += scored
        points_against += allowed
    return wins, losses, points_for, points_against


def break_tie(teams, games, records):
    """Reapply head-to-head to the remaining tied teams after each split."""
    if len(teams) < 2:
        return [teams]
    head_to_head = [game for game in games if game[1] in teams and game[2] in teams]
    mini = {team: record(head_to_head, team) for team in teams}

    def head_wins(team):
        return mini[team][0]

    def head_difference(team):
        return mini[team][2] - mini[team][3]

    def overall_difference(team):
        return records[team][2] - records[team][3]

    def scoring_ratio(team):
        scored, allowed = records[team][2:]
        return -abs(Fraction(scored - allowed, allowed)) if allowed else Fraction(0)

    for criterion in (head_wins, head_difference, overall_difference, scoring_ratio):
        ordered = sorted(teams, key=criterion, reverse=True)
        groups = [list(group) for _, group in groupby(ordered, key=criterion)]
        if len(groups) > 1:
            return [result for group in groups for result in break_tie(group, games, records)]
    return [sorted(teams)]


def standings(teams, games):
    records = {team: record(games, team) for team in teams}

    def league_points(team):
        wins, losses, _, _ = records[team]
        return -wins, losses

    rank = 1
    rows = []
    for _, tied in groupby(sorted(teams, key=league_points), key=league_points):
        for group in break_tie(list(tied), games, records):
            for team in group:
                wins, losses, scored, allowed = records[team]
                rows.append((rank, team, teams[team], wins + losses, wins, losses, scored, allowed, scored - allowed))
            rank += len(group)
    return rows


def berlin_date(scheduled_time):
    return datetime.fromisoformat(scheduled_time.replace("Z", "+00:00")).astimezone(BERLIN).date()


def export(database, season_start_year, through):
    connection = sqlite3.connect(f"file:{database}?mode=ro", uri=True)
    connection.row_factory = sqlite3.Row
    season = connection.execute("SELECT season_id, label FROM seasons WHERE start_year = ?", (season_start_year,)).fetchone()
    if season is None:
        raise SystemExit(f"no season starting {season_start_year} in {database}")
    game_rows = connection.execute(
        """SELECT game_id, scheduled_time, home_franchise_id, guest_franchise_id, home_team_name, guest_team_name,
                  home_final_score, guest_final_score
           FROM games WHERE season_id = ? AND competition = 'BBL' AND stage = 'MAIN_ROUND'
           ORDER BY scheduled_time, game_id""", (season["season_id"],)).fetchall()
    fixtures = [dict(row) for row in game_rows]
    teams = {}
    for row in fixtures:
        teams[row["home_franchise_id"]] = row["home_team_name"]
        teams[row["guest_franchise_id"]] = row["guest_team_name"]
    official = [row for row in connection.execute(
        """SELECT game_id, scheduled_time, home_franchise_id, guest_franchise_id, home_final_score, guest_final_score
           FROM games WHERE season_id = ? AND competition = 'BBL' AND stage = 'MAIN_ROUND' AND status = 'OFFICIAL'
             AND home_final_score IS NOT NULL AND guest_final_score IS NOT NULL
           ORDER BY scheduled_time, game_id""", (season["season_id"],))
        if berlin_date(row["scheduled_time"]) <= through]
    ids = tuple(row["game_id"] for row in official)
    marks = ",".join("?" * len(ids))
    team_stats = [dict(row) for row in connection.execute(
        f"SELECT game_id, franchise_id, home_away, {', '.join(TEAM_FIELDS)} FROM game_team_stats WHERE game_id IN ({marks})", ids)]
    player_stats = [dict(row) for row in connection.execute(
        f"""SELECT game_id, franchise_id, bbl_real_player_id, bbl_season_player_id, player_name, is_starting_five,
                   {', '.join(PLAYER_FIELDS)}
            FROM game_player_stats WHERE game_id IN ({marks})""", ids)]
    for rows, fields in ((team_stats, TEAM_FIELDS), (player_stats, PLAYER_FIELDS)):
        for row in rows:
            for field in fields:
                if row[field] is not None:
                    row[field] = int(row[field]) if float(row[field]).is_integer() else row[field]
    for row in player_stats:
        # Source names occasionally carry stray spaces.
        row["player_name"] = " ".join((row["player_name"] or "").split())
    box_scores = {"season": season["label"], "exported_through": through.isoformat(),
                  "games": [dict(row) for row in official], "teams": team_stats, "players": player_stats}

    results = [(berlin_date(row["scheduled_time"]), row["home_franchise_id"], row["guest_franchise_id"],
                row["home_final_score"], row["guest_final_score"]) for row in official]
    first_day = min(game[0] for game in results) if results else through
    sunday = first_day + timedelta(days=6 - first_day.weekday())
    snapshots = []
    while sunday <= through:
        available = [game for game in results if game[0] <= sunday]
        snapshots.extend((sunday.isoformat(), *row) for row in standings(teams, available))
        sunday += timedelta(days=7)
    return box_scores, snapshots, len(fixtures)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("database", type=Path)
    parser.add_argument("box_scores", type=Path, help="output JSON for build_bbl_dashboard.py")
    parser.add_argument("standings", type=Path, help="output CSV for build_bbl_dashboard.py")
    parser.add_argument("--season", type=int, default=2026, help="season start year")
    parser.add_argument("--through", type=date.fromisoformat,
                        help="last Sunday to include (default: the most recent Sunday before today, Berlin time)")
    args = parser.parse_args()
    through = args.through
    if through is None:
        today = datetime.now(BERLIN).date()
        through = today - timedelta(days=today.weekday() + 1)  # last completed Sunday
    box_scores, snapshots, fixture_count = export(args.database, args.season, through)
    args.box_scores.write_text(json.dumps(box_scores, ensure_ascii=False, separators=(",", ":")) + "\n", encoding="utf-8")
    with args.standings.open("w", newline="", encoding="utf-8") as stream:
        writer = csv.writer(stream)
        writer.writerow(("week_ending", "rank", "bbl_season_team_id", "team", "games", "wins", "losses",
                         "points_for", "points_against", "point_difference"))
        writer.writerows(snapshots)
    weeks = len({row[0] for row in snapshots})
    print(f"{box_scores['season']}: {len(box_scores['games'])} official games of {fixture_count} fixtures through {through}, "
          f"{weeks} weekly standings snapshots.")


if __name__ == "__main__":
    main()
