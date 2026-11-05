# Ocean Depths eggs — Blender review, 2026-11-05

The user selected concept numbers **3, 10, 4, 8, 6**, in that exact order of
increasing rarity, approved the Blender models, and authorized their World2
integration on 2026-11-05. See `docs/ocean-eggs.md` for Studio integration,
captions, levitation, outlines and thematic effects. Prices and reward pools
retain their existing values; no game publication occurred.

| Left to right | Model | Rarity | Reference | Construction |
| --- | --- | --- | --- | --- |
| 1 | Kelp | Common | 3 | Teal egg, three repeating amber-leaf spirals, sand cuff |
| 2 | Leviathan | Uncommon | 10 | Teal armor, gold scales, six ivory horns and aqua gems |
| 3 | Treasure | Rare | 4 | Navy shell, six gold ribs, three hoops, six gemstone/barnacle groups |
| 4 | Abyss | Epic | 8 | Indigo armor, six repeated sectors with cyan seams, diamonds and fins |
| 5 | Jelly | Legendary | 6 | Translucent lilac shell, inner pearl, three cyan waves, twelve tendrils |

The decorative patterns continue around the entire body, including the back.
All five undersides have modeled concentric construction seals; Leviathan and
Abyss additionally have six repeated lower plates and radial ribs. Gold, teal,
navy, indigo, lilac, ivory and cyan come from the selected concept board.
The reference is preserved in `work/reference.png`.

## Review and source

- `work/ocean-eggs-presentation.blend`: the review scene, with the five eggs in
  a row, camera, neutral floor and studio lights. The original Blender scene is
  preserved; its pre-task snapshot is `work/session-before-eggs.blend`.
- `model/ocean-eggs-lineup.blend`: clean five-egg source, without the review stage.
- `model/01_Common_Kelp.*` through `model/05_Legendary_Jelly.*`: individual clean
  BLEND, GLB and FBX files, with a base-centered origin and no cameras or lights.
- `work/build_eggs.py`: deterministic authoring script, run through the connected
  Blender MCP. It replaces only its own named authoring scene.
- `work/render_checks.py`: front, right, back, left, top, underside and approximate
  block-character scale renders. Rotation checks retain the lineup order.
- `work/export_stable.py`: isolated export and independent GLB/FBX reimport checks,
  followed by reopening every clean individual BLEND file.
- `work/verify_render_exports.py`: actual GLB/FBX import renders under the same
  camera and studio lights. `material-roundtrip.json` confirms that both preserve
  Jelly's shader alpha; GLB additionally preserves transmission.
- `work/validation.json`, `work/export-validation.json`: measured geometry and
  interchange results.

Blender axes: X right, -Y front, Z up. Body height is 4.63 authoring units;
Leviathan's horns extend above it. A future Studio integration can scale a model
to its stand's target height. The character-scale image uses a 2.55-unit block
proxy, approximately the ratio of a 5.5-stud character beside a 10-stud egg.

The first pass was authored in the connected Blender. After the interactive
connection stopped responding, the final refinements were completed headlessly
from the saved review scene. The final files and renders are the revised version.
The final presentation was reopened in an interactive Blender and confirmed
through MCP. The export uses normal saves in an isolated background process:
writing a copied Scene with `bpy.data.libraries.write` crashed this Blender 5.2.3
session and its background reproduction, so that export path was removed.

Jelly uses Principled alpha and transmission in Blender. GLB can carry these
properties; FBX preserves supported base color/opacity but does not reproduce
the full transmission shader. Matching the translucent appearance in Roblox
requires a separate Studio material/rendering check. This task stops at Blender
review as initially requested; the subsequently authorized Studio integration
uses persistent native CSG and preserves Jelly's opacity. No cloud asset upload
or game publication is included.
