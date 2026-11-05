# Sync conflict resolution · 2026-11-05

Status: completed. The user explicitly authorized the backup commit/push. Commit
`f8ba402b3019596acb04074ea8ccb7235582bc67` was successfully pushed to `origin/main`
before deleting the 42 reviewed copies. No source or authored scene was rebuilt.

Recovery ZIP: `Assets/OceanDepths/ConflictRecovery/2026-11-05-sync-conflicts.zip`
(1,546,942 bytes), stored through Git LFS. It contains all 42 copies, all 19 original
files at review time, and `conflict-inventory.json` with their SHA-256 hashes.
The ZIP was reopened, CRC-checked and compared with every inventoried hash.
Each deletion used an exact resolved path inside this repository and rechecked the
copy's hash against the ZIP. All 19 working originals remained byte-identical across
the deletion step. A final `rg --files -g '*.conflict*'` returned no visible copies.

42 conflict copies cover 19 originals: 14 byte-identical and 28 different. The current originals retain the final fish size/speed, safe route bounds, atmosphere, corrected rigs and full release history. Copies contain earlier revisions; no unique current feature needs merging. All copies and originals are preserved byte-for-byte in a verified ZIP with a SHA-256 inventory.

## Decisions

| Original | Copies | Resolution |
|---|---:|---|
| `Assets/OceanDepths/AnimatedSeaLife/AbyssSquid.fbx` | 2 | Keep current corrected rig/export; preserve old binary in the recovery ZIP. |
| `Assets/OceanDepths/AnimatedSeaLife/AbyssSquid.glb` | 2 | Keep current corrected rig/export; preserve old binary in the recovery ZIP. |
| `Assets/OceanDepths/AnimatedSeaLife/Anglerfish.fbx` | 2 | Keep current corrected rig/export; preserve old binary in the recovery ZIP. |
| `Assets/OceanDepths/AnimatedSeaLife/Anglerfish.glb` | 2 | Keep current corrected rig/export; preserve old binary in the recovery ZIP. |
| `Assets/OceanDepths/AnimatedSeaLife/README.md` | 2 | Keep current completed implementation and verification documentation. |
| `Assets/OceanDepths/AnimatedSeaLife/YellowTang.fbx` | 2 | Keep current corrected rig/export; preserve old binary in the recovery ZIP. |
| `Assets/OceanDepths/AnimatedSeaLife/YellowTang.glb` | 2 | Keep current corrected rig/export; preserve old binary in the recovery ZIP. |
| `Assets/OceanDepths/AnimatedSeaLife/animated-wildlife.blend` | 2 | Keep current corrected rig/export; preserve old binary in the recovery ZIP. |
| `Assets/OceanDepths/AnimatedSeaLife/build.py` | 2 | Keep stronger corrected YellowTang tail deformation. |
| `Assets/OceanDepths/AnimatedSeaLife/rig-manifest.json` | 2 | Keep eleven final species, updated YellowTang/Anglerfish rigs and final uploaded IDs. |
| `Assets/OceanDepths/AnimatedSeaLife/roblox-assets.json` | 2 | Keep eleven final species, updated YellowTang/Anglerfish rigs and final uploaded IDs. |
| `RojoTest/src/client/Controllers/OceanWildlifeController.luau` | 4 | Keep final scaled steering, safe integration, shared jelly wave clock and atmosphere. |
| `RojoTest/src/client/Modules/UpdateLog.luau` | 4 | Keep complete current releases and named player credits; copies predate recent releases. |
| `RojoTest/src/server/OceanWildlifeAuthoring.luau` | 2 | Keep 2x migration, neighbouring safe-origin search and ambient route exclusion. |
| `RojoTest/src/shared/Core/OceanSwimming.luau` | 2 | Keep tighter certified school envelope; old copy uses wider offsets. |
| `RojoTest/tools/VerifyOceanWildlifeMotion.luau` | 2 | Keep integration scaled with fish motion rate. |
| `docs/README.md` | 2 | Keep current completed implementation and verification documentation. |
| `docs/ocean-wildlife.md` | 2 | Keep current completed implementation and verification documentation. |
| `docs/verification.md` | 2 | Keep current completed implementation and verification documentation. |
