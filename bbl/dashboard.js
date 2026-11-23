const find = (id) => document.getElementById(id);
const weekSelect = find("bbl-dashboard-week");
const dateLabel = new Intl.DateTimeFormat("en-GB", {day: "numeric", month: "short", timeZone: "UTC"});
const stats = [
  ["points", "Points"], ["total_rebounds", "Rebounds"], ["assists", "Assists"],
  ["steals", "Steals"], ["blocks", "Blocks"],
];
const palette = ["#245681", "#a03b38", "#28774b", "#783a90", "#91521b", "#267581",
  "#93690f", "#aa3669", "#4d597d", "#596623", "#563568", "#18776d", "#965139",
  "#2a6aa3", "#8a2f53", "#475947", "#7d6138", "#6e4b5c"];
// Short names for chart labels; the full sponsor names stay in the tables.
const shortNames = {
  "486": "Bayern", "415": "Bonn", "430": "Oldenburg", "551": "Rostock", "422": "Braunschweig",
  "418": "Ulm", "413": "Alba Berlin", "426": "Skyliners", "483": "Jena", "540": "Würzburg",
  "541": "Vechta", "485": "Chemnitz", "414": "Trier", "433": "Ludwigsburg", "473": "Hagen",
  "428": "MBC", "554": "Hamburg", "420": "Bamberg",
};

function html(tag, text, className) {
  const node = document.createElement(tag);
  if (text !== undefined) node.textContent = text;
  if (className) node.className = className;
  return node;
}

function svg(tag, attributes, text) {
  const node = document.createElementNS("http://www.w3.org/2000/svg", tag);
  for (const [name, value] of Object.entries(attributes)) node.setAttribute(name, value);
  if (text !== undefined) node.textContent = text;
  return node;
}

function table(target, labels, rows, caption) {
  target.classList.add("dashboard-table-wrap");
  target.tabIndex = 0;
  target.setAttribute("role", "region");
  target.setAttribute("aria-label", caption);
  const grid = html("table", undefined, "dashboard-table");
  grid.setAttribute("aria-label", caption);
  const head = grid.createTHead().insertRow();
  for (const label of labels) {
    const cell = html("th", label, label === "Team" ? "" : "dashboard-number");
    cell.scope = "col";
    head.append(cell);
  }
  const body = grid.createTBody();
  for (const row of rows) {
    const tr = body.insertRow();
    for (const entry of row) {
      tr.append(html("td", entry, typeof entry === "number" ? "dashboard-number" : ""));
    }
  }
  target.replaceChildren(grid);
}

// Multi-series line chart with a legend, used for the player season trends.
function seriesChart(target, weeks, series, {label, ticks}) {
  const width = 640;
  const height = 230;
  const left = 40;
  const bottom = 195;
  const top = 16;
  const last = Math.max(1, weeks.length - 1);
  const min = ticks[0];
  const max = ticks.at(-1);
  const x = (index) => left + (width - left - 22) * index / last;
  const y = (value) => bottom - (value - min) / (max - min) * (bottom - top);
  const plot = svg("svg", {viewBox: "0 0 640 230", class: "dashboard-chart", role: "img", "aria-label": label});
  plot.append(svg("title", {}, label));
  for (const tick of ticks) {
    plot.append(svg("line", {x1: left, x2: width - 22, y1: y(tick), y2: y(tick), stroke: "#d6d1c5"}));
    plot.append(svg("text", {x: left - 8, y: y(tick) + 4, "text-anchor": "end"}, tick));
  }
  for (const [index, week] of weeks.entries()) {
    if (index % Math.ceil(weeks.length / 5) !== 0 && index !== weeks.length - 1) continue;
    plot.append(svg("text", {x: x(index), y: height - 10, "text-anchor": "middle"},
      dateLabel.format(new Date(week.ending))));
  }
  const legend = html("div", undefined, "dashboard-key");
  for (const {name, color, values} of series) {
    let previous = null;
    for (const [index, value] of values.entries()) {
      if (value == null) {
        previous = null;
        continue;
      }
      const point = [x(index), y(value)];
      if (previous) plot.append(svg("line", {x1: previous[0], y1: previous[1], x2: point[0], y2: point[1],
        stroke: color, "stroke-width": 1.7}));
      const dot = svg("circle", {cx: point[0], cy: point[1], r: 2.7, fill: color});
      dot.append(svg("title", {}, name + " · " + dateLabel.format(new Date(weeks[index].ending)) + " · " + value));
      plot.append(dot);
      previous = point;
    }
    const entry = html("span");
    const swatch = html("span", undefined, "dashboard-swatch");
    swatch.style.backgroundColor = color;
    entry.append(swatch, name);
    legend.append(entry);
  }
  target.replaceChildren(plot, legend);
}

// Full-width rank chart: one line per team, team names down the right edge in
// current rank order. Clicking a name or a line highlights that team.
function rankChart(target, weeks, series, teamCount, {highlighted, onSelect}) {
  const width = 960;
  const height = 460;
  const left = 36;
  const right = width - 200;
  const top = 18;
  const bottom = height - 34;
  const last = Math.max(1, weeks.length - 1);
  const x = (index) => left + (right - left) * index / last;
  const y = (rank) => top + (rank - 1) / Math.max(1, teamCount - 1) * (bottom - top);
  const plot = svg("svg", {viewBox: `0 0 ${width} ${height}`, class: "dashboard-chart dashboard-rank-chart",
    role: "img", "aria-label": "Team standings rank by week"});
  plot.append(svg("title", {}, "Team standings rank by week"));
  for (let rank = 1; rank <= teamCount; rank++) {
    plot.append(svg("line", {x1: left, x2: right, y1: y(rank), y2: y(rank), stroke: "#e3dfd4"}));
    if (rank === 1 || rank === teamCount || rank % 5 === 0) {
      plot.append(svg("text", {x: left - 8, y: y(rank) + 4, "text-anchor": "end"}, rank));
    }
  }
  for (const [index, week] of weeks.entries()) {
    plot.append(svg("line", {x1: x(index), x2: x(index), y1: top, y2: bottom, stroke: "#eeeae1"}));
    if (index % Math.ceil(weeks.length / 8) !== 0 && index !== weeks.length - 1) continue;
    plot.append(svg("text", {x: x(index), y: height - 10, "text-anchor": "middle"},
      dateLabel.format(new Date(week.ending))));
  }
  const ordered = [...series].sort((a, b) => Number(a.id === highlighted) - Number(b.id === highlighted));
  for (const {id, name, color, values} of ordered) {
    const dimmed = highlighted && highlighted !== id;
    const opacity = dimmed ? .14 : 1;
    const group = svg("g", {class: "dashboard-rank-line", opacity});
    group.addEventListener("click", () => onSelect(id));
    let previous = null;
    for (const [index, value] of values.entries()) {
      if (value == null) {
        previous = null;
        continue;
      }
      const point = [x(index), y(value)];
      if (previous) group.append(svg("line", {x1: previous[0], y1: previous[1], x2: point[0], y2: point[1],
        stroke: color, "stroke-width": id === highlighted ? 3.2 : 1.8}));
      const dot = svg("circle", {cx: point[0], cy: point[1], r: id === highlighted ? 4 : 3, fill: color});
      dot.append(svg("title", {}, name + " · " + dateLabel.format(new Date(weeks[index].ending)) + " · rank " + value));
      group.append(dot);
      previous = point;
    }
    plot.append(group);
    const current = values.at(-1);
    if (current == null) continue;
    const label = svg("text", {x: right + 12, y: y(current) + 4, fill: color, class: "dashboard-rank-label",
      "font-weight": id === highlighted ? 700 : 500, opacity: dimmed ? .35 : 1, role: "button", tabindex: 0,
      "aria-pressed": String(id === highlighted)}, name);
    label.addEventListener("click", () => onSelect(id));
    label.addEventListener("keydown", (event) => {
      if (event.key === "Enter" || event.key === " ") {
        event.preventDefault();
        onSelect(id);
      }
    });
    plot.append(label);
  }
  target.replaceChildren(plot);
}

// Offence against defence, one labelled dot per team.
function ratingsMap(target, rows) {
  const width = 520;
  const height = 440;
  const left = 44;
  const right = width - 16;
  const top = 16;
  const bottom = height - 40;
  const offs = rows.map((row) => row.offense);
  const defs = rows.map((row) => row.defense);
  const pad = 2;
  const minO = Math.floor((Math.min(...offs) - pad) / 5) * 5;
  const maxO = Math.ceil((Math.max(...offs) + pad) / 5) * 5;
  const minD = Math.floor((Math.min(...defs) - pad) / 5) * 5;
  const maxD = Math.ceil((Math.max(...defs) + pad) / 5) * 5;
  const x = (value) => left + (value - minO) / (maxO - minO) * (right - left);
  const y = (value) => top + (value - minD) / (maxD - minD) * (bottom - top); // lower defence rating is higher up
  const plot = svg("svg", {viewBox: `0 0 ${width} ${height}`, class: "dashboard-chart", role: "img",
    "aria-label": "Offensive rating against defensive rating by team"});
  plot.append(svg("title", {}, "Offensive rating against defensive rating by team"));
  for (let tick = minO; tick <= maxO; tick += 5) {
    plot.append(svg("line", {x1: x(tick), x2: x(tick), y1: top, y2: bottom, stroke: "#e3dfd4"}));
    plot.append(svg("text", {x: x(tick), y: bottom + 16, "text-anchor": "middle"}, tick));
  }
  for (let tick = minD; tick <= maxD; tick += 5) {
    plot.append(svg("line", {x1: left, x2: right, y1: y(tick), y2: y(tick), stroke: "#e3dfd4"}));
    plot.append(svg("text", {x: left - 6, y: y(tick) + 4, "text-anchor": "end"}, tick));
  }
  const meanO = offs.reduce((sum, value) => sum + value, 0) / offs.length;
  const meanD = defs.reduce((sum, value) => sum + value, 0) / defs.length;
  plot.append(svg("line", {x1: x(meanO), x2: x(meanO), y1: top, y2: bottom, stroke: "#a9a397", "stroke-dasharray": "4 4"}));
  plot.append(svg("line", {x1: left, x2: right, y1: y(meanD), y2: y(meanD), stroke: "#a9a397", "stroke-dasharray": "4 4"}));
  plot.append(svg("text", {x: (left + right) / 2, y: height - 4, "text-anchor": "middle", class: "dashboard-axis"}, "Offensive rating (points scored per 100 possessions)"));
  plot.append(svg("text", {x: 12, y: (top + bottom) / 2, "text-anchor": "middle", class: "dashboard-axis",
    transform: `rotate(-90 12 ${(top + bottom) / 2})`}, "Defensive rating (points allowed per 100, better upward)"));
  for (const row of rows) {
    const dot = svg("circle", {cx: x(row.offense), cy: y(row.defense), r: 5, fill: row.color, opacity: .85});
    dot.append(svg("title", {}, row.name + " · Off " + row.offense + " · Def " + row.defense + " · Net " + row.net));
    plot.append(dot);
    plot.append(svg("text", {x: x(row.offense) + 7, y: y(row.defense) + 4, fill: row.color}, row.short));
  }
  target.replaceChildren(plot);
}

function leaders(week, stat) {
  return Object.entries(week.players)
    .filter(([, total]) => total[stat] > 0)
    .sort(([idA, a], [idB, b]) => b[stat] - a[stat] || a.games - b.games || idA.localeCompare(idB))
    .slice(0, 3);
}

function loadDashboard(data) {
  const {weeks, teams, players} = data;
  if (!weeks.length) throw new Error("No completed weeks");
  // Newest week first in the menu; option values stay the index into weeks.
  for (let index = weeks.length - 1; index >= 0; index--) {
    weekSelect.add(new Option(dateLabel.format(new Date(weeks[index].ending)), index));
  }
  weekSelect.value = weeks.length - 1;
  const teamIds = Object.keys(teams).sort((a, b) => teams[a].localeCompare(teams[b]));
  const color = Object.fromEntries(teamIds.map((id, index) => [id, palette[index % palette.length]]));
  const short = (id) => shortNames[id] || teams[id];
  let highlighted = "";

  function renderRanks() {
    const upto = Number(weekSelect.value) + 1;
    const shown = weeks.slice(0, upto);
    const series = teamIds.map((id) => ({id, name: short(id), color: color[id],
      values: shown.map((week) => week.standings.find((row) => row.team === id)?.rank)}));
    rankChart(find("bbl-standings-trend"), shown, series, teamIds.length, {
      highlighted,
      onSelect(id) {
        highlighted = highlighted === id ? "" : id;
        renderRanks();
      },
    });
  }

  const cards = stats.map(([stat, label]) => {
    const card = html("article", undefined, "dashboard-stat");
    const list = html("ol");
    const empty = html("p", "No recorded leaders this week.", "dashboard-empty");
    const details = html("details");
    const chart = html("div");
    details.append(html("summary", "↗ Season trend"), chart);
    details.addEventListener("toggle", () => {
      if (!details.open || chart.childNodes.length) return;
      const ids = [...new Set(weeks.flatMap((week) => leaders(week, stat).map(([id]) => id)))];
      const series = ids.map((id, index) => ({id, name: players[id], color: palette[index % palette.length],
        values: weeks.map((week) => week.players[id]?.[stat])}));
      const maximum = Math.max(1, ...series.flatMap((line) => line.values.filter((value) => value != null)));
      const step = Math.max(1, Math.ceil(maximum / 4));
      seriesChart(chart, weeks, series, {label: label + " totals for players who ranked in a weekly top three",
        ticks: [0, step, 2 * step, 3 * step, 4 * step]});
    });
    card.append(html("h5", label), list, empty, details);
    find("bbl-player-leaders").append(card);
    return {stat, list, empty};
  });

  function renderRatings() {
    const week = weeks[Number(weekSelect.value)];
    const rows = Object.entries(week.seasonRatings)
      .sort(([, a], [, b]) => b.net - a.net)
      .map(([id, rating]) => ({id, name: teams[id], short: short(id), color: color[id], ...rating,
        weekNet: week.weeklyRatings[id]?.net}));
    const target = find("bbl-ratings");
    if (!rows.length) {
      target.replaceChildren(html("p", "No league games yet.", "dashboard-empty"));
      find("bbl-ratings-map").replaceChildren();
      return;
    }
    table(target, ["#", "Team", "GP", "Off", "Def", "Net", "Week net"],
      rows.map((row, index) => [index + 1, row.name, row.games, row.offense, row.defense, row.net,
        row.weekNet == null ? "—" : row.weekNet]),
      "Team ratings, season to date");
    ratingsMap(find("bbl-ratings-map"), rows);
  }

  function renderWeek() {
    const week = weeks[Number(weekSelect.value)];
    table(find("bbl-standings"), ["Rank", "Team", "GP", "W", "L", "+/−"],
      week.standings.map((row) => [row.rank, teams[row.team], row.games, row.wins, row.losses, row.point_difference]),
      "League standings through the selected week");
    for (const {stat, list, empty} of cards) {
      const items = leaders(week, stat).map(([id, row]) =>
        html("li", players[id] + " · " + row[stat] + " (" + row.games + (row.games === 1 ? " game)" : " games)")));
      list.replaceChildren(...items);
      empty.hidden = items.length > 0;
    }
    renderRanks();
    renderRatings();
  }
  weekSelect.addEventListener("change", renderWeek);
  renderWeek();
  weekSelect.disabled = false;
  find("bbl-dashboard").hidden = false;
  find("bbl-dashboard-status").textContent = data.season + " regular season · " + data.gameCount + " games across completed weeks";
}

fetch(new URL("./dashboard-data.json", import.meta.url))
  .then((response) => {
    if (!response.ok) throw new Error("Dashboard data unavailable");
    return response.json();
  })
  .then(loadDashboard)
  .catch(() => { find("bbl-dashboard-status").textContent = "Dashboard data is currently unavailable."; });
