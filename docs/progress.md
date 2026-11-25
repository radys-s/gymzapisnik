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

## 2026-11-18 — UX pass: fewer taps between sets

- What: audited the main journeys in the release web build at 360 px and desktop width (`docs/ux-audit-2026-11.md`), then shipped the top 5 by impact over effort in four PRs (#9–#12): confirm a set from the set sheet ("Potvrdit sérii", keyboard Done confirms too), a check on an empty set opens the sheet with the reason instead of a toast, an edit button on the summary right after finishing and in history, rest-bar buttons at full 44 px on a 360 px phone, and a history button in the Pokrok app bar. Version 1.0.0-beta.14+23.
- Why: the goal is logging between sets one-handed with sweaty hands. The biggest losses were extra trips to the row's check after editing a set, an error toast with no way forward on new exercises, no way to fix a typo right after finishing, and buttons shrunk below 44 px on narrow phones.
- Numbers (taps): adjusted set 4 → 3; first set of a never-done exercise 4 → 2 (plus typing, no error); fix a set right after finishing 6 + scroll → 1; open history 2 + scroll → 2; rest buttons 36 px → 44 px tall at 360 px. Prefilled set stays at 1 tap. 10 new widget tests (and one updated); all but the guard that a done set keeps "Hotovo" failed before their change.
- What worked: a release web build plus the browser preview with Flutter semantics enabled gave real tap targets in px; a local copy of `tool/screens_test.dart` rendered before/after PNGs in seconds without a browser. Loading Roboto in a widget test made size assertions match the phone (the default test font is far wider). The independent review caught real issues: a retried confirm could un-confirm a set, an unreadable number could be confirmed with old values, the keyboard's Done skipped confirmation, and the summary's coach verdict stayed stale after an edit.
- Next: the plan screen's "Složím si vlastní" sits where the previous step's primary button was (double-tap risk); check on an iPhone whether the set sheet should stop opening the keyboard by itself; workout title tap target is 37 px; let a past workout's date change and a forgotten exercise be added; Esc to close pages on desktop web.

## 2026-11-22 — Body measurements and a working screenshot tour

- What: added circumference tracking (waist, chest, arm, forearm, thigh, calf, hips, neck) on the existing Váha a míry page: add, history, delete with undo, 30-day change per part, persistence, backup export/import and wipe. Renamed the Progress row to match; the test expectation was updated with it.
- Why: competitor research (`docs/research/competitors-2026-11.md`) lists body measurements as a standard free feature in Strong, Alpha Progression and Hevy; weight alone misses recomposition.
- Bug found during verification: the screenshot tour's `pageBack()` looks for the English "Back" tooltip, but this Czech app uses "Zpět", so the tour failed on the exercise detail page even though its back arrow is present. Replaced with a localized `_back` helper. The tour now also captures the weight and measurements screens.
- Numbers: 7 domain/state/UI tests added or updated, 33 focused tests pass, tour renders 29 screens in 12 s; format, `git diff --check` and targeted analyze are clean.
- Next: finish the remaining top-20 research items in priority order and review the rendered screens with Tomáš.

## 2026-11-22 — Deep redesign pass, audit fixes, and mobile review artifact

- What: English-first exercise catalog (211 entries) with Czech names/aliases/pattern metadata; improved exercise search/filtering (EN/CZ/alias/muscle/equipment) and gym-only filter in library and workout picker; richer exercise detail with Czech name, clearer demo framing/replay/phase cue, science-based technique tips, alternatives, and next PR target.
- Onboarding: added language selection (cs/en/sk, exercise names remain English), beginner vs 6+ months fork, and "I have my own plan" flow that collects schedule/gym preferences, saves a recommended fallback, then opens Program Editor prefilled with the selected day count.
- Dopamine/UI: added Progress rank card and "Další PR cíle" card, made Home food block more prominent with calorie/protein progress and quick add, refreshed bottom nav with animated bar, updated gym presets (Suncity/Okragon/Extrifit/Form Factory/generic big gym).
- Audit fixes: used suggested nutrition targets per field when only one custom target is set, restored counted-set guard in exercise history counts, guarded null bestToday in exercise comparison, skipped unknown recent exercises in picker, and added app-language setting in Settings.
- Verification: `flutter analyze` clean on changed Dart files; focused tests passed (`progress_page_test`, `set_sheet_test`, `catalog_test`, `summary_test`, `measurement_test`, `bodyweight_test`, `backup_test`, `app_state_test`, `state_slices_test`); `flutter build web --release` succeeded; review artifact refreshed at `docs/screenshots/review-2026-11-22/`.
- Next: collect user feedback from mobile emulator, polish demo quality beyond figurine animation, and continue i18n/dopamine tuning based on review.

## 2026-11-22 — Weekly report, current-set marker and visual cleanup

- What: new Týdenní report (Progress → "Týdenní report" or the "Report" action on the week card): weekly volume with per-day bars, workouts/time/sets/reps with % against last week, the week's records (one row per exercise, best value only), exercise of the week, and sets per muscle; arrows browse back to the first training week. Home shows a "Minulý týden" recap on Monday and Tuesday that opens last week's report. In the workout, the next set to log gets an ember stripe and tint.
- Cleanup: tab bar labels fell back to the system font (AnimatedDefaultTextStyle replaced the theme style) and now use Inter; the rest bar is one row again after the overflow fix had wrapped its buttons to a second line (skip becomes an icon under 300 px); the Home food block lost its off-brand blue/orange boxes and three-line subtitle; rank names and the demo cue are Czech (Nováček…Elita, no "Lv."), rank uses ember with gold only at the top.
- Why: competitor research item 19 (Boostcamp-style weekly report) was the last missing top-20 feature; the rest were visible inconsistencies Tomáš called slop.
- Numbers: 11 new tests (9 domain, 2 widget); focused workout, home and progress suites pass (61 + 13 tests); screenshot tour renders the report.
- Next: Tomáš's hands-on feedback from the new IPA.

## 2026-11-23 — Onboarding rebuilt around plan styles, Czech + English, new figure

- What: onboarding starts with a one-tap language choice (Czech or English, Slovak dropped, nothing preselected), then "Jak chceš trénovat?": a highlighted own-plan card or one of three styles (science-based, old school, strength). Questions show no answer until tapped; the schedule asks for days and session length. Six new style plans; science-based exercises carry a short "why this exercise" note with its study (Maeo 2021/2023, Pedrosa 2022, Kubo 2019, Kassiano 2023, Wolf 2023; plan principles from Schoenfeld 2016/2017 and Robinson 2024). The own-plan editor starts from any template with one tap, names are optional, empty days show one big add button.
- Languages: `tr(cs, en)` pairs (lib/core/i18n.dart); the app rebuilds when the language changes. Translated in batches by a worker model and reviewed.
- Exercises: 33 English names made consistent, 17 duplicates hidden from lists (ids kept for history), 45 exercises got a matching movement. The figure got volume, working muscles in the accent (helpers half-tone, equipment neutral), a faint start pose, three slow reps with phase labels and start/end frames.
- Declined: copying scraped photos from free-exercise-db/wrkout (their maintainer says he does not own the image copyright); used only as pose reference.
- Next: English for the remaining screens and technique texts, 54 new exercises, review, IPA.

## 2026-11-24 — Phone preview of the whole redesign

- What: built the release web app with CanvasKit bundled (`--no-web-resources-cdn`, relative `<base href="./">`) and published it inside a phone frame as a private claude.ai artifact (https://claude.ai/artifact/21ui45gtzW9tYi7c6u3R6u) with a "what changed / try this" column. Fixed the last 8 analyzer infos (curly braces in `splits.dart` and `workout_page.dart`).
- Why: Tomáš asked for a page with a phone emulator to try the app and dictate feedback after the long redesign run.
- Numbers: bundle 22 MB in 40 files after dropping skwasm/wimp renderers and debug symbols; build 60 s. Served locally from a sub-path, the build boots to the language picker in headless Chromium.
- Not verified: storage and the AI proxy inside the claude.ai frame itself (no browser access to claude.ai from the hub).
- Next: Tomáš's feedback on the preview.

## 2026-11-24 — Exercise illustration polish completed after handoff

- What: finished the pending figure rendering pass: fuller body shapes, highlighted working/helper muscles, rep-dependent effort, movement paths, floor shadows, and a live four-phase tempo strip. Side-view chest orientation follows the hands. Contact-sheet options support exercise subsets and larger cells.
- Visual correction: the short squeeze phase clipped its label on a 390 px phone; labels now receive equal width while timeline segments retain their duration proportions.
- Verification: targeted analyzer clean; figure/catalog and exercise-screen tests pass (5 tests); workout screenshot tour passes and renders 8 screens. Inspected the full catalog contact sheet and exercise detail screenshot. Independent read-only review approved the rendering changes before the label correction.
- Delivery: source committed on the redesign branch. The previously published phone preview predates this final illustration polish; its hosted bundle has not been updated in this pass.
- Next: hands-on feedback on the existing phone preview, then refresh the hosted bundle with any requested revisions.

## 2026-11-24 — Remove the pain question

- Removed the pain-selection screen from onboarding and plan setup following user feedback. Gym selection now leads directly to the generated plan in onboarding; later plan setup continues with the optional body and focus steps.
- Removed unused question helpers, adjusted the progress count, and updated the flow tests and screenshot tour. Existing saved exercise exclusions remain supported.
- Verification: targeted analyzer clean; first-run screenshot tour reaches the plan without the removed step.

## 2026-11-24 — Follow-up audit: preserve profile and numeric input

- Fixed Later in plan setup deleting saved sex, height, birth year and weight goal. It now discards only edits in that step and restores saved body details, including the weight field.
- Fixed set input silently stripping minus signs (pasted -5 became 5) and decimal separators from reps (8.5 became 85). Keep these characters visible, reject invalid/negative values before persistence, and prevent steppers from replacing negative input. Existing draft values remain intact until input is corrected.
- Translated the body-step validation toast for English users.
- Evidence: added regression assertions failed before both fixes; body/profile flow and consent suites pass (15 tests), set editor passes (9). Baseline checks of active workout, backups, history and English onboarding also passed (37 including the set suite). Targeted analyzer clean.
- Independent read-only audits: schedule-loss claim is blocked by the required schedule selection before save; draft-body claim does not apply because the body step is only offered in setup, which intentionally initializes from saved planAnswers rather than planDraft. Neither warranted changing persistence.
- Next: continue the audit with nutrition and program editing; refresh the hosted preview after the source fixes are collected. This pass does not establish that the entire app is bug-free.

## 2026-11-24 — Competitor-informed workout motion and input robustness

- Research: used REA to navigate and inspect Hevy's feature page and Strong's public site. Recorded exact Evidence IDs, observations and limits in `docs/research/motion-rea-2026-11-24.md`; no claim of inspecting signed-in mobile app behavior.
- Motion: slide/fade workout volume and completed-set values, animate exercise-card size and rest-bar entrance/exit, transition countdown values and completion icon, animate nutrition's remaining-goal feedback. Screen readers receive only the latest animated label. Reduced-motion settings show final states immediately.
- Robustness: delayed reveals now cancel when reduced motion is enabled during a run; tab and selection animations settle too. Ambient clock subscribers stop in the background and resume in the foreground. Added deterministic regression tests for these cases.
- Data: the completed-workout editor independently stripped minus signs and decimal separators, turning pasted fractional reps into different whole values. It now keeps invalid input visible, shows inline errors, preserves the last valid draft values, blocks saving, and recovers when corrected. Deleting an invalid set or exercise clears its validation state.
- Review tooling: the workout screenshot tour now awaits set persistence and confirms the next remaining set, avoiding captures with stale totals or a skipped row.
- Verification: 58 focused tests pass (motion, history editing, rest controls, set entry, nutrition and workout logging); targeted analyzer clean. Before/after workout renders captured under `/tmp/gym-motion-before` and `/tmp/gym-motion-final`. No repo-wide build or test run on this hub. Source work stays on `t3/app-deep-redesign`; hosted preview refresh remains separate.

## 2026-11-25 — Pre-release audit fixes and bilingual polish

- What: fixed the last preselected onboarding control (reminder time now needs a deliberate tap), kept Czech exercise names out of English lists, translated the keyboard "Done" bar and the Progress report action, and put bottom-nav transitions behind the shared reduced-motion-aware `Motion` helper. Updated the onboarding e2e scripts to the current language → value → consent → path flow, refreshed the stale product/design docs, and bumped the version to `1.0.0-beta.15+24`.
- Why: a read-only audit of the redesign branch found these remaining gaps before the sideload build. A first fresh IPA from `23213fc` succeeded (run `45588478774`), but the branch had further fixes to land.
- Numbers: two new regression tests (reminder stays unset until a time is picked; My-gym switch toggles once); full `flutter analyze --no-pub` clean; full `flutter test --no-pub` passes 509 tests.
- Verification: focused consent and My-gym suites pass. The full test log still contains one pre-existing non-fatal hit-test warning in `first_workout_test.dart`; it does not fail the suite or CI.
- Next: rebuild the phone-review bundle from the new HEAD, dispatch the final sideload IPA, and check its artifact and version.

## 2026-11-25 — First impression: brand, welcome and interaction finish

- What: gave language selection and welcome a finite 900 ms brand entrance, with the existing icon framed by restrained calibration rings. Rebuilt the welcome hierarchy around a bilingual two-line headline, concise supporting copy and compact benefit rows. Home now carries the same small brand mark in its greeting.
- Motion: loading crossfades into the real app; primary actions, tappable panels and onboarding choices share a 2 px pointer lift and a visible keyboard-focus outline. These effects add no permanent animation loop and respect reduced motion. The hover wrapper adds no keyboard traversal stop and does not intercept taps.
- Reliability: language selection gives immediate selected feedback, blocks duplicate saves and disables its controls while saving. Choice cards now expose their own screen-reader tap action and disabled state instead of hiding the child's action with their combined label.
- Verification: new tests cover finite logo motion, changes to reduced motion while it plays, 320 × 568 layout with 1.5× text, pointer enter/exit and taps, keyboard activation, and choice accessibility. Focused onboarding, first-workout, set-entry, navigation, Home and design checks pass; targeted analyzer clean. The screen tour rendered 23 first-run and tab screens for visual inspection.
- Evidence: actual before/after Flutter screenshots and an interactive comparison are in `docs/screenshots/first-impression-2026-11-25/`. Independent read-only review found one saving-state affordance issue; fixed it directly. Existing app-icon assets retain the same final mark, so installation and in-app branding stay consistent.
- Delivery: this follow-up starts from merged PR #14 in the same worktree, on `tomas/first-impression`. The hosted phone preview and IPA have not been rebuilt in this pass.

## 2026-11-25 — Home with a restrained technical character

- What: gave Home a very faint ASCII backdrop, technical date/history metadata, a framed workout module, numbered exercise rows, a stronger condensed workout title and rounded-square week markers. Corrected row spacing so long exercise names stay separated from their targets.
- Motion: cached decorative glyphs drift only a few pixels; a brief light sweep runs along the workout module edge, with a long rest between passes. Both layers draw at 8 fps from the existing shared ambient clock. Repaint boundaries separate the decorative paint from data-heavy content; the texture is excluded from input and semantics.
- Lifecycle: hidden tabs now disable their ticker scope, so Home's ambient listeners detach when navigating away. Existing background-app and reduced-motion handling also apply. Added tests for click-through, hidden-tab pause/resume of both decorative layers, and reduced motion.
- Typography: bundled IBM Plex Mono Regular (135,580 bytes) and its SIL OFL license from https://github.com/google/fonts/tree/main/ofl/ibmplexmono. Generic monospace fallbacks produced missing glyphs in review renders; the bundled font is registered in the screenshot tour too.
- Verification: 24 focused tests pass (Home, navigation, motion and narrow/large-text mobile layouts), plus the strengthened ambient-layer checks. Changed-file analyzer clean. Independent read-only review approved. Actual Flutter renders are saved in `docs/screenshots/home-technical-2026-11-25/`; stills show the resting appearance rather than the full motion.
- Delivery: continues on `tomas/first-impression` in the existing worktree. The installed beta and hosted phone preview require a new build to show this source update.
