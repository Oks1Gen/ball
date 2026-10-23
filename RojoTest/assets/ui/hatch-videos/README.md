# Hatch animation comparison

The studded pet-result plate was removed. HatchStage.luau renders the result
on transparent CanvasGroups: pet model, name, rarity and multiplier, without
Surface backgrounds, outlines or shadows. The Continue button retains the
game's established button styling.

Three source-backed variants are implemented:

1. Bounce/shake with a ring-and-spark burst, reveal at 1.45 seconds.
2. Three rotating orbit rings with a floating egg, reveal at 1.85 seconds.
3. Sequential glowing crack segments and angular fragments, reveal at 2.05 seconds.

Each supports one or three server-confirmed pets; triple reveals are staggered
by 0.09 seconds. The client never rolls or grants pets. Reduced motion displays
the completed result immediately. Connections are disconnected on completion
and unmount. Egg geometry is cloned from the selected world's ImportedVisual
when available, with a colored egg fallback for unloaded scenery.

The internal Variant prop / PreviewVariant attribute selects the comparison;
default is 3 (glowing cracks and fragments) for every egg and world, for both
single and triple hatches. PreviewTime is an offline capture control, not a player setting.

Recording completed on 2026-10-22 with Studio visible: all 44 timeline captures
were saved for each of the three variants. The MP4 previews use the actual
HatchStage component and imported game assets, with the same camera and pet
for comparison. Triple-pet layout was also checked in Studio. The recording-only
GUI, camera override, temporary blur and prompt suppression were cleaned up;
the player's regular UI and camera were restored. Recording grants no pets.

tools/EncodeHatchVideos.py converts 44 Studio timeline captures per variant
at 12 samples/second into local 1280x720 MP4 previews with 30fps interpolation.
It requires imageio-ffmpeg installed under .tools/video-runtime and verifies
that all 44 captures exist before encoding. It does not capture desktop UI.

Checks: formatting, Selene, 31 tests, build, sourcemap and verification scripts
passed. Through an ASCII path the type gate has 612 known findings, one existing
absolute-path Theme finding, and 10 stale entries after old errors were removed.
The baseline was not rewritten.
