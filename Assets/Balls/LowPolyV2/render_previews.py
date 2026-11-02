"""Render review shots (one per ball, reference framing) and the pack overview.

Set WHICH = ["01", "overview"] before exec to limit the renders.
"""
import math
import os

import bpy
from mathutils import Vector

OUT = r"C:\Users\dakem\Documents\RobloxGames\ball\Assets\Balls\LowPolyV2\previews"
WHICH = globals().get("WHICH")
SCENE_NAME = "BallPack_LowPolyV2"
PACK_COLL = "BallPack_LowPolyV2"

sc = bpy.data.scenes[SCENE_NAME]
pack = bpy.data.collections[PACK_COLL]
main_cam = bpy.data.objects["LP2_Camera"]
rev = bpy.data.objects.get("LP2_ReviewCam")
if rev is None:
    rev = bpy.data.objects.new("LP2_ReviewCam", bpy.data.cameras.new("LP2_ReviewCam"))
    bpy.data.collections["BallPack_Stage"].objects.link(rev)
rev.data.lens = 85

saved_hide = {c.name: c.hide_render for c in pack.children}
res = (sc.render.resolution_x, sc.render.resolution_y)
done = []
try:
    for coll in pack.children:
        code = coll.name.split("_")[1]
        if WHICH and code not in WHICH:
            continue
        root = bpy.data.objects[coll.name]
        for other in pack.children:
            other.hide_render = other is not coll
        d = Vector((0, -math.cos(math.radians(8)), math.sin(math.radians(8))))
        target = root.location.copy()
        rev.location = target + d * {"09": 7.8, "10": 7.8}.get(code, 6.6)
        rev.rotation_euler = (target - rev.location).to_track_quat("-Z", "Y").to_euler()
        sc.camera = rev
        sc.render.resolution_x = sc.render.resolution_y = 720
        sc.render.filepath = os.path.join(OUT, "review_%s.png" % code)
        bpy.ops.render.render(write_still=True, scene=sc.name)
        done.append(sc.render.filepath)
    if not WHICH or "overview" in WHICH:
        for other in pack.children:
            other.hide_render = False
        sc.camera = main_cam
        sc.render.resolution_x, sc.render.resolution_y = 1920, 1080
        sc.render.filepath = os.path.join(OUT, "overview.png")
        bpy.ops.render.render(write_still=True, scene=sc.name)
        done.append(sc.render.filepath)
finally:
    for c in pack.children:
        c.hide_render = saved_hide.get(c.name, False)
    sc.camera = main_cam
    sc.render.resolution_x, sc.render.resolution_y = res

result = {"rendered": done}
