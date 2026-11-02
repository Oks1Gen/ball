"""Turntable check: front / right / back / left / top views of every ball, assembled into sheets.

Rows are balls, columns are views. Set WHICH = ["08", "09"] before exec to limit the balls.
"""
import math
import os

import bpy
import numpy as np
from mathutils import Vector

OUT = r"C:\Users\dakem\Documents\RobloxGames\ball\Assets\Balls\LowPolyV2\previews"
WHICH = globals().get("WHICH")
SIZE = 300
VIEWS = [("front", 0, 12), ("right", 90, 12), ("back", 180, 12), ("left", 270, 12), ("top", 30, 62)]

sc = bpy.data.scenes["BallPack_LowPolyV2"]
pack = bpy.data.collections["BallPack_LowPolyV2"]
main_cam = bpy.data.objects["LP2_Camera"]
rev = bpy.data.objects["LP2_ReviewCam"]
rev.data.lens = 85
tmp = os.path.join(OUT, "_turn.png")

saved_hide = {c.name: c.hide_render for c in pack.children}
res = (sc.render.resolution_x, sc.render.resolution_y)
rows = []
try:
    sc.render.resolution_x = sc.render.resolution_y = SIZE
    for coll in pack.children:
        code = coll.name.split("_")[1]
        if WHICH and code not in WHICH:
            continue
        for other in pack.children:
            other.hide_render = other is not coll
        target = bpy.data.objects[coll.name].location.copy()
        dist = {"09": 8.0, "10": 8.0}.get(code, 6.8)
        row = []
        for _, az, el in VIEWS:
            a, e = math.radians(az), math.radians(el)
            d = Vector((math.sin(a) * math.cos(e), -math.cos(a) * math.cos(e), math.sin(e)))
            rev.location = target + d * dist
            rev.rotation_euler = (target - rev.location).to_track_quat("-Z", "Y").to_euler()
            sc.camera = rev
            sc.render.filepath = tmp
            bpy.ops.render.render(write_still=True, scene=sc.name)
            img = bpy.data.images.load(tmp, check_existing=False)
            px = np.array(img.pixels[:], dtype=np.float32).reshape(SIZE, SIZE, img.channels)
            if img.channels == 3:
                px = np.concatenate([px, np.ones((SIZE, SIZE, 1), np.float32)], axis=2)
            bpy.data.images.remove(img)
            row.append(px)
        rows.append((code, np.concatenate(row, axis=1)))
finally:
    for c in pack.children:
        c.hide_render = saved_hide.get(c.name, False)
    sc.camera = main_cam
    sc.render.resolution_x, sc.render.resolution_y = res
    if os.path.exists(tmp):
        os.remove(tmp)

sheets = []
for start in range(0, len(rows), 5):
    chunk = rows[start:start + 5]
    # Blender pixel rows go bottom-up: stack in reverse so the first ball is the top row.
    sheet = np.concatenate([r for _, r in reversed(chunk)], axis=0)
    name = "turntable_%s-%s.png" % (chunk[0][0], chunk[-1][0])
    out = bpy.data.images.new(name, sheet.shape[1], sheet.shape[0], alpha=True)
    out.pixels.foreach_set(sheet.ravel())
    out.filepath_raw = os.path.join(OUT, name)
    out.file_format = "PNG"
    out.save()
    bpy.data.images.remove(out)
    sheets.append(out.filepath_raw if False else os.path.join(OUT, name))

result = {"sheets": sheets, "views": [v[0] for v in VIEWS]}
