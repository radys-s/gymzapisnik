# UX audit, November 2026

Audited on 2026-11-18 against `main` at Beta 13 (`1290324`). Goal: fewer taps, fewer errors and
clearer screens for someone logging sets between sets, one-handed, with sweaty hands. No new
features.

## How it was tested

- Release web build (`flutter build web --release`) served locally and driven in a real browser
  at phone width (360 × 780) and desktop width (1280 × 800). Taps were real pointer clicks; touch
  target sizes come from the Flutter semantics tree.
- The app has one dark theme (`themeMode: ThemeMode.dark`), so there is no light mode to check.
- First-time user: welcome → terms → 5 questions → plan → Home → first workout → summary.
  Returning user: Home after a workout, history, editing a finished workout, settings, backup.
- Read the code behind each screen to confirm what the browser showed and to count steps on
  paths the browser could not reach (phone keyboard, empty sets).
- Built on recent work: `docs/PLAN.md` (U1–U18, X1–X4), the Beta 13 entry in `docs/progress.md`,
  and the last 30 commits. Already-solved items (undo on set delete, tap-to-copy "Minule", rest
  timer on every tab, drawn check, quiet PRs mid-workout) are not repeated here.

Screenshots of the state before this pass: [`docs/screenshots/ux-2026-11/`](screenshots/ux-2026-11/).

## Step counts today

| Journey | Steps (taps) | Notes |
|---|---|---|
| First launch to Home with a plan | 10 | Začít, consent, 18+, Pokračovat, 5 answers, "Beru tenhle plán" |
| Start today's workout from Home | 1 | "Začít Push" |
| Log a prefilled set | 1 | ✓ starts the rest timer |
| Log a set with a changed weight | 4 | weight field, +, Hotovo, ✓ |
| Log the first set of a never-done exercise | 5 + typing | ✓ (error toast "Zadej počet opakování."), kg field, type, Hotovo, ✓ |
| Finish workout with unconfirmed sets | 2 | Dokončit, Dokončit |
| Fix a wrong set right after finishing | 6 + scroll | Hotovo, Pokrok, scroll, Historie, workout, ⋯, Upravit, then edit and Uložit |
| Open history (and its search) | 2 + scroll | Pokrok, scroll (row is below the fold at 780 px), Historie |
| Back up data | 2 + system save | ⚙, Uložit zálohu |

## Friction points

Each line: what, evidence, impact (H/M/L), effort (S/M/L).

### Logging sets

1. **The set sheet cannot confirm the set.** After changing weight or reps the user must close the
   sheet ("Hotovo") and then find and tap ✓. It costs a tap on every adjusted set, and an edited
   but unconfirmed set is the classic "I thought I logged it" error (the finish dialog then says
   "Nepotvrzené se neuloží"). Evidence: `set_sheet.dart` has only `Hotovo`;
   screenshot `before-05-set-sheet.png`. H / M.
2. **✓ on an empty set shows an error instead of helping.** A new exercise (free workout, added
   or swapped exercise without history) starts with an empty set (`_prefilled` → `SetEntry()`).
   Tapping ✓ shows "Zadej počet opakování." and nothing else; the user must then find the field.
   Evidence: `toggleDone` returns the message; `_SetRow._toggleDone` only toasts it. H / S.
3. **Rest bar buttons shrink below 44 px on narrow phones.** At 360 px the `FittedBox` scales
   −15 / +15 / Přeskočit down to 41×36, 40×36 and 71×36 px (measured), and the hit area shrinks
   with them. These are the buttons pressed between every set. Evidence: `timers.dart`
   `_RestBarState.build`; screenshot `before-04-workout-rest-bar.png`. M / S.
4. **The set sheet opens the keyboard every time.** The weight (or reps) field autofocuses, so on a
   phone the keyboard covers the lower half of the sheet (RPE, Hotovo) even when the user only
   wants ±2.5 kg. Needs a check on a real iPhone before changing; typing users would lose a tap.
   Evidence: `autofocus: !widget.focusReps` in `set_sheet.dart`. M / S.
5. **Workout title (rename) target is 37×37 px.** Below the 44 px minimum. Evidence: semantics
   box of the title button in the workout app bar. L / S.

### After the workout

6. **No way to fix a mistake right after finishing.** The summary shown right after "Dokončit" has
   only "Sdílet"; editing exists only later, from history, behind the ⋯ menu. Fixing "I logged 6,
   it was 8" takes 6 taps and a scroll. Evidence: `summary_page.dart` shows the menu only when
   `!finished`; screenshot `before-06-summary.png`. H / S.
7. **Editing a past workout cannot change its date or add a forgotten exercise.** The edit page
   shows the date as plain text and has no "Přidat cvik". A workout logged late stays on the wrong
   day. Evidence: `edit_workout_page.dart`, screenshot `before-07-edit-workout.png`. M / M.

### Finding things

8. **History is below the fold.** On Pokrok the "Historie" row sits at y = 941 px on a 780 px
   screen after one workout, and drops further as charts and records appear. History search is
   only there. Evidence: semantics boxes on Pokrok; `progress_page.dart` `_rows`. M / S.

### First run

9. **A double tap on the last question lands on "Složím si vlastní".** The plan screen puts its
   secondary action exactly where the previous step's primary button was (y 708–760 vs 716–760).
   In the browser one click on "Nic mě nebolí" also opened the empty program editor. Could be a web
   semantics artefact; on a phone it needs a quick double tap. Evidence: semantics boxes of both
   screens. M / S.

### Desktop and accessibility

10. **Desktop web: Esc does not close pages, chips are 32 px tall.** On desktop Flutter uses
    `MaterialTapTargetSize.shrinkWrap`, so RPE and "Jak to šlo?" chips measure 35×32 px; phones get
    the padded 48 px target, so this matters only with a mouse. Esc closes dialogs but not pages.
    L / S.

Checked and fine: Czech copy reads naturally; errors say what to do next ("Zkus to znovu";
"Sérii potvrdíš zaškrtnutím vpravo"); empty states exist for workout, history search and Pokrok;
the finish dialog counts confirmed sets; delete set has undo; all main buttons, set fields
(64×45) and ✓ (48×48) meet 44 px; option cards expose `selected` to screen readers; desktop
layout centres a 760 px column without breaks (`before-08-home-desktop.png`).

## Top 10 by impact ÷ effort

| Rank | Item | Impact | Effort | Plan |
|---|---|---|---|---|
| 1 | ✓ on an empty set opens the set sheet (#2) | H | S | do now |
| 2 | Edit right after finishing, edit visible in history detail (#6) | H | S | do now |
| 3 | Confirm the set from the set sheet (#1) | H | M | do now |
| 4 | Rest bar buttons stay ≥ 44 px (#3) | M | S | do now |
| 5 | History one tap from Pokrok (#8) | M | S | do now |
| 6 | Plan screen: no secondary action under the previous primary (#9) | M | S | next |
| 7 | Set sheet without automatic keyboard (#4) | M | S | after an iPhone check |
| 8 | Workout title target ≥ 44 px (#5) | L | S | next |
| 9 | Edit date and add exercise in a past workout (#7) | M | M | later |
| 10 | Desktop Esc and chip size (#10) | L | S | later |

Items 1 and 3 touch the same sheet and ship together.
