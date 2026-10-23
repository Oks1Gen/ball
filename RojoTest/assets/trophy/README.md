# Golden trophy import

## Current state: persistent import completed

On 2026-10-22 the user imported golden-trophy.fbx through Studio's 3D Importer.
All 28 imported MeshParts have persistent rbxassetid MeshIds. The narrow,
idempotent tools/FinalizeTrophyImport.luau script replaced the temporary
Workspace.ImportedTrophy with those meshes, restored gold/Metal styling,
disabled collisions/touches/queries, and preserved the current position,
rotation and dimensions (height 40, base Y=20). PendingMeshUpload is now false;
DurableMeshVersion is 1. The mesh IDs and local transforms are recorded in
mesh-assets.json. The broken preview and unmodified import are retained in
ServerStorage.WorldBackups.BeforePersistentTrophy_20261022 and
ServerStorage.WorldBackups.OriginalTrophyFBX_20261022 respectively.
The Edit viewport and mesh IDs were verified. Save the place in Studio to
retain this scene change; the game was not published. The notes below describe
the earlier temporary preview and its recovery, not the current asset status.

## Original preview

Source: `C:/Users/userr/Downloads/кубак.blend` (unchanged).
`golden-trophy.fbx` exports the 28 trophy objects without the studio floor,
camera or lights, normalized to height 8 and a bottom-center origin.
There are 1,114 nondegenerate triangles, using the source's two assigned
materials (Royal gold and Golden highlights). 22 degenerate source triangles
are omitted. `trophy-geometry.json` preserves positions and corner normals for
the exact Studio MCP geometry transfer; Blender Z-up becomes Roblox Y-up.

`tools/ExportTrophy.py` produces both files. `tools/ImportTrophy.luau` consumes
the data transferred to `_G.TrophyImportData` in batches through Studio MCP.
It creates only a local EditableMesh preview named `Workspace.ImportedTrophy`
at (25,20.26,220), with height 8, no collisions/touches/queries, metal material,
and the source colors converted from linear RGB to sRGB. Two material meshes
share the same geometry origin. Base height, dimensions and an Edit screenshot
were checked. No existing map geometry was edited. Play was not run.

Persistent Roblox mesh upload is pending explicit user approval. An attempted
upload was rejected by automatic review before execution. No Roblox assets
were uploaded. The preview has `PendingMeshUpload=true`; it must not be treated
as a saved, published mesh asset. Retain FBX/JSON for recovery. Once approved,
upload the two EditableMeshes to the game creator's Roblox inventory and
replace the preview content with the resulting durable mesh asset IDs.

## Recovery on 2026-10-22

After reopening the place, both trophy MeshParts had empty MeshId and
MeshContent (SourceType=None), so Roblox rendered their bounding boxes.
The original 1,114 triangles were restored from trophy-geometry.json in Edit,
preserving the current pivot, rotation, scale 5, dimensions and non-colliding
properties. The previous model is backed up under
ServerStorage.WorldBackups.BeforeTrophyMeshRecovery_20261022.

The user explicitly approved uploading the two meshes. However, the Studio MCP
AssetService:CreateAssetAsync call failed with
"CreateAssetAsync and CreateAssetVersionAsync are not available yet".
No assets were uploaded and the current recovery is still session-only.
To finish, manually import golden-trophy.fbx using Studio's 3D Importer with
the experience creator as asset owner, insert the imported model and retain it
for replacing the temporary trophy geometry. Do not publish or rebuild the map.
Until durable mesh IDs have been assigned, reopening Studio can lose the preview.

The user subsequently requested fivefold enlargement and placement on the grass
behind the low-tier pitches. `tools/PlaceTrophyBehindLanes.luau` sets the existing
preview to scale 5 (height 40), base (139,20,194.600037), with its front facing
the lanes (-X). Nine ground samples were inspected before placement; the base,
dimensions and overview were checked afterward. Original trophy state is in
`ServerStorage.WorldBackups.BeforeTrophyPlacement_20261020`. Upload remains pending.
