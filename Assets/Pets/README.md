# Pet modeling reference library

Saved in the Ball project on 2026-11-09 for future 3D modeling. All reference
PNGs live inside this directory, not only in chat, temporary files or generated
image storage. Exact ImageGen prompts and provenance are retained beside sheets.
`catalog.json` indexes egg/species names, draft status and preferred sheet paths.

## Current sheets — use these for modeling

| World | Egg | Reference sheet | Status |
| --- | --- | --- | --- |
| World1 | Forest | [Five pets v4](ForestEgg/concepts-v4/forest-egg-five-pets-v4.png) | User approved after cube/simplicity revisions and fifth pet added. |
| World1 | Frost | [User reference](FrostEgg/reference.png) | Five models and portraits integrated in Studio with the brighter palette. |
| World1 | Magma | [Vibrant reference](MagmaEgg/reference.png) | Five models and transparent portraits integrated in Studio. |
| World1 | Void | [User reference](VoidEgg/reference.png) | Five models and transparent portraits integrated in Studio. |
| World1 | Solar Crown | [User reference](SolarCrownEgg/reference.png) | Five models and transparent portraits integrated in Studio. |
| World2 | Kelp | [Five pets v2](World2/concepts-v2/kelp-egg-five-pets-v2.png) | Saturated palette; draft for user corrections. |
| World2 | Leviathan | [Five pets v2](World2/concepts-v2/leviathan-egg-five-pets-v2.png) | Saturated palette; draft for user corrections. |
| World2 | Treasure | [Five pets v3](World2/concepts-v3/treasure-egg-five-pets-v3.png) | Fifth pet replaced with Ruby Koi; draft for user corrections. |
| World2 | Abyss | [Five pets v2](World2/concepts-v2/abyss-egg-five-pets-v2.png) | Saturated palette; draft for user corrections. |
| World2 | Jelly | [Five pets v2](World2/concepts-v2/jelly-egg-five-pets-v2.png) | Saturated jelly palette; draft for user corrections. |

## Shared brief for future 3D models

- Five pets per egg. Species follow the egg's theme, with no football requirement.
- Every pet has one square cube as the combined head/body: flat front, top and
  sides, soft small corner bevels. Do not turn it into a sphere, separate head,
  long neck or organic animal torso. Ears, tails, horns and shells attach to it.
- Keep the approved soft toy-like look, large glossy expressive eyes, small
  mouth, subtle blush and tiny feet/fins/tentacle feet.
- Use a few broad recognizable shapes. No excess foliage, flower collars,
  ornate jewelry or small repeated detail. Rare pets distinguish themselves
  through silhouette/material accents, not only recoloring or particle effects.
- Sheet names and rarity captions are reference labels, not parts of the mesh.
  Artwork shadows, highlight blobs and panel backgrounds are not model geometry.
- Model appendages from the silhouettes but verify cube planes from front,
  side, rear and above; these are concept views, not complete turnarounds.
- Semi-transparent Jelly bodies still need clearly readable cube planes/faces.
- World2 colors must be bright and saturated per the user's latest correction;
  use v2 sheets except Treasure, whose latest sheet is v3 (Ruby Koi replaces
  rejected Treasure Mimic). Earlier pastel v1 sheets are history, not the modeling target.
- The catalog is a design proposal. It does not grant permission to change paid
  products, prices, production probabilities, saved pet IDs or publish the game.

## Modeled assets

- [Clover Bunny v1](ForestEgg/models/CloverBunny/v1/README.md): editable Blender,
  GLB and FBX, actual renders and reimport validation. The asset is left in the
  user's open Blender. User review/Studio integration remain separate.

- [Acorn Squirrel v1](ForestEgg/models/AcornSquirrel/v1/README.md) includes the editable Blender file, GLB and FBX exports, and front and rear renders from background Blender.

The remaining three Forest Egg models use the same 2-unit rounded cube, ground
pivot and −Y front. Their rear geometry continues the shapes and palette from
the single concept view. Each format passed an isolated Blender reimport.

| Forest Egg pet | Model files | Blender verification |
| --- | --- | --- |
| Bloom Fox | [BLEND](ForestEgg/models/BloomFox/v1/model/BloomFox.blend) · [GLB](ForestEgg/models/BloomFox/v1/model/BloomFox.glb) · [FBX](ForestEgg/models/BloomFox/v1/model/BloomFox.fbx) | [7,872 triangles](ForestEgg/models/BloomFox/v1/work/verification.json) |
| Moon Owl | [BLEND](ForestEgg/models/MoonOwl/v1/model/MoonOwl.blend) · [GLB](ForestEgg/models/MoonOwl/v1/model/MoonOwl.glb) · [FBX](ForestEgg/models/MoonOwl/v1/model/MoonOwl.fbx) | [7,652 triangles](ForestEgg/models/MoonOwl/v1/work/verification.json) |
| Grove Guardian | [BLEND](ForestEgg/models/GroveGuardian/v1/model/GroveGuardian.blend) · [GLB](ForestEgg/models/GroveGuardian/v1/model/GroveGuardian.glb) · [FBX](ForestEgg/models/GroveGuardian/v1/model/GroveGuardian.fbx) | [9,392 triangles](ForestEgg/models/GroveGuardian/v1/work/verification.json) |

[Front renders](ForestEgg/models/work/forest-egg-front.png) ·
[Rear renders](ForestEgg/models/work/forest-egg-rear.png) ·
[Headless build script](ForestEgg/models/work/build_remaining.py)

The [Forest Egg UI portraits](../UI/Pets/forest-egg-v1/manifest.json) cover
all five pets. Each is an RGBA PNG with a common 24 px black contour, based
on a front-left Blender render. Clover Bunny and Acorn Squirrel also replace
the former mushroom and cake visuals in the game, preserving saved pet IDs.

[Frost Egg](FrostEgg/README.md) has five editable models, outlined UI portraits,
and verified Roblox imports. The brighter palette follows the latest request.

[Magma Egg](MagmaEgg/README.md) has five editable models and 24 px outlined
portraits. All replace the third egg's visuals and UI. Saved Shark, CloudBird,
AngelCat and IceCat IDs are retained; BlazeBat is the new Epic slot.

[Void Egg](VoidEgg/README.md) has five editable models and 24 px outlined
portraits. The fourth egg retains its five saved IDs and includes Singularity
with a 0.05% Secret chance.

[Solar Crown Egg](SolarCrownEgg/README.md) has five editable models and
24 px outlined portraits. The fifth stand in Football City opens for Wins.

## Original references and older drafts

Original three user-supplied bunny/cat style images:
`ForestEgg/concepts-v1/references/`. Forest v1-v3 are retained for history;
they are superseded by v4 and should not be used as the final modeling brief.
World1 details/prompts: `World1/remaining-eggs-v1/`.
World2 current details/edit prompts: `World2/concepts-v2/`. Initial generation
prompts and superseded pastel sheets: `World2/concepts-v1/`.
Treasure's current replacement/edit prompt: `World2/concepts-v3/`.

PNG assets are covered by the repository's Git LFS rules. `.gitignore` now
allows `Assets/Pets/` so these references can join a future authorized backup.
