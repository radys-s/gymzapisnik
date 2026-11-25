# Design system v2 ("Ember")

Written 2026-11-22. Replaces the neon gradient look of beta.13/14. Competitor notes that shaped it:
[`docs/research/competitors-2026-11.md`](research/competitors-2026-11.md).

## Principles

1. **Data first.** The workout screen is a table, not a stack of cards. Numbers are big, labels are small.
2. **One accent.** Ember orange marks what you can press and what is current. Nothing else is orange.
3. **Color means something.** Green = a completed set or a positive change. Gold = a record or badge.
   Red = destructive or failure set. Everything else is neutral grey.
4. **Quietly layered.** Depth comes from surface tone (background → card → control). A single soft
   shadow under the bottom bar and a subtle gradient on a pressed/selected tile are allowed; no
   glows, grid textures or drifting backgrounds.
5. **Quiet motion.** All transitions go through `Motion` (roughly 120–280 ms for state changes, zero
   when the system asks to reduce motion). Nothing moves on its own.

## Tokens (`lib/ui/design/tokens.dart`)

| Token | Value | Use |
|---|---|---|
| `background` | `#0A0A0B` | page |
| `grouped` | `#151517` | cards, panels |
| `elevated` | `#1E1E21` | dialogs, menus, rest bar |
| `fill` | `#242428` | controls: set fields, chips, secondary buttons |
| `separator` | `#2A2A2E` | hairlines |
| `label` / `secondaryLabel` / `tertiaryLabel` | `#F5F5F4` / `#A1A1A8` / `#6B6B73` | text |
| `accent` = `AppPalette.ember` | `#FF6B2C` | actions, selection, exercise names, today |
| `onAccent` = `AppPalette.ink` | `#0A0A0B` | text on accent (black on orange reads 7:1) |
| `positive` = `AppPalette.done` | `#3DD68C` | done sets, done days, positive deltas |
| `gold` | `#FFC53D` | records, badges, warm-up badge |
| `negative` | `#FF5A5F` | delete, failure badge |

Data colors (`violet`, `blue`, `cyan`, `teal`, `pink`, `lime`, `yellow`) are only for charts with
several series, supersets and real-world colors (plates). Never for icons or buttons.

`Tone` still exists so old call sites compile, but every tone is the accent.

Radii: control 12, card 16, hero 20, sheet 20. Small inline controls (set fields, ✓, chips) use 8.

## Type

- **Inter** (400–800) for all text. Large titles 30/800, section titles 19/700, body 16/14.
- **Barlow Condensed** 700 only for figures: timers, volume, stat tiles, records, 1RM.
- Eyebrows and table headers: 11 px, 700, uppercase, `tertiaryLabel` (`textTheme.labelSmall`).
- All numbers use tabular figures.

## Components

- `PrimaryButton`: flat accent, 52 px, centered label with optional leading icon. One per screen.
- `SecondaryButton`: `fill` background, label color.
- `Panel` / `CardSurface` / `HeroCard`: flat `grouped`, radius 16, no border, no shadow.
- `IconTile`: 14 % tint of its color with the icon in that color; neutral by default.
- `StatTile`: condensed figure + small label.
- Tab bar: no indicator; selected = `label`, others = `tertiaryLabel`.
- App bar icons: `label`, not accent.

## Key screens

- **Workout**: session strip (time · volume · done/total sets + green progress line) under the app bar;
  exercises edge to edge separated by hairlines; exercise name in accent; set table
  `SÉRIE | MINULE | KG | OPAK. | ✓` with 44 px rows; done row tinted green, ✓ becomes a green
  square; set badge colors W gold, D violet, F red; full-width "Přidat sérii"; rest bar is an
  elevated card whose elapsed part fills with accent.
- **Home**: greeting, week strip (Mon–Sun, done days green ✓, today ringed in accent, planned
  days dotted, streak in weeks), today's routine card, food, recent workouts.
- **Training**: routine cards with exercise preview and a per-routine Start button (accent for
  today's).
- **Progress**: totals, 1RM curve, recent records (gold), 16-week consistency heatmap,
  strength-level ladder for squat/bench/deadlift/OHP.
- **Summary**: completion check, divided stat row, gold record list, coach, rating, next workout.

## Logo

Ink ring-"G" with a dumbbell on a flat ember plate (`lib/ui/design/brand.dart`). Regenerate icon
files with `flutter test tool/brand_assets_test.dart`.
