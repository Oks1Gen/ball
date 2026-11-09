# Magma Egg pet model library

Source reference: [vibrant concept sheet](reference.png).
The five models retain a 2-unit soft cube body/head, tiny four-paw stance,
large glossy eyes, saturated toy colors and broad rarity silhouettes.

| Pet | Editable source and exports |
| --- | --- |
| Coal Mole | [BLEND](models/CoalMole/v1/model/CoalMole.blend), [GLB](models/CoalMole/v1/model/CoalMole.glb), [FBX](models/CoalMole/v1/model/CoalMole.fbx) |
| Cinder Gecko | [BLEND](models/CinderGecko/v1/model/CinderGecko.blend), [GLB](models/CinderGecko/v1/model/CinderGecko.glb), [FBX](models/CinderGecko/v1/model/CinderGecko.fbx) |
| Ember Ram | [BLEND](models/EmberRam/v1/model/EmberRam.blend), [GLB](models/EmberRam/v1/model/EmberRam.glb), [FBX](models/EmberRam/v1/model/EmberRam.fbx) |
| Blaze Bat | [BLEND](models/BlazeBat/v1/model/BlazeBat.blend), [GLB](models/BlazeBat/v1/model/BlazeBat.glb), [FBX](models/BlazeBat/v1/model/BlazeBat.fbx) |
| Inferno Phoenix | [BLEND](models/InfernoPhoenix/v1/model/InfernoPhoenix.blend), [GLB](models/InfernoPhoenix/v1/model/InfernoPhoenix.glb), [FBX](models/InfernoPhoenix/v1/model/InfernoPhoenix.fbx) |

Headless bpy source: [build_magma.py](models/work/build_magma.py). Shared soft
geometry, paint, export and reimport helpers come from the Frost pipeline.
Each model's `work/verification.json` records evaluated triangles, bounds and
independent isolated reimports of all three formats. Source front is -Y, up
is +Z, and the ground is Z=0. Saved BLEND files contain only the asset scene
with packed textures and editable parts; no preview floor, lights or camera.

The concept supplies one view. Hidden rear surfaces are reconstructed as
simple matching toy forms. UI staging mirrors the gecko, ram and phoenix
to keep their asymmetric tails visible in the shared front-left camera.
Authoring geometry is unchanged by that portrait staging.

## Runtime and UI

[UI portraits](../../UI/Pets/magma-egg-v1/manifest.json) are separate 512px RGBA
PNGs generated from the saved front-left render, with identical 24 px black
outlines. [Preview](../../UI/Pets/magma-egg-v1/preview.png).

The third egg retains the `Rare` saved ID and 5,000 Wins price. Four saved pet
IDs map to the replacement visuals; Blaze Bat is an added Epic. Odds use the
same five-pet split as Forest/Frost, 55/30/10/4/1. Existing boost tiers remain.
Roblox uses one mesh and one embedded 1024px atlas per pet. Rojo templates
normalize insertion rotation, white material tint and a 1.8-stud cube body;
they are independent of the temporary imported package copies.

[Asset IDs](../../../RojoTest/assets/pets/magma-v1/roblox-assets.json),
[export checks](../../../RojoTest/assets/pets/magma-v1/verify-exports.json),
[Studio checks](../../../RojoTest/assets/pets/magma-v1/verify-studio.json).
The four previous templates are archived as a file outside the scene.
