# Animated wildlife · Ocean Depths

Eleven Blender-authored skinned species; one MeshPart per animal. Approved tropical fish/manta
colours and silhouettes are retained. SilverSprat and MoonJellyfish extend the same faceted style.

- `animated-wildlife.blend`: clean source library, named collections, skinning and four-second cycles.
- `<species>.glb`, `<species>.fbx`: individual rigged exports, embedded palette texture.
- `<species>-palette.png`: exact sRGB palette atlases; one material per mesh.
- `rig-manifest.json`: bone axes in each bone's rest basis, procedural cycle recipe and conservative
  deformation radius. The game varies phase/cadence per animal and drives these bones locally.
- `roblox-assets.json`: final uploaded model/package IDs. Mesh and texture IDs live inside each model.
- `roundtrip-validation.json`: 22 independent format imports; one skinned mesh/armature, correct
  bone count, normalized weights and at most four influences per vertex.
- `deformation-validation.json`: 31 evaluated poses per species inside the conservative radius;
  first/last cycle vertex positions agree within 0.0001 studs.
- `*-front-*`, `*-back-*`, `*-top-31`, `*-underside-31`: Blender QA renders.
- `studio-zone01..08.png`: actual PC Play screenshots, HUD temporarily hidden for composition.
- `studio-manta-motion-1..4.png`: actual Play frames; GIF is a slideshow of those captures,
  not a real-time video. `animation-contact-sheet.png` contains Blender animation poses.

## Rebuild / recover

1. Run Blender headless with `build.py`, then `refine.py`. The second pass adds the moon jelly,
   strengthens YellowTang's tail, seats the squid eyes, and gives the angler a fish rig.
2. Run `verify-render.py` and `verify-deformation.py`; `-- --extra-views` renders top/underside.
   Blender's glTF importer creates an Icosphere bone-display helper: QA counts skinned meshes,
   not that helper. The source blend contains only the eleven meshes and eleven armatures.
3. `upload.py` uses configured Open Cloud environment variables. Requests is in the ignored
   `.tools/python-libs` on this machine. Each species has a durable ignored journal; do not discard
   journals to retry an uncertain upload. Existing unchanged files reuse their completed IDs.
4. Studio MCP `insert_asset` the IDs into ServerStorage. Run
   `RojoTest/tools/ImportAnimatedOceanLife.luau` per model with the matching manifest entry and
   `ServerStorage.Assets.OceanDepths.AnimatedSeaLife`. This unlinks the uploaded package and
   normalizes the pivot from Root.WorldCFrame, including MeshPart.PivotOffset.
5. Fresh-require `OceanWildlifeAuthoring` and call `.apply(workspace.Map.World2)` in Edit only.
   It stages/certifies every route before replacing its previous wildlife; landscape builders are
   never called. Replaced original fauna stay in `ServerStorage.Assets.OceanDepths.LegacyWildlife`.
6. Run `tools/VerifyOceanWildlifeMotion.luau` in Edit and check `_G.OceanWildlifeStress`, then Play.
   Save the edited place through Studio's normal local Save. This workflow does not publish the game.

Open Cloud credentials are never stored in these assets. Asset upload is separate from game publication.

Visibility update (2026-11-05): fish instances use 2× size and route speed, with 2× skeletal
frequency. Reusable Blender/imported templates retain unit scale. Use the targeted,
idempotent `OceanWildlifeAuthoring.enlargeFish(world)` in Edit to apply this to existing
wildlife without rebuilding any landscape. Full `.apply` also applies these multipliers.
See `docs/ocean-wildlife.md` and `fish-visibility-validation.json` for the new safe envelopes,
58 route certificates, simulation, preservation checks and Play evidence. The close/reverse
screenshots are `studio-fish-double-size-close.png` and `studio-fish-double-size-reverse.png`.
