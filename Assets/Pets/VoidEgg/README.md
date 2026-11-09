# Void Egg models

[Original concept](reference.png) · [Front renders](models/work/front-three-quarter-contact.png) · [Rear renders](models/work/rear-three-quarter-contact.png)

| Pet | Rarity | Editable source and exports |
| --- | --- | --- |
| Dusk Moth | Common | [BLEND](models/DuskMoth/v1/model/DuskMoth.blend) · [GLB](models/DuskMoth/v1/model/DuskMoth.glb) · [FBX](models/DuskMoth/v1/model/DuskMoth.fbx) |
| Shadow Kitten | Uncommon | [BLEND](models/ShadowKitten/v1/model/ShadowKitten.blend) · [GLB](models/ShadowKitten/v1/model/ShadowKitten.glb) · [FBX](models/ShadowKitten/v1/model/ShadowKitten.fbx) |
| Orbit Axolotl | Rare | [BLEND](models/OrbitAxolotl/v1/model/OrbitAxolotl.blend) · [GLB](models/OrbitAxolotl/v1/model/OrbitAxolotl.glb) · [FBX](models/OrbitAxolotl/v1/model/OrbitAxolotl.fbx) |
| Rift Wyrm | Legendary | [BLEND](models/RiftWyrm/v1/model/RiftWyrm.blend) · [GLB](models/RiftWyrm/v1/model/RiftWyrm.glb) · [FBX](models/RiftWyrm/v1/model/RiftWyrm.fbx) |
| Singularity | Secret | [BLEND](models/Singularity/v1/model/Singularity.blend) · [GLB](models/Singularity/v1/model/Singularity.glb) · [FBX](models/Singularity/v1/model/Singularity.fbx) |

[Headless Blender source](models/work/build_void.py) uses a 2-unit body with a
ground pivot, front at −Y and up at +Z. The reference shows one side. The
unseen surfaces use simple forms that match the visible colors and silhouette.
Singularity's cyan edges and violet orbit are textured. Each Studio export is
one mesh with an embedded 1024 px color atlas.

The [UI portraits](../../UI/Pets/void-egg-v1/preview.png) use the same 512 px
canvas and 24 px black outline as the earlier eggs. The
[portrait manifest](../../UI/Pets/void-egg-v1/manifest.json) records the
Blender views, ImageGen inputs and prompts.

The fourth egg uses the saved ID `Rainbow` and the same pool as Abyss Egg.
Five saved pet IDs point to the new visuals, including `EclipseCat` for
Singularity. [Roblox asset IDs](../../../RojoTest/assets/pets/void-v1/roblox-assets.json) ·
[Studio checks](../../../RojoTest/assets/pets/void-v1/verify-studio.json) ·
[Export checks](../../../RojoTest/assets/pets/void-v1/verify-exports.json)
