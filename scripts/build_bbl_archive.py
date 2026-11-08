"""Build the BBL index from edition metadata before invoking Quarto."""
from __future__ import annotations

import calendar
from collections import defaultdict
from datetime import date, timedelta
from html import escape
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]


def month_week(day: date) -> tuple[date, date]:
    """Monday-Sunday weeks, clipped to the first and last day of the month."""
    start = max(day.replace(day=1), day - timedelta(days=day.weekday()))
    end = min(day.replace(day=calendar.monthrange(day.year, day.month)[1]),
              day + timedelta(days=6 - day.weekday()))
    return start, end


def read_editions(directory: Path) -> list[tuple[date, str]]:
    editions = []
    for path in directory.glob('*.qmd'):
        day = date.fromisoformat(path.stem)
        text = path.read_text(encoding='utf-8')
        title = re.search(r'^title:\s*(.+)$', text, re.MULTILINE)
        if not title:
            raise ValueError(f'{path}: missing title')
        editions.append((day, title.group(1).strip().strip('\"\'')))
    return sorted(editions, reverse=True)


def date_label(day: date) -> str:
    return f'{day:%b} {day.day}, {day.year}'


def build_archive(editions: list[tuple[date, str]]) -> str:
    if not editions:
        return 'No editions yet.\n'
    latest = editions[0][0]
    cutoff = latest - timedelta(days=6)
    months = defaultdict(set)
    rows = []
    for day, title in editions:
        start, end = month_week(day)
        months[day.strftime('%Y-%m')].add((start, end))
        hidden = ' hidden' if day < cutoff else ''
        rows.append(f'<tr data-week="{start}"{hidden}><td><time datetime="{day}">{date_label(day)}</time></td>'
                    f'<td><a href="posts/{day}.html">{escape(title)}</a></td></tr>')
    navigation = []
    for month, weeks in sorted(months.items(), reverse=True):
        month_day = date.fromisoformat(month + '-01')
        links = []
        for start, end in sorted(weeks, reverse=True):
            label = f'{start:%B} {start.day}' + (f'–{end.day}' if end != start else '')
            links.append(f'<li><a href="?week={start}" data-archive-week="{start}" '
                         f'data-label="{escape(label)}">{label}</a></li>')
        opened = ' open' if month == latest.strftime('%Y-%m') else ''
        navigation.append(f'<details class="bbl-month"{opened}><summary>{month_day:%B %Y}</summary>'
                          f'<ul>{"".join(links)}</ul></details>')
    fallback = ''.join(f'<li><a href="posts/{day}.html">{escape(title)}</a></li>' for day, title in editions)
    return f'''```{{=html}}
<div class="bbl-layout">
  <section class="bbl-editions" aria-labelledby="bbl-period" id="bbl-editions">
    <div aria-live="polite" aria-atomic="true">
      <h2 id="bbl-period">Latest seven days</h2>
      <p id="bbl-period-dates" class="bbl-period-dates">{date_label(cutoff)} – {date_label(latest)}</p>
    </div>
    <table class="table bbl-table" aria-label="BBL Daily editions for the selected period">
      <thead><tr><th scope="col">Date</th><th scope="col">Title</th></tr></thead>
      <tbody>{''.join(rows)}</tbody>
    </table>
  </section>
  <div class="bbl-archive" role="complementary" aria-label="Edition archive">
    <details class="bbl-archive-panel" open>
      <summary>Browse the archive</summary>
      <nav aria-label="Months and weeks">
        <a class="bbl-latest" href="?" aria-current="page">Latest seven days</a>
        {''.join(navigation)}
      </nav>
    </details>
  </div>
</div>
<noscript><h2>All editions</h2><p>Choose an edition directly from the archive.</p><ul>{fallback}</ul></noscript>
```
'''


if __name__ == '__main__':
    output = ROOT / 'bbl' / '_archive.qmd'
    output.write_text(build_archive(read_editions(ROOT / 'bbl' / 'posts')), encoding='utf-8')
    print(f'Built {output.relative_to(ROOT)}')
