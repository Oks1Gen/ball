"""Write the final pack: one textured .glb and .fbx per ball, colours from roblox/atlas.png.

Run inside Blender after export_roblox.py, which builds the per-ball meshes and the atlas. This
script repeats that mesh build (same module, EXPORT_KEEP=True keeps the meshes) and then exports
each ball with a material that samples the atlas, so the files open in colour in any viewer.
Writes final/models/<Ball>.glb, final/models/<Ball>.fbx and final/textures/atlas.png.
"""
import os
import shutil

import bpy

HERE = r"C:\Users\dakem\Documents\RobloxGames\ball\Assets\Balls\LowPolyV2"
FINAL = os.path.join(HERE, "final")
os.makedirs(os.path.join(FINAL, "models"), exist_ok=True)
os.makedirs(os.path.join(FINAL, "textures"), exist_ok=True)

# Drop meshes left by an interrupted run so names stay unsuffixed.
for stale in [m for m in bpy.data.meshes if m.name.endswith("_Export") and m.users == 0]:
    bpy.data.meshes.remove(stale)
ns = {"EXPORT_KEEP": True}
exec(open(os.path.join(HERE, "export_roblox.py"), encoding="utf-8").read(), ns)

atlas_path = os.path.join(FINAL, "textures", "atlas.png")
shutil.copyfile(os.path.join(HERE, "roblox", "atlas.png"), atlas_path)
img = bpy.data.images.load(atlas_path)

mat = bpy.data.materials.new("LP2_AtlasPack")
mat.use_nodes = True
nodes = mat.node_tree.nodes
bsdf = nodes["Principled BSDF"]
bsdf.inputs["Roughness"].default_value = 0.6
tex = nodes.new("ShaderNodeTexImage")
tex.image = img
tex.interpolation = "Closest"
mat.node_tree.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])

scene = bpy.data.scenes.new("_LP2_Pack")
win = bpy.context.window
prev = win.scene
written = []
try:
    win.scene = scene
    for b in ns["balls"]:
        me = bpy.data.meshes[b["mesh"]]
        me.materials.clear()
        me.materials.append(mat)
        ob = bpy.data.objects.new(b["name"], me)
        scene.collection.objects.link(ob)
        for other in scene.objects:
            other.select_set(other == ob)
        bpy.context.view_layer.objects.active = ob
        base = os.path.join(FINAL, "models", b["name"])
        with bpy.context.temp_override(window=win, scene=scene):
            bpy.ops.export_scene.gltf(filepath=base + ".glb", export_format="GLB", use_selection=True,
                                      use_active_scene=True, export_yup=True, export_apply=False,
                                      export_image_format="AUTO")
            bpy.ops.export_scene.fbx(filepath=base + ".fbx", use_selection=True, path_mode="COPY",
                                     embed_textures=True, axis_forward="-Z", axis_up="Y")
        scene.collection.objects.unlink(ob)
        bpy.data.objects.remove(ob)
        written.append(b["name"])
finally:
    win.scene = prev
    bpy.data.scenes.remove(scene)
    for b in ns["balls"]:
        if b["mesh"] in bpy.data.meshes:
            bpy.data.meshes.remove(bpy.data.meshes[b["mesh"]])
    bpy.data.materials.remove(mat)
    bpy.data.images.remove(img)

result = {"written": written}
