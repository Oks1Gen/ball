# Egg pet preview variants

The Hatch window now has a transparent shell without the large dark plate or
its border. The egg selection window keeps its existing plate. Native world
interaction prompts are temporarily hidden during Hatch and their prior enabled
state is restored on close. A UI-only fake result (no inventory/currency writes)
verified shell transparency, absent stroke and prompt restoration via Continue.
The reveal animation itself has not been redesigned yet; a shake/crack/glow
and pet-reveal sequence was proposed separately.

Current selection: the user chose Gallery (variant 2). The Gallery pet viewport
is now 104 rather than 96 design pixels high at the tested card size, and the
camera fill increased from 90% to 94%, giving roughly 13% larger silhouettes.
This approved Gallery layout applies to all four egg tabs: Common, Uncommon,
Rare and Rainbow. Each was checked in the running game: four cards in one row,
all names/chances/boosts fitting, every model's bounding corners inside the
viewport, and all mesh/texture fetches successful. Egg prices, weights and
boosts are unchanged by the UI adjustment.
The updated real Play screenshot is variant-2-larger.jpg. All four cards and
labels fit in one row. The earlier screenshots below remain comparisons.

Three real Studio Play captures at the same window size, prepared on 2026-10-22:

- variant-1.jpg: LargeCards, three tall cards with scrolling for further rows.
- variant-2.jpg: Gallery, four portrait cards in one row.
- variant-3.jpg: Split, two columns by two rows, large pet on the left and text
  on the right. This was the initial default before the user selected Gallery.

EggCardLayout.luau defines the layouts, selected by the internal EggCardVariant
screen prop. There is no additional player-facing settings or navigation.
PetViewCamera.luau fits all eight model bounds corners to the actual viewport
aspect with a margin. Only egg previews enable this framing; other PetView
callers keep their existing cameras. The framing updates on viewport resize
and disconnects its listener on unmount.

The current live Play screen was restarted once to verify the actual synced
React implementation, not just the comparison instance adjustments. All four
names/chances/boosts fit, all four cards are fully visible in the default
layout, and the preview height increased from approximately 43 to 76 screen
pixels at the tested viewport. The closer framing further enlarges the visible
pet silhouettes. Opening the screen did not hatch pets or alter inventory.

Formatting, lint, 31 tests, build and verification scripts passed. The full
gate still reports the pre-existing 99 new / 29 stale typecheck-baseline findings
under the Cyrillic workspace path; the baseline was not updated.
