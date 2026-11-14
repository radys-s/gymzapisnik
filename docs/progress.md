# Progress log

## 2026-11-14 — App interface redesign

- Replaced the harsh black and neon treatment with a softer green-black palette, rounded cards and controls, more readable headings, and restrained gradients.
- Centered narrow app content on wide screens, renamed the Profile destination to Progress, and moved weekly totals and muscle coverage off Home so its main workout action comes first.
- Removed duplicate nutrition totals when target rings already show them; updated the focused widget expectations for the new layout.
- Scope: 18 implementation and test files before this entry; roughly 370 additions and 518 deletions. `git diff --check` passes. Flutter and Dart are unavailable in this worktree, so widget tests and an in-app visual run could not be performed.
- Review: both requested GPT review rounds approved their submitted diffs. The separate provider critique could not run because its usage limit was reached.
- Next: run the focused Flutter widget tests and inspect the UI on a real app environment when the Flutter SDK is available.

## 2026-11-14 — Screenshot tour selector

- Updated the web screenshot tour to use the renamed Progress tab. The first visual run revealed its old `Profil` selector was capturing Strava while naming the screenshots `profile`.
- Removed an unused Home import caught by full CI after the moved records card no longer needed it.
- Updated mission widget tests that still expected the removed weekly progress ring on Home; the mission summary remains there, and the detailed ring is in Progress.
- Moved the remaining stale streak-chip assertion out of the Home mission test; streak analytics now belong to Progress.
- Kept the assertion comment on its own line to satisfy the repository Dart formatter.
- Next: rerun full CI and the remote screenshot tour; confirm Progress screenshots show the intended page.
