"""Render the saved pack for inspection without adding fixtures to the asset."""
import json
import math
from pathlib import Path

import bpy
from mathutils import Vector

OUT = Path(__file__).resolve().parent
bpy.ops.wm.open_mainfile(filepath=str(OUT / "sea-life.blend"))
scene = bpy.context.scene
for name, x in (("MantaRay", -24), ("YellowTang", 0), ("Clownfish", 12), ("BlueTang", 24), ("Butterflyfish", 36)):
    root = bpy.data.objects[name]
    root.location.x = x
    if name == "MantaRay":
        root.rotation_euler.z = math.pi
    else:
        root.scale = (2.4,) * 3

scene.render.engine = "CYCLES"
scene.cycles.samples = 24
scene.render.resolution_x = 1800
scene.render.resolution_y = 900
scene.render.resolution_percentage = 100
scene.world = bpy.data.worlds.new("Preview ambient")
scene.world.use_nodes = True
scene.world.node_tree.nodes.get("Background").inputs[0].default_value = (.34, .41, .52, 1)
scene.world.node_tree.nodes.get("Background").inputs[1].default_value = .65
scene.view_settings.view_transform = "Standard"
for location, energy, size in (((-10, -30, 45), 35000, 36), ((25, 18, 24), 27000, 28)):
    data = bpy.data.lights.new("Preview softbox", "AREA")
    light = bpy.data.objects.new("Preview softbox", data)
    scene.collection.objects.link(light)
    light.location = location
    light.rotation_euler = (Vector((4, 0, 0)) - light.location).to_track_quat("-Z", "Y").to_euler()
    data.energy, data.shape, data.size = energy, "DISK", size
data = bpy.data.cameras.new("Review camera")
camera = bpy.data.objects.new("Review camera", data)
scene.collection.objects.link(camera)
scene.camera = camera
data.type = "ORTHO"
data.ortho_scale = 85
for name, position in (("front", (4, -70, 38)), ("back", (4, 70, 32)), ("top", (4, -15, 90)), ("underside", (4, -60, -35))):
    camera.location = position
    camera.rotation_euler = (Vector((4, 0, 0)) - camera.location).to_track_quat("-Z", "Y").to_euler()
    scene.render.filepath = str(OUT / ("sea-life-" + name + ".png"))
    bpy.ops.render.render(write_still=True)
report = {}
for name in ("MantaRay", "YellowTang", "Clownfish", "BlueTang", "Butterflyfish"):
    model = bpy.data.objects[name]
    count = 0
    for obj in model.children:
        obj.data.calc_loop_triangles()
        count += len(obj.data.loop_triangles)
    report[name] = {"triangles": count}
(OUT / "validation.json").write_text(json.dumps(report, indent=2), encoding="utf-8")
