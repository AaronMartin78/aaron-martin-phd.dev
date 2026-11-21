const dashboard = document.querySelector("#bbl-dashboard");
const find = (id) => dashboard.querySelector("#" + id);
const weekSelect = find("bbl-dashboard-week");
const ratingsPeriod = find("bbl-ratings-period");
const teamSelect = find("bbl-chart-team");
const dateLabel = new Intl.DateTimeFormat("en-GB", {day: "numeric", month: "short", timeZone: "UTC"});
const stats = [
  ["points", "Points"], ["total_rebounds", "Rebounds"], ["assists", "Assists"],
  ["steals", "Steals"], ["blocks", "Blocks"],
];
const palette = ["#245681", "#a03b38", "#28774b", "#783a90", "#91521b", "#267581",
  "#93690f", "#aa3669", "#4d597d", "#596623", "#563568", "#18776d", "#965139",
  "#2a6aa3", "#8a2f53", "#475947", "#7d6138", "#6e4b5c"];

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

function seriesChart(target, weeks, series, {label, ticks, reversed = false, highlighted = ""}) {
  const width = 640;
  const height = 230;
  const left = 40;
  const bottom = 195;
  const top = 16;
  const last = Math.max(1, weeks.length - 1);
  const min = ticks[0];
  const max = ticks.at(-1);
  const x = (index) => left + (width - left - 22) * index / last;
  const y = (value) => {
    const fraction = (value - min) / (max - min);
    return reversed ? top + fraction * (bottom - top) : bottom - fraction * (bottom - top);
  };
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
  const ordered = [...series].sort((a, b) => Number(a.id === highlighted) - Number(b.id === highlighted));
  for (const {id, name, color, values} of ordered) {
    const opacity = highlighted && highlighted !== id ? .17 : 1;
    let previous = null;
    for (const [index, value] of values.entries()) {
      if (value == null) {
        previous = null;
        continue;
      }
      const point = [x(index), y(value)];
      if (previous) plot.append(svg("line", {x1: previous[0], y1: previous[1], x2: point[0], y2: point[1],
        stroke: color, "stroke-width": id === highlighted ? 3 : 1.7, opacity}));
      const dot = svg("circle", {cx: point[0], cy: point[1], r: 2.7, fill: color, opacity});
      dot.append(svg("title", {}, name + " · " + dateLabel.format(new Date(weeks[index].ending)) + " · " + value));
      plot.append(dot);
      previous = point;
    }
    if (!highlighted || highlighted === id) {
      const entry = html("span");
      const swatch = html("span", undefined, "dashboard-swatch");
      swatch.style.backgroundColor = color;
      entry.append(swatch, name);
      legend.append(entry);
    }
  }
  target.replaceChildren(plot, legend);
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
  weeks.forEach((week, index) => weekSelect.add(new Option(dateLabel.format(new Date(week.ending)), index)));
  weekSelect.value = weeks.length - 1;
  teamSelect.add(new Option("All teams", ""));
  const teamIds = Object.keys(teams).sort((a, b) => teams[a].localeCompare(teams[b]));
  teamIds.forEach((id) => teamSelect.add(new Option(teams[id], id)));
  const ranks = teamIds.map((id, index) => ({id, name: teams[id], color: palette[index % palette.length],
    values: weeks.map((week) => week.standings.find((row) => row.team === id)?.rank)}));
  function renderRanks() {
    seriesChart(find("bbl-standings-trend"), weeks, ranks,
      {label: "Team standings rank by week", ticks: [1, 5, 9, 13, 18], reversed: true, highlighted: teamSelect.value});
  }
  teamSelect.addEventListener("change", renderRanks);
  renderRanks();

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
    const rows = Object.entries(week[ratingsPeriod.value])
      .sort(([, a], [, b]) => b.net - a.net)
      .map(([id, rating], index) => [index + 1, teams[id], rating.games, rating.possessions, rating.offense, rating.defense, rating.net]);
    const target = find("bbl-ratings");
    if (rows.length) table(target, ["#", "Team", "GP", "Est. poss.", "Off", "Def", "Net"], rows, "Team ratings");
    else target.replaceChildren(html("p", "No league games this week.", "dashboard-empty"));
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
    renderRatings();
  }
  weekSelect.addEventListener("change", renderWeek);
  ratingsPeriod.addEventListener("change", renderRatings);
  renderWeek();
  weekSelect.disabled = false;
  find("bbl-dashboard-content").hidden = false;
  find("bbl-dashboard-status").textContent = data.season + " regular season · " + data.gameCount + " games across completed weeks";
}

fetch(new URL("./dashboard-data.json", import.meta.url))
  .then((response) => {
    if (!response.ok) throw new Error("Dashboard data unavailable");
    return response.json();
  })
  .then(loadDashboard)
  .catch(() => { find("bbl-dashboard-status").textContent = "Dashboard data is currently unavailable."; });
