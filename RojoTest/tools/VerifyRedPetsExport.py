"""Round-trip verification of the FBX prepared for Studio's 3D Importer."""
import bpy
import json
from pathlib import Path

folder = Path(__file__).resolve().parents[1] / "assets" / "pets" / "red30"
manifest = json.loads((folder / "manifest.json").read_text(encoding="utf-8"))
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.fbx(filepath=str(folder / "red-pets30.fbx"))
meshes = [o for o in bpy.data.objects if o.type == "MESH"]
assert len(meshes) == 30, f"Expected 30 meshes, got {len(meshes)}"
for item in manifest["pets"]:
    obj = bpy.data.objects.get(item["id"])
    assert obj is not None and obj.type == "MESH", item["id"]
    obj.data.calc_loop_triangles()
    assert len(obj.data.loop_triangles) == item["triangles"], item["id"]
    assert obj.data.uv_layers.active is not None, "Missing color atlas UVs"
    assert abs(obj.dimensions.z - 3) < 0.001, "Pet height changed in FBX"
    assert len(obj.data.materials) == 1, "Missing atlas material"
    textures = [n.image for n in obj.data.materials[0].node_tree.nodes if n.type == "TEX_IMAGE" and n.image]
    assert textures and textures[0].size[:] == (256, 256), "Missing embedded atlas"
print("RED_PETS_VERIFIED=" + json.dumps({"meshes": len(meshes), "triangles": sum(x["triangles"] for x in manifest["pets"]), "textures": "embedded 256x256 color atlas", "heightStuds": 3}))
