# Clover Bunny — Blender model v1

2026-11-09. Made in the user's connected Blender5.2.3 via MCP using bpy.
The user named Frost Egg but explicitly requested Clover Bunny; the selected
species and approved Forest v4 picture govern this asset. No egg mapping changed.

## Files

- `model/CloverBunny.blend`: clean editable scene, asset collection and root only.
- `model/CloverBunny.glb`: evaluated geometry and embedded material images.
- `model/CloverBunny.fbx`: evaluated geometry with embedded images.
- `work/front-three-quarter.png`, `work/rear-three-quarter.png`: actual Blender renders.
- `work/roundtrip-{blend,glb,fbx}.png`: renders after independent reimports.
- `work/export-validation.json`: dimensions, geometry and import checks.
- `work/build_clover_bunny.py`, `work/refine_clover_bunny.py`,
  `work/export_clover_bunny.py`, `work/render_validate_clover_bunny.py`: source workflow.

Reference: `../../../concepts-v4/forest-egg-five-pets-v4.png`, Clover Bunny only.
Soft square cream body, pink ear inlays/nose/blush, green iris gradients and
two catchlights, tiny feet, one upright ear and one broad folded ear, tiny clover.
Unseen rear continued as a cream back with a small round lobed bunny tail.
No studs, fur, collars or extra equipment introduced.

One2-unit cube combines head/body; +Z up, front -Y, empty root at ground origin.
Segmented static asset; no rig or animation requested. Parts remain separately
named/editable. Body/feet keep bevel and normal modifiers; ears keep smoothing
and decimation modifiers. Iris256px and blush128px PNGs are packed in BLEND,
embedded in GLB/FBX, with portable simple Principled materials. Palette sRGB
hexes are in `work/build-summary.json` and material custom properties.

## Verification

Evaluated export: **9,988 triangles**, maximum1,330 per part;31 mesh components
plus root,27 native editable mesh objects and4 editable curve parts in BLEND.
Zero degenerate export triangles. Solid volumes have outward normals; irises
and alpha blush are deliberate front-facing surface patches. Curve caps welded
in the export copy. No triangle budget or runtime performance claim for Studio.

Clean BLEND has one scene and no cameras, lights, floor or original default cube.
All three formats loaded independently in the same Blender session from copies
containing only the deliverable files. Bounds error0 for BLEND/GLB and below
0.000001 units for FBX; eye orientation remains -Y. GLB has no external image or
buffer URIs. FBX importer extracted and packed both embedded images; their
paths are under the validation copy's own `.fbm` directory, not original PNGs.
All three import renders visually retain ears, colors, eyes, catchlights and blush.

Original default scene's Cube/Camera/Light matrices preserved. Backup before
authoring: `work/blender-before-clover.blend`; full authoring session backup:
`work/authoring-session.blend`. The same asset collection is linked into the
original scene, and the clean `CloverBunny` scene is left active in the open app.
Temporary verification scenes/objects removed; preview scene is authoring-only.

KB: Chibi Character Rules in Practice (`Version2: what made the difference`),
Organic and Creature Modeling (`Checklist`). Applied low expressive eyes,
iris/catchlight depth, tiny limbs, no neck, safe face orientation and export checks.
Generic pear/round-body advice yields to the explicitly approved square cube.

No Roblox Studio import, upload, gameplay integration, profile change, Update Log,
permanent standard write, commit or publication occurred in this modeling task.
