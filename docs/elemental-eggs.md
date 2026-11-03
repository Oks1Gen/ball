# Elemental egg asset set — 2026-11-03

Five replacement visuals were reconstructed in Blender from the user's approved
reference: Meadow, Glacier, Magma, Void and Celestial. This is an asset-authoring
change, now integrated on the existing stand. Common uses Meadow, Uncommon
uses Glacier, Rare uses Magma, Rainbow uses Void, and the premium Volcanic egg
uses Celestial. Purchase IDs, captions, prices, rewards and hatch logic remain.
The current unpublished Update Log's lobby entry includes the new visuals.

`server/ElementalEggStyle.luau` applies this mapping after EggStandStyle, without
rerunning world builders in Edit. It preserves interaction anchors, fits each
visual to 10 studs, and places its bottom 0.08 studs above the matching seat.
Reapplying reuses the existing themed models. The premium client's
VolcanicEggVisual recognizes Celestial and retains the replicated native model.
The previous shop and original visuals are backed up under
`ServerStorage.WorldBackups.BeforeElementalEggReplacement_20261103`.

Server and Client Play verified all five mappings and prompts; the premium
fallback stays hidden and the client create call retains Celestial. Returned
to Edit afterward. Purchases and hatching were not triggered.

## Current Studio locations

- `ServerStorage.Assets.Eggs.Elemental`: five independent finished Models.
- `ServerStorage.Assets.Eggs.ElementalPreviewRow`: spaced copies of the same
  models, retained outside Workspace for review/manual placement.
- `ServerStorage.ElementalEggTemplates`: reproducible native facet inputs,
  mapped from the asset's `.rbxmx` through Rojo. These are build inputs, not the
  optimized models to place in the live map.
- `ServerStorage.WorldBackups.ElementalEggs_FirstPass_20261103`: first authoring
  pass, preserved outside Workspace.

Each finished model has its pivot at its ground origin and a nominal visible
height of 10 studs. Thin native surfaces extend the measured height by less
than 0.008 studs. The default front is local +Z; rotate to face the desired
direction before replacing an existing visual. All decorative geometry is
anchored and has CanCollide/CanTouch/CanQuery disabled.

## Import method and persistence

The connected Studio rejects `AssetService:CreateAssetAsync` with
`CreateAssetAsync and CreateAssetVersionAsync are not available yet`.
Consequently this set uses **persistent native UnionOperations**, not temporary
EditableMesh content and not uploaded MeshParts. Blender triangle surfaces are
transferred as 0.008-stud thin wedges, then consolidated per source component.
The final 105 UnionOperations preserve per-face colors with UsePartColor=false;
glowing cores use Neon and other surfaces use SmoothPlastic. Facet interiors and
base color variations are geometry/materials, not baked lighting textures.

These UnionOperations are saved with the place when the user saves Studio.
They do not require mesh IDs or an asset upload. No game publication occurred.
The source FBX is also available for a later lower-instance-count MeshPart import
through Studio's 3D Importer; it contains a shared embedded flat palette texture.

## Files and reproducibility

Asset directory: `RojoTest/assets/eggs/elemental-v1/`.

- `elemental-eggs-final.blend`: final editable Blender scene, currently opened.
- `elemental-eggs.fbx`, `elemental-eggs.glb`, `palette.png`: mesh exports.
- `reference.png`, `preview-refined.png`: approved reference and actual Blender render.
- `build_eggs.py`: deterministic model/UV/palette/export generator; preserves the
  pre-existing Blender session in `blender-session-before-eggs.blend`.
- `geometry.json`: exact local Blender geometry, mapped to Roblox X/Y/Z.
- `export_native.py`, `elemental-eggs.rbxmx`: persistent native source fallback.
- `validation.json`, `native-validation.json`, `fbx-roundtrip-validation.json`,
  `studio-validation.json`: recorded checks.

`tools/ImportElementalEggs.luau` imports the JSON through a temporary localhost
asset server using Studio MCP. It refuses to overwrite existing templates and
does not alter the map. `tools/OptimizeElementalEggs.luau` consumes clones of
these source components and builds the finished set with GeometryService. It
reports progress through the set's Status/CompletedComponents attributes and
retains wedge geometry if a union fails. All 105 components completed without
failure for the delivered set. Do not rerun old world builders for this import.

## Verification

- Blender: 4,394 triangles, closed geometry, no degenerate faces or nonmanifold edges.
- FBX round trip: five named roots, 105 meshes, UVs on every mesh, no floor,
  cameras, lights or unrelated objects.
- Studio: five models, 105 native unions, base pivots and clone/PivotTo checked.
- Studio screenshots: whole row and close view in the actual lobby lighting.
  Temporary Workspace copies were moved to ServerStorage after inspection.
- 22,256 original map parts retained transform, size, transparency and physics.
- `check.mjs`: formatting, lint, 107 unit tests, five verification-gate tests,
  Rojo build, module checks and typecheck passed. Windows luau-lsp's Cyrillic-path
  issue was avoided with an ASCII temporary junction and Node's
  `--preserve-symlinks --preserve-symlinks-main` flags.
- No Play, hatch, purchase, mobile, save-data or game-publication actions.

Integration changes only the visuals. Existing EggShells, interaction anchors,
egg keys, prompts, prices and stand geometry are preserved. Save the place in
Studio to retain the edited scene and optimized source models.
