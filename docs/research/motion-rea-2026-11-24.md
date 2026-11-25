# Workout interaction and motion follow-up

## Observed competitor evidence

REA controlled browser navigation and passive accessibility inspection on November 24, 2026:

- [Hevy feature page](https://www.hevyapp.com/features/): the rendered page lists automatic rest timers, previous workout values, supersets, live personal-record notifications and progress tracking. REA inspection Evidence `ev_21839dd2b15a4880e9ef5487640de4259225746ea299b808a5495ae6fedd3786`; navigation parent Evidence `ev_49af97cc7f7d66a7f4cd6311eda44c078080d15317461ce8fca24de4c131b37b`.
- [Strong public site](https://www.strong.app/): the rendered page emphasizes simple workout recording, progress visualization, custom timers, best-set tracking and data export. REA inspection Evidence `ev_31921ec52b239ed4ca3b8b467c6588dbebe69cc6eb4d86abdec1bef99fd25737`.

These observations establish public product descriptions, not behavior inside their signed-in mobile apps. Exact animation curves, timings, persistence and offline behavior remain unknown. We did not copy assets or code. The implementation below is our design inference from the importance these products give to logging feedback and progress.

The first REA browser launch failed because this host cannot initialize Chromium's sandbox. A temporary headless Chromium process using an isolated profile and loopback CDP endpoint allowed REA to navigate and inspect the public pages. REA disconnected cleanly; the owned browser was stopped afterward.

## Changes in this worktree

- Workout volume and completed-set totals slide and fade when they change, retaining the exact latest value for accessibility.
- Exercise cards animate their height as sets are added or removed.
- The rest bar expands/collapses smoothly, countdown values transition, and its completion icon changes with a brief pop.
- Nutrition's remaining-to-goal label transitions and acknowledges goal completion.
- Reduced motion immediately settles delayed reveals, tab transitions and selection pops, including when enabled during an animation.
- Ambient effects stop their shared clock subscriptions while the app is in the background, resuming only in the foreground.

All effects are bounded or use the existing shared ambient clock. Workout actions remain available during transitions. No additional perpetual per-widget animation controller was introduced.

## Verification scope

Regression tests first reproduced the delayed-reveal, tab-transition and background-clock problems. Motion tests also check that outgoing animated values do not appear in accessibility. Focused workout, rest, set-entry and nutrition tests cover interaction behavior. Workout screenshot tours provide before/after layout evidence; static images do not establish animation quality over time.
