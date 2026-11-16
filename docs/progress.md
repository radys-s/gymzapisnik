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
- Updated the screenshot tour selector; inspection confirms the first Progress shots land on the correct empty state. Added a second visit after the sample workout to capture populated weekly analytics, and removed its last obsolete `Profil` fallback.
- Next: rerun the tour and inspect the populated Progress captures.

## 2026-11-15 — Color, motion, new logo and a shorter first run

- What: replaced the green-on-black look with an ink background and per-section color (training green, food orange, progress violet); cards got a lit corner and shadow; pages sit on a slowly drifting color background; the main action glows and catches a sheen about every 7 s; selected choices lift with a colored glow and pressed controls tilt.
- Logo: the icon was a fried egg while the app showed a barbell tile. One painter (`lib/ui/design/brand.dart`) now draws a progress ring opened into a "G" and closed by a dumbbell; `tool/brand_assets_test.dart` renders every iOS, Android and web icon and launch file from it.
- Home: greeting with the logo replaces the "Domů" title, the hero keeps "Jiný trénink" on its caption row, so workout, food and weekly goal fit one 390×844 screen.
- First run: terms and age moved right after the welcome, birth year removed, the body step and the "how do you want to start" step dropped; 5 questions instead of 7, and the finished plan is accepted or replaced by an own program on one screen. Consent is saved when given; a new `introPending` flag keeps the app on the intro until the plan step is done.
- Program editor: adding a day now starts with a visible choice between suggested exercises (pick muscle groups, drop what you do not want) and picking everything yourself.
- Why: Tomáš's feedback on beta.12: too green and flat, misaligned, first run too long, terms too late, birth year redundant with the 18+ answer, exercise suggestions not clearly separate from own choice.
- Ambient motion runs from one 25 fps clock that stops with its last listener; it is off with reduced motion, on covered pages and in widget tests.
- Tooling: Flutter 3.47.2 is now installed on the hub at `~/sdk/flutter-3.47.2` (busybox stands in for `unzip`), so format, analyze and focused tests run locally. `tool/screens_test.dart` renders 18 screens to PNG in about 10 s for visual checks.
- Numbers: 16 commits, about 2,400 lines added and 850 removed across 36 files. Version 1.0.0-beta.13+22.
- Next: collect tester feedback on the motion level; the workout screen itself still uses the old flat set rows.
