# Ocean Depths · Location Kit

Built 2026-11-05 for the seven approved locations after Coral Reef.
Selected references and Studio overview/ground-level captures remain in each location folder.

- `location-kit.blend`: editable Blender source. `build-location-kit.py` recreates it headlessly.
- `location-kit.glb` and `.fbx`: seven species, 4,406 triangles total; both reimported and checked.
- `location-kit-geometry.json`: coloured triangle groups for permanent Studio CSG import.
- `kit-{front,back,top,underside}.png`: model renders; `validation.json` and `roundtrip-validation.json`: measured checks.
- `native-architecture.rbxmx`: seven native Studio models: wreck, anchor, column, stepped temple, gateway, chimney, tube-worm colony. Editable Parts and original HD textures; no cloud upload required.
- `native-architecture.json`: typed source for the native pack. Run `lune run Assets/OceanDepths/LocationKit/write-native-pack.luau` from the repository root to regenerate the XML. The writer verifies a model round trip.
- `effects.json`: VfxForge-authored mineral plume, sun shaft and bubble spring templates. Restore in Studio Edit with `RojoTest/tools/ImportOceanEffects.luau` and decoded JSON. Chimney effects are separate from the architecture pack.

Studio storage: `ServerStorage.Assets.OceanDepths.LocationKit`, `.Architecture`, `.Effects`.
Sea creatures reuse the existing `.SeaLife` pack. The builder lives in
`RojoTest/src/server/OceanLocationKit.luau` and `OceanCourseLocations.luau`.
See `docs/ocean-depths.md` for fresh-module authoring, support checks and preview limitations.

HD studs use the established `rbxassetid://88156646156237` map, repeat 4.8,
four studs per tile (1.2 pitch), equal U/V and zero offsets. Small trim and
organic sea creatures intentionally have smooth faces.
