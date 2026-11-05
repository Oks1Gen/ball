# Ocean eggs — 2026-11-05

The approved Blender set is integrated into World2's existing EggShop. From the
front, left to right: Kelp (Common), Leviathan (Uncommon), Treasure (Rare), Abyss
(Epic), Jelly (Legendary). Keys remain Common, Uncommon, Rare, Rainbow, AdminEgg;
prices, reward pools and premium-product configuration retain their existing values.

`shared/OceanEggCatalog` owns the world-specific display mapping. `server/OceanEggStyle`
reuses the existing curved stand, places Rare in the centre and Jelly at the last
seat, preserves interaction anchors, applies captions and tags each visual for
`EggDisplay`. WorldService reapplies this styling on startup. The old shop snapshot
is in `ServerStorage.WorldBackups.BeforeOceanEggs_20261105`.

Exact Blender triangles were transferred through Rojo as thin native surfaces,
then consolidated with GeometryService into 301 persistent CSG components; all
301 unions succeeded. Final templates: `ServerStorage.Assets.Eggs.Ocean`.
Source mapping: `ServerStorage.OceanEggTemplates`; source file and authoring scripts
are under `Assets/OceanDepths/Eggs/work`. Jelly retains 30 translucent components;
neon markings remain opaque for readability. Runtime visual height is 7.5 studs,
matching the current world's scale, with a 0.06-stud resting clearance.

`EggDisplay` supplies the existing client levitation, slight turn, animated
highlight and orbiting emitters. `EggAura` adds gold/kelp rings, crown glints,
treasure sparkles, cyan abyss spirals and lilac/cyan jelly pulses. VfxForgeUltra
authored the additional themed mote templates in `ReplicatedStorage.OceanEggVFX`;
the display controller clones them and gates them with the other effects.
Egg preview panels, ordinary egg inventory titles/tabs and prompt labels use the
Ocean mapping; Football City's labels retain their own catalog.

## Verification

- PC Play: all five models move over time; all five outlines activate nearby.
- Model order, seats, names and rarities checked in Edit and Play.
- All four normal egg approach raycasts find valid ground after rearrangement.
- Jelly's translucent parts survive native import and Play.
- StyLua, Selene, 126 Lune tests, five verification tests, Rojo build and typecheck pass.
- Current Studio player: Dakemo555, UserId 11789507527, confirmed through MCP.
- No purchase or reward mutation was performed for this visual integration.
- Stop Play after inspection. Save the Studio place to retain the optimized CSG
  templates, installed models and VfxForge templates. No game publication occurred.

The separate Premium Egg / Coming Soon decorative station is unchanged.
New ocean pet models and developer-product setup remain in the backlog.

## Nautilus shell cradles — 2026-11-05

The user selected shell concept 5. The Blender source, reference sheet and
exports live in `Assets/OceanDepths/EggShellStand`. The smooth GLB is uploaded as
Model **70791212451135**, owned by **Dakemo555 (11789507527)**, with explicit user
consent. One successful upload created the Model and 29 mesh dependencies; no
image assets were created. Use access, including dependencies, was granted only
to universe **10770268214**. The source Model passed moderation.

Template: `ServerStorage.Assets.EggStands.NautilusShell`. Blender's 24 source
meshes become 29 MeshParts because the importer splits material groups. All
materials arrived grey; source sRGB colors were restored from the GLB material
manifest. Source bounds, upright orientation and the paired volutes were checked.
The repaired template and scene copies are independent local copies; reinserting
the cloud package would need the same color and placement repairs.

`server/OceanEggCradle` fits one model into each of the five existing stations.
The shell has 31 MeshParts including a two-piece shallow contact foot, faces the player,
follows the seat yaw and stays stationary. The egg and caption are raised above
its rim. Old shell models are retired outside Workspace in
`ServerStorage.WorldBackups.BeforeNautilusShells_20261105`.

Verification: 316 static stand/interaction parts retain their transforms, sizes,
visibility and physics. Reapplying causes no drift. All 45 sole probes find a
visible seat surface with no gap. PC Play confirms five stationary shells, five
floating eggs and five active outlines; themed effects remain active. No hatch,
purchase or profile mutation was triggered. Code gate passes (126 Lune tests,
five gate tests, formatting, lint, build and typecheck).

Client preload of the five actual shell Models succeeds for all 155 MeshPart
references. Independent visual review: 4/4, including the central spiral in an
isolated Studio inspection copy (removed afterward). Update Log opens and closes
on PC with the current text and confirmed author. Play is stopped after checks.

The earlier exact native CSG source is retained outside Workspace as
`ServerStorage.Assets.EggStands.NautilusShellNative`; the original imported
package is `NautilusShellImported`. `tools/ImportNautilusShell.luau` and
`work/geometry.json` can reproduce the native source without a temporary Rojo
mapping or HTTP server. `model/roblox-asset.json` records the final mesh IDs and
colors. Save the Studio place to retain the repaired manual assets. The game
itself was not published.
