# Ball display

## Current balls: Low Poly V2 (2026-10-31)

The game uses the Low Poly V2 pack from `Assets/Balls/LowPolyV2/` (Blender sources, not in Git).
Everything below this section describes the replaced first-generation models and is history.

- Stone ids, power and prices are unchanged; names and sign colours follow the new meshes:
  Pebble = Rubber Ball, Smooth = Classic Ball, Golden = Beach Ball, Ruby = Basketball,
  Emerald = Leather Ball, Galaxy = Steel Ball, Rainbow = Gold Ball, DragonSun = Storm Ball,
  BlackHole = Volcano Ball, WorldCreator = Sun Ball.
- Each ball is a single MeshPart: no vertex colours. Its UVs point into a shared 1024 px colour atlas
  (16 px flat tiles; face shading and glow are baked into the tile colour). It uses SmoothPlastic
  and a white Color.
- Roblox assets, all on account 11789507527:
  - Model `72414326263846` (all ten meshes).
  - Image `125793810196493` (the atlas).
  - Universe `10770268214` has been granted Use through the Open Cloud asset-permissions API. Without that grant, Studio answers "User is not authorized to access Asset", because the place belongs to 11792184677.
  - The MeshIds inside the Model are listed in `Assets/Balls/LowPolyV2/make_templates.py`.
- Pipeline:
  1. `export_roblox.py` in Blender writes `roblox/balls.glb`, `atlas.png` and `manifest.json`.
  2. Open Cloud upload: the glb as Model, the atlas as Image.
  3. `game:GetObjects` returns the inner MeshIds.
  4. `make_templates.py` writes `src/shared/BallTemplates.rbxmx`.
- Roblox's glTF importer turns the scene 180° about Y. The templates turn each part back, so the ball centre sits at the template origin and the front (the Blender front view) faces -Z.
- Each template Model carries `FitSize`, its largest outer dimension with accessories included.
  - `BallVisuals.create` scales that dimension to the requested diameter, so all ten balls take up the same size: the user asked for this.
  - Balls with a ring, spark or spikes therefore have a slightly smaller body.
  - The pivot stays at the ball centre.
- `Visuals.fitKey` lets the stand rebuild placed copies once the templates change.
- Stands:
  - Ten display models were created in Edit:
    - World1: in `Workspace.AllBalls_NoTextures`, display diameter 4.
    - World2: in `EmptyItemStand.DisplayBalls`, diameter 6.
  - They have the same slots, BallId/DisplaySlot attributes and label links. Their front faces the purchase side of each DisplayTop (+X).
  - The previous models are in `ServerStorage.WorldBackups.BeforeLowPolyV2Balls`.
  - Save the place to keep this scene edit.

### Minimal stand (2026-10-31)

The look follows the user's reference: a lavender stepped platform with studs, and items on square pads.

- **`BallStandStyle.apply`:**
  - Removes the old navy `BallShopDecor`: the header, posts, neon rims, corners and badge.
  - Paints the tiers lavender `C(196,196,244)` with studs on top and on the sides.
  - Paints each `EmptyPedestal` as a cream frame `C(244,232,226)`.
  - Makes each `DisplayTop` a raised periwinkle pad `C(172,188,240)` with studs. The pad's height is 1.5 times the frame's and is recomputed from the frame, so the pass is idempotent.
- **SurfaceSeparation:**
  - It used to keep offset copies of the stand parts and hide the originals.
  - The style deletes the stand's copies, restores the originals' transparency and sets `SurfaceSeparationSkip` on the `EmptyItemStand` folder.
  - `SurfaceSeparation.apply` now skips every record that goes through such a folder.
- **`BallStand`:**
  - The ball body's diameter is `0.45 × min(pad X, Z)`: 2.7 in World1 and 4.05 in World2.
  - A model with a different `DisplayDiameter` is rebuilt from its template, facing the purchase side of the pad.
  - The ball sits `0.5 + 0.2 × scale` above the pad, which covers the bob.
  - The caption hangs `(1.6 + 2.7) × scale` above the ball.
- **Backup:** the previous stand parts and decor are in `ServerStorage.WorldBackups.BeforeMinimalBallStand`.

## Previous Studio stand placement

The active game now uses the ten true ball names in tier order, increasing
multipliers from ×1 through ×10, and Crowns prices. Labels follow the levitation.
`src/server/BallStand.luau` and `src/shared/GameConfig.luau` maintain this current
display; the one-off placement/label scripts below describe its earlier setup.
All ten models are available as gameplay templates in
`src/shared/BallTemplates.rbxmx`. Purchase and animation validation is documented
in the project README.

All ten balls now have labels above their bounds with a 0.65-stud gap.
The lower row labels now use Rubber Rookie, Steel Impact, Crystal Ice,
Volcano Heart, and Mechanical Reactor from left to right. Upper-right
labels use Black Hole and World Creator. Existing multipliers are preserved. Slots 8–10
have new decorative labels Dragon Stone, Thunder Stone, and Plasma Stone;
no progression entries or multipliers were added. `tools/LabelImportedBalls.luau`
applies this once and saves the seven original anchors to
`ServerStorage.WorldBackups.BeforeBallStandLabels`. All ten label positions
were checked above their balls and an Edit screenshot was inspected.

The imported `Workspace.AllBalls_NoTextures` models are now arranged on
`Workspace.ProgressionMap.EmptyItemStand` in the reference order: balls 1–5
left to right on the lower tier, balls 6–10 left to right on the upper tier,
when viewed from the plaza (+X). Slots are 5–1 and 10–6 respectively.
Models use 2.5 times their imported scale, centered pivots, and a quarter-turn
toward the plaza. Each bounding box rests 0.025 studs above its DisplayTop;
all ten fit their tiles. Display meshes are anchored and exclude collisions,
touches, and queries. Existing stone proxies are hidden; their prompts and
the existing stone names/progression are retained.

`tools/PlaceImportedBalls.luau` applies this placement once. Studio backup
`ServerStorage.WorldBackups.BeforeBallStandPlacement` preserves the imported
models, stand, and original stone proxies. All 23 stand parts retain their
transforms, sizes, and collision flags. An Edit screenshot confirmed both
rows and the order. Play was not run. Save the place to retain these edits.

`ball-display.blend` is the current editable scene containing ten upgrade balls.
Each row is placed left to right at X=0, 3.2, 6.4, 9.6, and 12.8, on separate pedestals.
The original five are at Y=0; tiers 6–10 form a second row at Y=4.6.
Ball roots are named `Ball_01_RubberRookie`, `Ball_02_SteelImpact`,
`Ball_03_CrystalIce`, `Ball_04_VolcanoHeart`, and `Ball_05_MechanicalReactor`.

The three newest models use simplified Roblox-style forms: a translucent faceted
ice sphere with a central diamond and three points; twelve dark pentagonal plates
over an orange core; and large reactor panels, a chunky belt, and a cyan front lens.
Their components remain separate and editable under their respective root empties.

`add_tiers_3_5.py` adds tiers 3–5 to a scene containing tiers 1–2, preventing duplicates.
`before-tiers-3-5.blend` preserves the prior two-ball scene. The first two balls'
mesh-object transforms were checked unchanged. Pedestal contact and the final
camera render were checked. `five-balls-preview.png` is the final render.

Tiers 3–5 have not been exported or imported into Roblox Studio. Blender glass and
emission materials will need equivalent Roblox materials during import.

The ice shell uses blue alpha transparency with the BLENDED surface method instead
of transmission/refraction. This keeps the central crystal visible in Material
Preview and avoids the dark tinted shell and dither grain. The pre-fix scene is
saved as `before-ice-color-fix.blend`.

`add_tiers_6_10.py` adds the second row using simple editable primitives. Their roots
are `Ball_06_PlasmaSatellite`, `Ball_07_ThunderSplit`, `Ball_08_DragonSun`,
`Ball_09_BlackHole`, and `Ball_10_WorldCreator`. The first row's mesh transforms
were checked unchanged. `before-second-row.blend` is the pre-addition backup.
`ten-balls-preview.png` shows the final two-row composition from the scene camera.
Tiers 6–10 have not been exported or imported into Roblox Studio.

Tiers 6–9 now use the revised faceted Roblox reference
`references/06-09-low-poly-roblox-v2.png`. Their ball geometry totals 296, 236,
264, and 272 triangles respectively, excluding their separate pedestals.
They use flat-shaded spheres, polygonal hoops, faceted satellites, closed armor
wedges, a geometric dragon head with rectangular eyes and dorsal fins, and a
segmented accretion disk. Their row X/Y positions are preserved; only their
height is adjusted to rest on the pedestal after rebuilding.
`rebuild_low_poly_6_9.py` implements this revision, and `before-low-poly-6-9.blend`
preserves the preceding scene. Models 1–5 and 10 were checked unchanged.
`LowPoly_6_9_Review` is an additional scene for inspection, sharing the four models
with the main display. `low-poly-6-9-preview.png` is the checked final render.
The earlier ten-ball preview predates this revision.

## Roblox import pack

`roblox-import/roblox-balls-10.fbx` contains the final ten balls without display
pedestals or studio objects. The pack includes fourteen mesh objects under ten
named ball roots. Transparent shells and the larger reactor/world components
are separate; every individual mesh is below 10,000 triangles. Colors are stored
in PNG textures with UVs, preserving the starter ball's existing rubber texture.
Modifiers are evaluated on export copies; the source blend is unchanged.
`export_roblox_pack.py` builds the pack and `validate_roblox_pack.py` checks a fresh
FBX import for all ten roots, mesh counts, UVs, triangles, and texture file links.
The validation passed in Blender; Roblox Studio import is not yet verified.
`roblox-balls-10.zip` bundles the FBX, textures, and Russian import instructions.
Set the two transparent shell MeshParts to Transparency=0.74 after import.

The original import pack is superseded by `roblox-balls-10-v2.zip` and
`roblox-import-v2/`. The original exporter compared evaluated material datablock
identities against original datablocks, incorrectly mapping all faces to the
first color swatch. The revised exporter matches material names and gives every
polygon positive UV area within its own color tile. Validation now samples the
texture at triangle UV centroids and verifies the expected color-region counts
after FBX reimport, in addition to geometry and texture-file checks. These checks
passed. Roblox Studio is not connected, so Studio validation remains pending.

The user's next import failed specifically with `base_color_texture: Upload failed`.
The PNG files were checked as valid 8-bit RGBA. The error does not identify why
Roblox rejected the image upload. `export_vertex_colors.py` creates an alternative
`roblox-vertex-colors/AllBalls_NoTextures.fbx` with colors stored as CORNER color
attributes, removing all image texture nodes and external image dependencies.
The file is also available under the ASCII-only path
`C:/Users/userr/Documents/RobloxBalls_VertexColor/AllBalls_NoTextures.fbx`.
FBX round-trip checks passed for fourteen meshes, retained color attributes, and
zero image texture nodes. Set MeshPart.Color to white and shell Transparency to
0.74 after import. The starter ball's original texture is approximated by vertex
colors in this alternate pack; fine rubber grain cannot be retained exactly.
Roblox Studio validation remains pending.
