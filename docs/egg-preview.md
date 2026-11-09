# Egg preview

Approaching an egg within 14 horizontal studs opens a nonmodal catalogue;
leaving 17 studs closes it. A neighbour takes over when at least 1.5 studs
closer. Other windows, hatching, flight and the map intro block the catalogue.
The active egg's world sign is replaced temporarily, then restored.

`Controllers/EggPreview.luau` owns proximity and lifecycle;
`CollectorUI/EggStandPanel.luau` owns the React view. A single interactive
`BillboardGui` in PlayerGui follows a local attachment at the visible egg's
centre, including its levitation. Its size in studs scales with camera
distance. The round **E** is centred on the egg, **Hatch 1** sits to its left,
and **Hatch 3** sits below. The catalogue is separate on the far left. The
centre button and Hatch 1 both use the existing single-hatch command. Solar
Crown uses the same action at Football City's fifth stand. Ocean Depths' Jelly
Egg uses the guaranteed Admin Egg purchase action. Normal is omitted.

The billboard reduces its scale around E to fit the safe screen rectangle
between the navigation, offers and progress HUD. The layout reserves room for
the opening overshoot. At an extreme edge, where further shrinking would
make the cards hard to read, it shifts inward by the necessary amount. The
tutorial follows the resulting button position. The last-kick caption yields
its space to Buy Egg while the egg preview is in view.

The appearance uses the game's shared Theme and Components: translucent grey
panel (0.3), GothamBlack, ink outlines, rarity tiles and green/gold stud buttons.
Actual world-sign titles/colours are reused. A three-column grid centres the
last partial row; only real pets are displayed. Percentages come from current
server-configured weights; each action shows its complete price. Restricted
random rewards still show the guaranteed pet at 100%.

Unknown pets show their exact portrait/model tinted pure black, without names
or boosts. Known pets use the full-colour portrait. Both image and 3D fallback
obey discovery. `ProfileData.discoveredPets` persists obtained kinds independently
of inventory copies. Older saves infer discoveries from valid current pets;
already deleted pets cannot be inferred retroactively. All acquisition paths
call `equipBest`, which records the current kinds before publishing. Recycling
and crafting do not clear history; the explicit full developer reset does.
Snapshot data carries the history; current inventory is a compatibility fallback.

Motion reuses UiMotion/Ripple for window and buttons. Portraits gently float
and sway over rotating rays, with independent phases. Effects Off stops these
layers and button/window transitions. The audio bus supplies quiet opening and
action clicks and obeys the player's volume. Hatching retains its existing
sound/reveal. This is an in-world proximity overlay, so it leaves HUD and world
unblurred; the modal HUD/blur rules apply when opening a full inventory window.

The first-hatch tutorial projects the egg centre into the HUD coordinate
system so its pointer follows the round button. Keyboard actions require the
egg to be in view and within the billboard's render distance.

PC verification is recorded in `verification.md`, “Egg preview in 3D — 2026-11-09”.
Mobile checks are deferred by AGENTS.md.
