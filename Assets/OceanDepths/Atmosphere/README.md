# Ocean Depths atmosphere pack · 2026-11-05

- `forge-effects.json`: exact VfxForgeUltra creation tree for the replicated template
  folder `OceanAmbientTemplates` (plankton, bubbles, surface light and jelly glow).
  Recreate with `vfx_create`, parent `ReplicatedStorage`, position `keep`.
- `audio-candidates.json`: Creator Store discovery metadata. Candidates are not picks.
- `audio-manifest.json`: the six free selected roles, attribution, asset links and
  measured Studio lengths. All six also loaded in the client.
- `studio-validation.json`: scene preservation, support, navigation, 60-second school
  simulation, real encounter/glow cycles, preferences and streaming/return checks.
- `studio-player-reef.png`, `studio-zone02.png` … `studio-zone08.png`: normal play views.
  Close surface/support and jellyfish views are saved alongside them. The final
  player-facing text is shown in `studio-update-log.png`.

Authored dimensions, scene ownership, runtime lifecycle and rebuild sequence are in
`docs/ocean-atmosphere.md`. Native map shapes and approved imported creatures are reused;
there is no new mesh upload. Landscape geometry and original HD studs are preserved.
The full authoring module stages and replaces only its own atmosphere models.

All changes are Studio-preview work. Save/publication of the game is a separate action;
this pack and its validation do not publish anything.
