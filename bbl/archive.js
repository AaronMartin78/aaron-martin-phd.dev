<script>
document.addEventListener('DOMContentLoaded', () => {
  const layout = document.querySelector('.bbl-layout');
  if (!layout) return;
  const rows = [...layout.querySelectorAll('tbody tr')];
  const links = [...layout.querySelectorAll('[data-archive-week]')];
  const latestLink = layout.querySelector('.bbl-latest');
  const heading = layout.querySelector('#bbl-period');
  const dates = layout.querySelector('#bbl-period-dates');
  const originalDates = dates.textContent;
  const recentRows = new Set(rows.filter(row => !row.hidden));
  const panel = layout.querySelector('.bbl-archive-panel');
  const mobile = window.matchMedia('(max-width: 767px)');
  panel.open = !mobile.matches;
  mobile.addEventListener('change', event => { panel.open = !event.matches; });

  function showPeriod() {
    const week = new URL(window.location.href).searchParams.get('week');
    const selected = links.find(link => link.dataset.archiveWeek === week);
    for (const row of rows) {
      row.hidden = selected ? row.dataset.week !== week : !recentRows.has(row);
    }
    for (const link of [latestLink, ...links]) link.removeAttribute('aria-current');
    (selected || latestLink).setAttribute('aria-current', 'page');
    heading.textContent = selected ? selected.dataset.label : 'Latest seven days';
    dates.textContent = selected ? `Archive · ${week.slice(0, 4)}` : originalDates;
    if (selected) selected.closest('.bbl-month').open = true;
  }

  layout.querySelector('nav').addEventListener('click', event => {
    const link = event.target.closest('a');
    if (!link || event.button !== 0 || event.metaKey || event.ctrlKey || event.shiftKey || event.altKey) return;
    event.preventDefault();
    window.history.pushState(null, '', link.href);
    showPeriod();
    if (mobile.matches) {
      panel.open = false;
      heading.tabIndex = -1;
      heading.focus({ preventScroll: true });
      heading.scrollIntoView({ behavior: 'smooth', block: 'start' });
    }
  });
  window.addEventListener('popstate', showPeriod);
  showPeriod();
});
</script>
