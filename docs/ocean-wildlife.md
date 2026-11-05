# Ocean Depths: animated wildlife

Status: implemented and verified, 2026-11-05. This is cosmetic Studio-preview work;
World2 travel/progression remain separate. Preserve every authored landscape and stud texture.

## Agreed behaviour

- Reuse approved fish/manta silhouettes and colours; author flexible models and animation in Blender.
- Schools follow smooth routes; each fish changes its position within the group, follows neighbours,
  maintains separation and has its own tail phase. No rigid whole-school translation.
- Mantas have travelling wing motion, trailing tails, glides and banked turns.
- Jellyfish pulse and trail flexible tentacles. Give seahorses, anglerfish and squid distinct motion.
- Populate Lobby and all eight locations, with different density and species by depth.
- No animal or animated appendage may pass through visible scenery, other animals or animated foliage.
  Navigation must include non-queryable decorative geometry. Route checks include full animation envelopes.
- Keep the playable pitch/ball corridor clear. No physics impulses or gameplay effects from decorative fauna.

## Implementation sequence

1. Export and import one true skinned fish. Check bones, colours, orientation and deformation in Studio.
2. Blender pack with rigged fish, silver sprat, manta, jellyfish, seahorse, anglerfish and squid;
   source, FBX, GLB, palette images and motion recipes stay in Assets/OceanDepths/AnimatedSeaLife.
3. Safe authored routes on both sides; navigation stores conservative obstacle bounds independently of CanQuery.
4. One client controller owns movement and bones; remove conflicting preview motion for converted fauna.
5. Verify swept motion, initial overlap, pair separation, all route cycles, low frame rates and streaming lifecycle.
6. PC Play and screenshots across all zones; update verification and player-facing log only after validation.

## Distribution

Coral Reef: yellow/blue tropical schools, clownfish near colonies, manta.
Kelp Forest: small cream schools in clear water, hovering golden seahorses.
Sunken Fleet: blue and silver schools beside both wrecks, never through unverified holes.
Lost City: silver schools above/beside mosaics and columns, staggered routes.
Jellyfish Canyon: pink and blue pulsing jellyfish, sparse blue fish.
Vent Fields: sparse silver fish outside plume envelopes.
Abyssal Trench: slow anglerfish, distant squid, sparse deep-blue school.
Pearl Grotto: small light-coloured schools along the mint banks, outside shell motion.

## Final implementation

`OceanWildlifeAuthoring` is an Edit-only targeted migration. It certifies smooth elliptical route
tubes against 30,249 oriented visible bounds, irrespective of CanQuery. Kelp sway and shell movement
have extra margins. The full deformed radius, school extent, curve sagitta and inter-route reservations
are included. Pitch geometry, banks, buildings, rocks, plants and HD studs are preserved.

There are 30 schools (262 fish) and 28 individual creatures on 58 routes. The eleven templates are
Clownfish, BlueTang, Butterflyfish, SilverSprat, YellowTang, MantaRay, ReefJellyfish, MoonJellyfish,
GoldenSeahorse, Anglerfish and AbyssSquid. Each animal is one persistent uploaded skinned MeshPart.
The source library, individual FBX/GLB exports, palettes, IDs, renders and rebuild instructions are
in `Assets/OceanDepths/AnimatedSeaLife/README.md`.

`OceanWildlifeController` owns both root motion and bone poses, called by `OceanPreviewController`.
Each fish steers toward changing positions, aligns with neighbours and separates from them. A swept
relative-motion check rejects unsafe steps, including initial overlap. Adaptive initial spacing fits
the largest animation envelope. School members stay inside the certified tube. Routes avoid each
other, so separate schools/creatures cannot intersect. Atomic Model streaming keeps each school whole.

Near-camera swimming updates every frame, with integration steps no larger than 1/30 s and a 0.12 s
catch-up cap. Farther groups update at 20 Hz; groups beyond 460 studs pause their own clocks and resume
without skipping through scenery. Lighting blends between the existing eight presets over about a second.
The original generic motion no longer owns converted fauna. No server per-fish replication or physical
collisions are introduced. This remains Studio-only with the existing World2 preview guard.

## Verified evidence and limits

- Blender: 22/22 GLB/FBX round trips, normalized weights, 31 deformed poses for each of 11 species,
  conservative bounds and closed animation cycles. Four complementary render views per species.
- Edit: 58/58 route certificates; 60 seconds across all groups, 104,400 integration steps,
  only two rejected unsafe steps, minimum sphere-envelope gap 0.2700 studs, 261/262 school members
  changed their local position. The school-envelope ratio stayed at 1 within float precision.
- Preservation: all 83,038 original parts remain; zero changes to surviving Workspace geometry/physics.
  Exactly 630 old fauna parts moved into the archive outside Workspace; none were deleted.
- PC Play: all eight zones photographed; body/wing/tentacle poses observed, restored World1 lighting,
  no new wildlife errors, updated Update Log opened, expanded and closed with confirmed Dakemo555 credit.
- Full check: 120 unit tests, five gate tests, Rojo build, 243 source requires and zero new type errors.
  Mobile/release profiling and live World2 travel remain outside this task.

The certificates apply to the current authored scenery and its recorded movement envelopes. After
moving landscape objects or changing an animal's shape/amplitude, recertify routes before keeping the
change. Do not rely on ordinary CanQuery-based rays to find decorative obstacles.

## Visibility pass · 2026-11-05

The user requested fish twice as large and swimming twice as fast. This means model size,
not doubling the population. All 262 schooling fish and six anglerfish now have 2× scene
scale, 2× route speed and 2× skeletal motion frequency. Mantas, jellyfish, seahorses and
squid retain their dimensions and timing. Imported templates and Blender source stay at
their reusable unit scale; there is no new upload or duplicate asset pack.

`OceanWildlifeAuthoring.enlargeFish(world)` is an Edit-only, targeted and idempotent
migration. It plans all 36 fish routes before touching the scene, doubles member offsets
and school envelopes, and certifies neighbouring lanes where the larger animals need room.
Twenty-nine route centres moved (at most 80 studs); all 58 final routes pass certification
against 30,249 visible bounds. No landscape parts or stud textures changed. Repeating the
migration changes no route origin, speed or scale. A full `.apply` ends with this same pass.

`MemberMotionScale=2` scales the school steering space; `MotionRate=2` scales steering
response, skeletal frequency and integration frequency. Route speed remains an authored
attribute and is explicitly doubled once. Pair separation and alignment distances scale
with the fish. Fish integrate at steps no larger than 1/60 s (other creatures at 1/30 s).
The 60-second whole-world test completed 169,200 integration steps, rejected two unsafe
steps, maintained a minimum deformation-envelope gap of 0.5401 studs, and reshuffled all
262 schooling fish. Runtime movement and changing bone poses were observed in Play.

## Atmosphere follow-up

The six atmosphere proposals have been implemented in the Studio preview. See
[ocean-atmosphere.md](ocean-atmosphere.md) for close schools, soundscape, caustics,
currents/particles, wildlife encounters, depth haze and distant reefs. The original
wildlife and landscape are retained; the follow-up adds its own certified routes.
