"""Calendar-boundary and archive regression checks (stdlib only)."""
from datetime import date, timedelta
from html.parser import HTMLParser
import unittest

from build_bbl_archive import build_archive, month_week


class ArchiveTests(unittest.TestCase):
    def test_weeks_never_cross_calendar_months(self):
        day = date(2024, 1, 1)
        while day < date(2028, 1, 1):
            start, end = month_week(day)
            self.assertLessEqual(start, day)
            self.assertGreaterEqual(end, day)
            self.assertEqual((start.year, start.month), (day.year, day.month))
            self.assertEqual((end.year, end.month), (day.year, day.month))
            self.assertLessEqual((end - start).days, 6)
            day += timedelta(days=1)

    def test_november_boundary_and_leap_day(self):
        self.assertEqual(month_week(date(2026, 11, 1)), (date(2026, 11, 1), date(2026, 11, 1)))
        self.assertEqual(month_week(date(2026, 10, 31)), (date(2026, 10, 26), date(2026, 10, 31)))
        self.assertEqual(month_week(date(2024, 2, 29)), (date(2024, 2, 26), date(2024, 2, 29)))

    def test_recent_days_and_all_archive_links(self):
        editions = [(date(2026, 11, 8) - timedelta(days=n), 'Daily <news>') for n in range(20)]
        html = build_archive(editions)
        class Rows(HTMLParser):
            def __init__(self):
                super().__init__()
                self.rows = []
            def handle_starttag(self, tag, attrs):
                attrs = dict(attrs)
                if tag == 'tr' and 'data-week' in attrs:
                    self.rows.append(attrs)
        parser = Rows()
        parser.feed(html)
        self.assertEqual(len(parser.rows), 20)
        self.assertEqual(sum('hidden' not in row for row in parser.rows), 7)
        self.assertIn('Daily &lt;news&gt;', html)
        self.assertIn('October 26–31', html)
        self.assertIn('November 1</a>', html)
        for day, _ in editions:
            self.assertIn(f'posts/{day}.html', html)

    def test_empty_archive(self):
        self.assertEqual(build_archive([]), 'No editions yet.\n')


if __name__ == '__main__':
    unittest.main()
