"""Export 30 numbered pet roots, preserving evaluated geometry and material colors.

Run in a background Blender process; the input .blend is never saved.
"""
import bpy
import json
import math
import re
from pathlib import Path
from mathutils import Vector

output = Path(__file__).resolve().parents[1] / "assets" / "pets" / "red30"
output.mkdir(parents=True, exist_ok=True)
roots = sorted((o for o in bpy.data.objects if o.type == "EMPTY" and re.match(r"^\d{2} \u2022 ", o.name)), key=lambda o: o.name)
assert len(roots) == 30, f"Expected 30 pet roots, found {len(roots)}"
graph = bpy.context.evaluated_depsgraph_get()
palette = []
lookup = {}
exports = []
manifest = []
collection = bpy.data.collections.new("RedPets30Export")
bpy.context.scene.collection.children.link(collection)

def color_of(material):
    if material and material.use_nodes:
        shader = next((n for n in material.node_tree.nodes if n.type == "BSDF_PRINCIPLED"), None)
        if shader:
            return tuple(shader.inputs["Base Color"].default_value)
    return tuple(material.diffuse_color) if material else (1, 1, 1, 1)

def color_index(color):
    key = tuple(round(v, 6) for v in color)
    if key not in lookup:
        lookup[key] = len(palette)
        palette.append(key)
    return lookup[key]

for index, root in enumerate(roots, 1):
    vertices, faces, normals, face_colors = [], [], [], []
    sources = [o for o in root.children_recursive if o.type in {"MESH", "CURVE", "SURFACE", "FONT"} and not o.hide_render]
    for source in sources:
        evaluated = source.evaluated_get(graph)
        mesh = evaluated.to_mesh(preserve_all_data_layers=True, depsgraph=graph)
        if not mesh:
            continue
        mesh.calc_loop_triangles()
        offset = len(vertices)
        vertices.extend(source.matrix_world @ v.co for v in mesh.vertices)
        normal_matrix = source.matrix_world.to_3x3().inverted().transposed()
        for tri in mesh.loop_triangles:
            coords = [vertices[offset + v] for v in tri.vertices]
            if (coords[1] - coords[0]).cross(coords[2] - coords[0]).length < 1e-10:
                continue
            material = mesh.materials[tri.material_index] if tri.material_index < len(mesh.materials) else None
            faces.append([offset + v for v in tri.vertices])
            face_colors.append(color_index(color_of(material)))
            normals.extend(tuple((normal_matrix @ mesh.corner_normals[i].vector).normalized()) for i in tri.loops)
        evaluated.to_mesh_clear()
    assert vertices and faces, f"Empty pet: {root.name}"
    assert len(faces) <= 20000, f"{root.name}: {len(faces)} triangles exceed importer limit"
    minimum = Vector(tuple(min(v[i] for v in vertices) for i in range(3)))
    maximum = Vector(tuple(max(v[i] for v in vertices) for i in range(3)))
    base = Vector(((minimum.x + maximum.x) / 2, (minimum.y + maximum.y) / 2, minimum.z))
    factor = 3 / (maximum.z - minimum.z)
    points = [(v - base) * factor for v in vertices]
    name = "RedPet" + f"{index:02d}" + re.sub(r"[^A-Za-z0-9]", "", root.name[5:])
    geometry = bpy.data.meshes.new(name + "Geometry")
    geometry.from_pydata(points, [], faces)
    geometry.update()
    geometry.normals_split_custom_set(normals)
    uv = geometry.uv_layers.new(name="UVMap")
    for poly, slot in zip(geometry.polygons, face_colors):
        # Each face samples the middle of a solid atlas cell, preventing seams.
        center = ((slot % 8 + 0.5) / 8, (slot // 8 + 0.5) / 8)
        for loop in poly.loop_indices:
            uv.data[loop].uv = center
    obj = bpy.data.objects.new(name, geometry)
    collection.objects.link(obj)
    obj.location = ((index - 1) % 6 * 5, (index - 1) // 6 * 5, 0)
    exports.append(obj)
    manifest.append({"index": index, "id": name, "name": root.name[5:], "sourceObjects": len(sources), "vertices": len(points), "triangles": len(faces), "heightStuds": 3})

assert len(palette) <= 64, "Expand palette atlas before exporting"
image = bpy.data.images.new("RedPets30Colors", width=256, height=256, alpha=True)
image.colorspace_settings.name = "sRGB"
pixels = []
for y in range(256):
    for x in range(256):
        slot = (y // 32) * 8 + x // 32
        pixels.extend(palette[slot] if slot < len(palette) else (1, 1, 1, 1))
image.pixels.foreach_set(pixels)
image.filepath_raw = str(output / "red-pets30-colors.png")
image.file_format = "PNG"
image.save()
material = bpy.data.materials.new("RedPets30Colors")
material.use_nodes = True
shader = material.node_tree.nodes.get("Principled BSDF")
shader.inputs["Roughness"].default_value = 0.55
texture = material.node_tree.nodes.new("ShaderNodeTexImage")
texture.image = image
texture.interpolation = "Closest"
material.node_tree.links.new(texture.outputs["Color"], shader.inputs["Base Color"])
for obj in exports:
    obj.data.materials.append(material)

bpy.ops.object.select_all(action="DESELECT")
for obj in exports:
    obj.select_set(True)
bpy.context.view_layer.objects.active = exports[0]
fbx = output / "red-pets30.fbx"
bpy.ops.export_scene.fbx(filepath=str(fbx), use_selection=True, object_types={"MESH"}, axis_forward="-Z", axis_up="Y", apply_unit_scale=True, bake_anim=False, path_mode="COPY", embed_textures=True)
(output / "manifest.json").write_text(json.dumps({"source": bpy.data.filepath, "pets": manifest, "colors": palette, "texture": "red-pets30-colors.png", "fbx": fbx.name}, ensure_ascii=False, indent=2), encoding="utf-8")

# Preview only the exported pack; exclude the original scene, floor and cameras.
scene = bpy.data.scenes.new("RedPets30Preview")
scene.collection.children.link(collection)
scene.render.engine = "CYCLES"
scene.cycles.samples = 16
scene.render.resolution_x = 1200
scene.render.resolution_y = 950
scene.render.resolution_percentage = 100
scene.world = bpy.data.worlds.new("RedPets30PreviewWorld")
scene.world.use_nodes = True
scene.world.node_tree.nodes["Background"].inputs["Color"].default_value = (0.12, 0.15, 0.2, 1)
scene.world.node_tree.nodes["Background"].inputs["Strength"].default_value = 0.8
camera_data = bpy.data.cameras.new("RedPets30PreviewCamera")
camera = bpy.data.objects.new("RedPets30PreviewCamera", camera_data)
scene.collection.objects.link(camera)
camera.location = (12.5, -28, 30)
camera.rotation_euler = (Vector((12.5, 10, 1.5)) - camera.location).to_track_quat("-Z", "Y").to_euler()
camera_data.type = "ORTHO"
camera_data.ortho_scale = 32
scene.camera = camera
for name, position, power, size in [("Key", (0, -10, 30), 5000, 20), ("Fill", (25, 15, 20), 3000, 15)]:
    light_data = bpy.data.lights.new(name, "AREA")
    light_data.energy = power
    light_data.shape = "DISK"
    light_data.size = size
    light = bpy.data.objects.new(name, light_data)
    scene.collection.objects.link(light)
    light.location = position
    light.rotation_euler = (Vector((12.5, 10, 0)) - light.location).to_track_quat("-Z", "Y").to_euler()
scene.view_settings.view_transform = "Standard"
scene.render.filepath = str(output / "preview.png")
bpy.ops.render.render(write_still=True, scene=scene.name)
print("RED_PETS_EXPORT=" + json.dumps({"pets": len(exports), "triangles": sum(p["triangles"] for p in manifest), "maxTriangles": max(p["triangles"] for p in manifest), "paletteColors": len(palette), "fbx": str(fbx), "bytes": fbx.stat().st_size}))
