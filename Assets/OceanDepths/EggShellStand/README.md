# Nautilus egg cradle — selected concept 5

The user selected option 5 on 2026-11-05 from `concepts/shell-options-v1.png`.
This is one reusable shell pedestal for Ocean Depths, modelled in Blender from
the selected generated concept. It has a thick continuous nacre basin, twelve
evenly repeated spiral ribs, a central nautilus coil, mirrored side volutes,
an octagonal blue stone foot and finished underside. Front is -Y, sole is Z=0.

`model/nautilus-shell.blend`, `.glb` and `.fbx` contain only the model and its
materials. The egg, character proxy, camera, lights and floor are review aids
and are excluded. Materials use solid Principled colors and geometry for all
visible detail; there are no external texture dependencies.

`work/build_shell.py` creates an isolated scene in the connected Blender without
removing existing scenes. `refine_shell.py` adjusts scroll attachments in place.
`finish_shell.py` runs in a separate background Blender: eight surface/scale
renders, clean ordinary saves, GLB/FBX exports, independent imports, same-light
renders of both imports, bounds checks and source manifold checks.
`work/validation.json` records measured results. Never use scene library-write
for export on this Blender installation; the ordinary-save route is used here.

Verified revision 3: 24 meshes, 11,692 triangles in total; each mesh is below
10,000 triangles. Source and FBX surfaces are closed. GLB material-boundary
splits were welded in an independent verification copy, confirming closed
topology. Bounds and appearance survive both imports. Independent visual
review: 5/5, including repaired continuous rim, reverse side and underside.

The user approved the model and requested replacing the five World2 egg cradles.
A direct smooth GLB import is installed and verified in Edit and PC Play;
`docs/ocean-eggs.md` records placement and checks. The user explicitly authorized
uploading to Dakemo555 and granting use to this game. Model 70791212451135 is
approved; `model/roblox-asset.json` lists the 29 generated MeshParts and restored
colors. Each placed cradle includes two additional mesh pieces for full contact
with the seat. Independent Studio visual review: 4/4. No game publication.
