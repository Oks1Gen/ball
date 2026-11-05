# Ocean Depths atmosphere

This extends the approved Ocean Depths scenery. No landscape builder is called.
The work remains in the existing Studio-only World2 preview; DEV → Карта opens it.

## Authored objects

`OceanAtmosphereAuthoring.apply(world)` stages and certifies its own dressing before
replacing the previous `OceanAtmosphereRoot` models. Every zone and Lobby own an
`Environment/OceanAtmosphere`; the local distant enclosure belongs to
`FootballCourse/Environment/UnderwaterHorizon` during Play. Existing parts, shops, ground and HD studs
are preserved. Distant columns rest on extensions of the seabed, with unit-matched studs.

- 16 close schools, three fish each, across both sides of the eight locations. Fish keep
  the larger approved size and faster swimming; small groups fit nearer to the player.
- One additional manta follows a certified crossing above Coral Reef. Its visibility
  fades over a 78-second encounter cycle. The existing squid fades through a 94-second
  cycle in Abyssal Trench. Jellyfish send a slow glow wave down their canyon.
- 234 surface-light carriers point to actual visible receiver parts via `Receiver`.
  Runtime overlays attach to those faces, drift in two directions and preserve the
  original stud textures. Overlays are local and are removed during teardown.
- 18 certified open-water plankton pockets and 16 small bubble streams. Their swept
  envelopes are checked against visible scenery regardless of CanQuery. Bubbles start
  at sand/rock surfaces and expire within a clear vertical column.
- 162 distant reef columns, grounded on seabed extensions, with no static background curtains.
  A client-local far enclosure covers holes left by unloaded distant boundaries.

The particle templates were authored through VfxForgeUltra. Their recreatable tree is
`Assets/OceanDepths/Atmosphere/forge-effects.json`. Existing ocean bubble/water textures
are reused; plankton uses the library's circle texture. No upload or generated mesh is needed.

## Runtime

`OceanPreviewController` owns `OceanAtmosphereController` and the existing wildlife
controller. `Core/OceanAtmosphere` provides coherent current, zone crossfade weights,
encounter envelopes and the travelling jellyfish wave. Kelp sway remains inside the
previous certified motion bounds and follows the same current as particles and water.

Effects are local, update at 20 Hz, activate near the camera and honor Effects/ReducedMotion.
The original tropical music is quietly muffled underwater; normal volume/filtering returns
on exit. No camera wobble, full-screen blur or gameplay force is added. The ball corridor
and HUD remain readable. Audio and extra effects stop/restore on world removal.

The controller retains the measured course origin (or derives it from another loaded
field). It continues updating in deep zones and fades out after travel even when
Streaming unloads Field1. The first field is not a permanent client dependency.

The underwater enclosure follows the camera at 700 studs, beyond the ocean fog range.
It keeps the default cloudy sky out of view even if Streaming has unloaded a far wall.
The six old gradient walls and four static depth curtains have been removed. Builders no
longer create them, and the controller has no legacy GUI background toggling. Water-surface ripples move and restore their offsets.

## Audio

`Shared/OceanSoundBank` stores the six roles and measured lengths. All candidates are free
Creator Store audio and passed Studio IsLoaded/TimeLength checks. Metadata, attribution,
asset links and measurements are in `Assets/OceanDepths/Atmosphere/audio-manifest.json`.

A quiet water bed, deeper ambience, positional bubble/current sounds, wreck creaks and
vent rumble blend between locations. Spatial sources follow the existing sound setting
through `SkippingSounds`; music still follows the existing music setting. Sounds with
zero contribution stop rather than accumulating voices. No new remotes or save fields exist.

## Rebuild and checks

Create the Forge template pack from its JSON first. Fresh-require the authoring module
and call `.apply(workspace.Map.World2)` in Studio Edit. Rebuild wildlife first if both
need rebuilding; then apply atmosphere. Do not run the landscape generators for this work.
Check all route certificates and `tools/VerifyOceanWildlifeMotion.luau`, then inspect Play
from the normal camera and along the banks. `node RojoTest/tools/check.mjs` covers pure
crossfade/envelope tests, formatting, lint, assembly and types. Play evidence and limits
belong in `docs/verification.md`.
