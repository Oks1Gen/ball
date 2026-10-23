# Red pets: 30-model import pack

## Current game mapping

The user imported the FBX through Studio on 2026-10-22. All 30 models were
validated and staged in `ServerStorage.ImportedPetPacks.Red30`; the original
import is retained in `ServerStorage.WorldBackups.OriginalRedPets30Import`.
Save the place in Studio to retain these scene-only staging folders.

The four pets marked in the user's reference image now replace the red Common
egg pool: Scarlet Mushroom (pack 25, 45%, x1.2), Strawberry Cake (pack 21, 30%,
x1.5), Autumn Cat (pack 09, 20%, x2.5), and Flame Cat (pack 06, 5%, x8).
Price remains 50 and egg multiplier remains x1. The retired Dog, Cat, Bunny,
Fox and Dragon definitions remain in `Config.LegacyPets` and the ProfileService
catalog, so existing inventory/equipment survives normalization. Other eggs
are unchanged. Each new pet explicitly sets eggBoost=1 for direct admin grants.

`common-egg-assets.json` records the persistent mesh/texture IDs and measured
body widths. `tools/AddCommonPetTemplates.py` adds only these four models to
the existing Rojo-managed template registry; their bodies are normalized to
width 1.8 and their fronts use the same orientation as the existing templates.
`PetVisuals.prepare` preserves TextureID when hydrating a Rojo-created MeshPart.
The mapping, textures and config are stored on disk and sync through Rojo.

Studio verification covered all 100 Common roll positions, preview/follower
creation, four successful mesh/texture preloads, legacy and new catalog entries,
and a synthetic inventory normalization retaining both old and new pets.
Rare and Rainbow verification also passed with their existing chances/boosts.
The four models were visually checked together; temporary previews were removed.
The full local gate passes 31 tests, lint and build, then reports the existing
99 new/29 stale type baseline findings under the Cyrillic workspace path.

Source: `C:/Users/userr/Downloads/30 красных петов.blend`.
`source.blend` is a byte-identical backup. The original file was not saved or modified.

`tools/ExportRedPets.py` evaluates the 30 numbered empty roots, including their
mesh and curve descendants. The unrelated puppy, scene floor, lights and cameras
are excluded. Each pet is combined into one mesh, normalized to height 3 with
a bottom-center origin, and placed on a 6-by-5 grid for import. Material colors
are preserved using a shared embedded 256x256 atlas with per-face UVs; the atlas
is also supplied as `red-pets30-colors.png`. Source procedural shaders/normal
mapping are not reproduced by this color atlas.

Output: `red-pets30.fbx`, 30 meshes, 135,388 triangles total, at most 11,120
triangles per pet. `manifest.json` records all 30 stable names and counts.
`preview.png` shows the exported pack. `tools/VerifyRedPetsExport.py` performs
an FBX round trip and checks names, triangle counts, height, UVs and embedded
texture. This verification passed on 2026-10-22.

## Studio import

Studio MCP asset upload was unavailable during the preceding trophy import.
No attempt is made to substitute temporary EditableMesh previews for durable
assets. The steps below describe the completed manual upload workflow and can
be used when importing the pack into another local copy of the same place.

1. In the existing place 106456161057435, open the 3D Importer and choose
   `red-pets30.fbx`.
2. Keep all 30 meshes separate and enable texture import and insertion into
   Workspace. Upload under the experience creator. Retain model name `red-pets30`.
3. Execute `tools/FinalizeRedPetsImport.luau` through Studio MCP in Edit mode.
   It verifies durable MeshIds and color textures, stores 30 separate templates
   in `ServerStorage.ImportedPetPacks.Red30`, disables collisions/touches/queries,
   and retains the unmodified imported scene in
   `ServerStorage.WorldBackups.OriginalRedPets30Import`.
4. Save the place in Studio. Do not publish the game for this import.

The remaining 26 templates stay staged separately. Green, blue and Rainbow
egg mappings are unchanged.
