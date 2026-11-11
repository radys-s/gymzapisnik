# Gym zápisník: repair and improvement plan

Written 2026-11-11 on `tomas/tensor`. Replaces the two earlier plan files (beta.12 "alive & usable"
and the architecture audit). Status column is updated as work lands; history goes to `progress.md`.

Legend: **P0** blocks daily use, **P1** clearly felt by the user, **P2** quality and maintenance,
**P3** nice to have. Evidence: `code` = seen in the source, `user` = Tomáš or testers reported it,
`check` = suspected, must be measured before fixing.

## 1. What the app is for

- **Core loop:** open in the gym → see today's training → log a set with one tap → see progress.
  Offline, no account, Czech.
- **Where it can beat Hevy/Strong:** own routine with a smart audit ("biceps: short head missing"),
  "Moje posilovna" with machine photos, protein tracking that feeds the progression coach, Czech copy.
- **Not the product:** full calorie tracker, social feed, gamification. Fridge AI, badges, growth,
  recovery and the premium scaffolding dilute the core loop and go behind "Laboratoř".
- **Success test:** Tomáš trains one full workout on the iPhone build and names fewer than 3 bad moments.

## 2. Work order

| # | Step | Items | Status |
|---|---|---|---|
| 0 | Land uncommitted onboarding, Moje posilovna, routine audit | F1–F4 | done (e3af2a2) |
| 1 | CI on push | Q1 | done (e3de62e) |
| 2 | Scoped rebuilds + derived-data cache | A1, A2 | done (6a08ce8) |
| 3 | Split `AppState`, typed profile keys | A3, A4 | done (8f0df71, 85c8313): extensions in `lib/state/app_state/` |
| 4 | One plan-question flow, split giant files | A5, A6 | done (A5 `PlanSetupPage` b355844, A6 split 7470aa2) |
| 5 | Laboratoř, premium off, storage safety, error reporting | S1–S3, D1, D2 | D1 persist + storage line, S2 Pro hidden without paywall, S3 fridge moved below meals, error log (Diagnostika) done; S1 waits on Tomáš, D2 in step 6 |
| 6 | Logging feel, summary sequence, Home rebuild | U1–U9 | U1 drawn check, U2 quiet PRs, U3 staged summary, U4/U5 Home order + food block, F5 coverage card, D2 backup reminder done; U6–U9 todo |
| 7 | Release beta.12 (web + IPA) | R1–R4 | todo |
| later | Backlog below | everything else | — |

## 3. Architecture

| ID | Pri | Problem | Evidence | Fix |
|---|---|---|---|---|
| A1 | P0 | Every change rebuilds `MaterialApp` and all 4 tabs: `GymApp` listens to the whole `AppState`, each set tap and typed digit calls `notifyListeners()` | code: `lib/app.dart:29`, `app_state.dart` `saveActive` | `GymApp` listens only to consent validity. `AppState` gets channels `activeChanges`, `historyChanges`, `foodChanges`, `profileChanges`; pages listen to the narrowest one. Global notify stays as fallback |
| A2 | P0 | History statistics are recomputed inside `build` on every rebuild (`recentRecords`, `weekSummary`, `progressSeries`, `totalsOf`, `weeklyBuckets`, `exerciseHistory`) | code: `home_page.dart`, `stats_page.dart`, `progress_page.dart`, `dashboard.dart` | `lib/state/derived.dart`: memoize by identity of `workouts` (pattern already used by `recordsOf`) |
| A3 | P1 | `AppState` is one 1867-line class with ~120 members and 9 domains | code | Mixins on a small base: workout session, program, nutrition, AI, backup, reminders. Public API unchanged |
| A4 | P1 | Profile is an untyped bag: ~35 string keys in `extra[...]`, legacy keys handled inline | code | `profile_keys.dart` constants + typed accessors; round-trip test |
| A5 | P1 | Two UIs for the same plan answers: new onboarding questions and the old `PlanQuizPage` form (479 lines) | code: opened from Home, Training, Program | Extract the question steps, reuse them in a `PlanSetupPage`, delete the old form |
| A6 | P2 | Giant UI files: `workout_page.dart` 1521, `components.dart` 1197, `onboarding_page.dart` 1074 | code | Split by widget, pure moves, barrel re-export |
| A7 | P2 | Domain models are mutable and mutated in place; caches rely on "lists are always replaced" | code: `models.dart`, comments in `app_state.dart` | Add a revision counter on the active workout; long term immutable `copyWith` models |
| A8 | P2 | Active workout is found by scanning `exercises` for `identical(set)` on every action | code: `_isWeighted`, `liveRecords`, `followersOf` | Pass the owning `WorkoutExercise` through the call; drop the scans |
| A9 | P3 | Imperative `Navigator.push` with `AppState` passed through 46 constructors | code | Keep for now (changing it touches all tests). Revisit with an `AppScope` inherited widget |
| A10 | P3 | Whole database is loaded into RAM at start | code: `load()` | Fine below ~5k documents. Later: load history lazily by month |
| A11 | P3 | Sync columns (`dirty`, `conflict`, `remote_revision`) and `schemaVersion 1` without migrations | code: `database.dart` | Leave; write a migration test before the first schema change |
| A12 | P2 | No global error handler: uncaught errors vanish | code: `lib/main.dart` | `FlutterError.onError` + `PlatformDispatcher.onError` → local ring buffer of last 20 errors, visible in Settings → Diagnostika |
| A13 | P2 | 73 `catch` sites, several swallow the error silently | code (count) | Review each: log to the ring buffer from A12 or show a message |
| A14 | P3 | Worker: one 457-line `index.ts` | code | Split routes after the app work; not urgent |

## 4. Finish what is started (beta.12 phases C–E)

| ID | Pri | Item | Status |
|---|---|---|---|
| F1 | P0 | Onboarding: one question per screen, "Proč se ptám", auto-advance, own/for-me path | written, tests pending |
| F2 | P0 | Moje posilovna: 4 gym types, untick missing machines, photo of a machine | written, tests pending |
| F3 | P0 | Routine audit logic (`routine_audit.dart`): missing head, missing focus, low/high volume, suggestion | written, tests pending |
| F4 | P0 | Audit panel live in the program editor with "Přidat" | todo |
| F5 | P1 | Weekly muscle coverage card on Home from the same audit | done (step 6) |
| F6 | P1 | Generator draws from all available exercises, not fixed pools of ~5 | partly (respects `unavailable`); widen pools |

## 5. UX and feel

| ID | Pri | Item | Evidence |
|---|---|---|---|
| U1 | P0 | Set done: check draws itself, row tints, rest bar slides in, 0.4 s, never blocks the next tap | user |
| U2 | P0 | No PR effects mid-workout; haptics only at end of rest, PR in summary, workout finished | user decision |
| U3 | P1 | Summary as a staged, skippable sequence: time → volume count-up → PRs → week ring → rating | user decision |
| U4 | P1 | Home order: food block → today's workout → muscle coverage → last 3 workouts | user decision |
| U5 | P1 | Home food block: kcal/protein rings, recent foods (one tap re-adds), barcode button | user decision |
| U6 | P1 | Hero transition routine card → workout, exercise → detail | user decision |
| U7 | P1 | Exercise reorder/remove animated | user decision |
| U8 | P2 | 18 hard-coded `Duration(milliseconds:)` in `lib/ui` bypass the `Motion` tokens and reduced motion | code (count) |
| U9 | P2 | ~40 colours outside `theme.dart`/`tokens.dart` (growth, achievements, settings, plates) | code (count) |
| U10 | P1 | Empty states: first run of History, Stats, Strava should teach the next action | check |
| U11 | P1 | Supersets in the workout | user (deferred from beta.11) |
| U12 | P2 | RPE input in the set sheet | user (deferred from beta.11) |
| U13 | P2 | "Proti minule" chip in the exercise card header | user (deferred from beta.11) |
| U14 | P2 | Rest timer visible in the active-workout bar on every tab | check |
| U15 | P2 | Keyboard: number pad with decimal comma, next-field action, no layout jump on open | check on iPhone |
| U16 | P3 | Plate calculator reachable from the weight field | check |
| U17 | P2 | Undo for every destructive action (delete workout, delete food, delete program) | check |
| U18 | P3 | Search in history by exercise name | idea |

## 6. Product scope

| ID | Pri | Item |
|---|---|---|
| S1 | P1 | Profil → "Laboratoř": toggles for fridge AI, badges, growth, recovery card; default off |
| S2 | P1 | Hide the Premium row while `paywallEnabled` is false |
| S3 | P2 | Fridge tile leaves the top of Strava; barcode stays |
| S4 | P2 | Missions and streak: keep one line on Home, remove separate surfaces |
| S5 | P3 | AI trainer: keep, but local answer first; network only when asked |

## 7. Data safety

| ID | Pri | Item | Evidence |
|---|---|---|---|
| D1 | P0 | Web: request `navigator.storage.persist()`; show storage status in Settings | code: no call exists; Safari can evict IndexedDB |
| D2 | P1 | Backup reminder visible on Home when `backupDue`, one tap exports | check where it is shown today |
| D3 | P2 | Automatic local snapshot before restore, import and wipe | check |
| D4 | P2 | Corrupted rows are skipped at load with only a `debugPrint`; count them and show in Diagnostika | code: `_parsed` |
| D5 | P3 | Optional file-based auto backup on Android/iOS (share sheet target) | idea |

## 8. Performance

| ID | Pri | Item | Evidence |
|---|---|---|---|
| P1 | P0 | Covered by A1 + A2; measure rebuild count per set tap before/after | code |
| P2 | P1 | `Timer.periodic` 250 ms and 1 s tickers call `setState` on large subtrees in the workout page | code: `workout_page.dart:540,588` | 
| P3 | P2 | `allExercises` builds a new list on every call | code: `app_state.dart:170` |
| P4 | P2 | `RepaintBoundary` around rings, charts and the body map | check with the performance overlay |
| P5 | P2 | Web build size and first load; deferred loading of fridge and charts | check `build/web` sizes |
| P6 | P3 | `lastSetsOf` scans history per exercise; cache per exercise id | code |

## 9. Quality and process

| ID | Pri | Item |
|---|---|---|
| Q1 | P0 | CI on push: analyze, test, worker tests (laptop analyzer is unreliable) |
| Q2 | P1 | Commit per phase; nothing stays uncommitted overnight |
| Q3 | P1 | Rebuild-scope test, derived-cache test, profile-key round-trip test |
| Q4 | P2 | Stricter lints: `unawaited_futures`, `avoid_dynamic_calls`, `prefer_const_constructors` (the last one also cuts rebuild cost) |
| Q5 | P2 | Golden tests for the 5 main screens at 390 px |
| Q6 | P2 | E2E scripts in `tool/` updated for the new onboarding and run in CI against `build/web` |
| Q7 | P3 | README "Struktura" and `TESTERS.md` updated for beta.12 |

## 10. Accessibility

| ID | Pri | Item |
|---|---|---|
| X1 | P1 | Every new animated widget honours `Motion.on(context)` (reduced motion shows the final state) |
| X2 | P2 | Text scale 1.3 and 2.0 pass on the 5 main screens without overflow (test) |
| X3 | P2 | Tap targets ≥ 44 px in the new onboarding and the muscle grid (test) |
| X4 | P3 | Screen-reader walk of the workout page |

## 11. Release

| ID | Item |
|---|---|
| R1 | Version `1.0.0-beta.12+21` in `pubspec.yaml` and `lib/core/version.dart` |
| R2 | Web build + `scripts/stamp_web_build.py`; deploy command is run by Tomáš |
| R3 | IPA through `ios-sideload.yml`, verify SHA256 and bundle id |
| R4 | `docs/progress.md` entry with measured numbers |

## 12. Not doing, and why

- **State-management library (Riverpod/Bloc):** channels on the existing notifier give the same
  rebuild scoping without rewriting 73 test files.
- **Relational schema:** the document store is enough at this data size and keeps backup simple.
- **Native rewrite / App Store:** needs a paid developer account; out of budget for now.
- **Cloud sync and accounts:** conflicts with "data stays on the device"; revisit after the core loop is good.
