"""Export the pack for Roblox: one mesh per ball (.glb, no materials) plus one shared colour atlas.

Every face keeps its flat colour: material colour x (1 + lp_shade), emission baked in as brightness,
quantised into 16 px tiles of a 1024 px atlas. Each face's UVs form a small triangle inside its
tile, so mipmaps never bleed. Balls are turned 180 deg about Z so the Blender front (-Y) becomes
Roblox -Z (LookVector). Writes roblox/balls.glb, roblox/atlas.png and roblox/manifest.json.
"""
import json
import os

import bmesh
import bpy
from mathutils import Matrix

OUT = r"C:\Users\dakem\Documents\RobloxGames\ball\Assets\Balls\LowPolyV2\roblox"
PACK_COLL = "BallPack_LowPolyV2"
TEX, TILE = 1024, 16
GRID = TEX // TILE

# Re-use the palette from the builder so colours match the renders exactly.
_src = open(os.path.join(os.path.dirname(OUT), "build_low_poly_v2.py"), encoding="utf-8").read()
_ns = {}
exec(_src[_src.index("PALETTE = {"):_src.index("\n\n\ndef lin")], _ns)
PALETTE = _ns["PALETTE"]


def srgb(hexstr):
    h = hexstr.lstrip("#")
    return [int(h[i:i + 2], 16) / 255 for i in (0, 2, 4)]


os.makedirs(OUT, exist_ok=True)
sc = bpy.data.scenes["BallPack_LowPolyV2"]
dg = bpy.context.evaluated_depsgraph_get()
turn = Matrix.Rotation(3.141592653589793, 4, "Z")
tiles = {}
balls = []

for coll in bpy.data.collections[PACK_COLL].children:
    root = bpy.data.objects[coll.name]
    inv = root.matrix_world.inverted()
    bm = bmesh.new()
    face_tile = []
    for ob in coll.objects:
        if ob.type != "MESH":
            continue
        me = ob.evaluated_get(dg).to_mesh()
        part = bmesh.new()
        part.from_mesh(me)
        part.transform(turn @ inv @ ob.matrix_world)
        # Triangulation copies each polygon's material index and lp_shade onto its triangles.
        bmesh.ops.triangulate(part, faces=part.faces[:])
        keys = [m.name[4:] if m else None for m in me.materials]
        # Boolean cuts leave an empty slot on the groove floor; it belongs to the groove colour,
        # which recolor_walls appended as the last slot.
        keys = [k or [x for x in keys if x][-1] for k in keys]
        assert all(k in PALETTE for k in keys), (ob.name, keys)
        lay = part.faces.layers.float.get("lp_shade")
        for f in part.faces:
            key = keys[min(f.material_index, len(keys) - 1)]
            s = f[lay] if lay is not None else 0.0
            face_tile.append((key, round(s * 50) / 50, PALETTE[key][2]))
        tmp = bpy.data.meshes.new("_tmp")
        part.to_mesh(tmp)
        part.free()
        bm.from_mesh(tmp)
        bpy.data.meshes.remove(tmp)
        ob.evaluated_get(dg).to_mesh_clear()
    bm.faces.ensure_lookup_table()
    uv = bm.loops.layers.uv.new("UVMap")
    for f, (key, s, emit) in zip(bm.faces, face_tile):
        tk = (key, s)
        if tk not in tiles:
            c = [min(1.0, v * (1 + s) * (1 + 0.5 * emit)) for v in srgb(PALETTE[key][0])]
            tiles[tk] = (len(tiles), c)
        idx = tiles[tk][0]
        cx = (idx % GRID + 0.5) / GRID
        cy = 1 - (idx // GRID + 0.5) / GRID
        d = 0.2 / GRID
        for loop, (du, dv) in zip(f.loops, ((-d, -d), (d, -d), (0, d))):
            loop[uv].uv = (cx + du, cy + dv)
    xs = [v.co.x for v in bm.verts]
    ys = [v.co.y for v in bm.verts]
    zs = [v.co.z for v in bm.verts]
    me = bpy.data.meshes.new(coll.name + "_Export")
    bm.to_mesh(me)
    bm.free()
    balls.append({
        "name": coll.name,
        "tris": len(me.polygons),
        # Blender Z-up bounds; Roblox Y-up is (x, z, -y).
        "bmin": [min(xs), min(ys), min(zs)],
        "bmax": [max(xs), max(ys), max(zs)],
        "mesh": me.name,
    })

assert len(tiles) <= GRID * GRID, len(tiles)


def write_roblox():
    write_atlas()
    write_glb()
    write_manifest()


def write_atlas():
    # Atlas: rows top-down in tile order; Blender pixel rows go bottom-up, so flip the row index.
    px = [0.0] * (TEX * TEX * 4)
    for idx, c in tiles.values():
        tx, ty = idx % GRID, idx // GRID
        for y in range(TILE):
            row = TEX - 1 - (ty * TILE + y)
            base = (row * TEX + tx * TILE) * 4
            for x in range(TILE):
                px[base + x * 4:base + x * 4 + 4] = (c[0], c[1], c[2], 1.0)
    img = bpy.data.images.new("LP2_Atlas", TEX, TEX, alpha=False)
    img.pixels.foreach_set(px)
    img.filepath_raw = os.path.join(OUT, "atlas.png")
    img.file_format = "PNG"
    img.save()
    bpy.data.images.remove(img)


def write_glb():
    # Export from a throwaway scene so the pack scene is untouched.
    tmp_scene = bpy.data.scenes.new("_LP2_Export")
    objs = []
    for b in balls:
        ob = bpy.data.objects.new(b["name"], bpy.data.meshes[b["mesh"]])
        tmp_scene.collection.objects.link(ob)
        objs.append(ob)
    win = bpy.context.window
    prev = win.scene
    win.scene = tmp_scene
    try:
        with bpy.context.temp_override(window=win, scene=tmp_scene):
            bpy.ops.export_scene.gltf(filepath=os.path.join(OUT, "balls.glb"), export_format="GLB",
                                      use_selection=False, use_active_scene=True,
                                      export_materials="NONE", export_yup=True,
                                      export_apply=False, export_normals=True, export_texcoords=True)
    finally:
        win.scene = prev
        for ob in objs:
            me = ob.data
            bpy.data.objects.remove(ob)
            bpy.data.meshes.remove(me)
        bpy.data.scenes.remove(tmp_scene)


def write_manifest():
    for b in balls:
        b.pop("mesh")
    manifest = {"atlas": "atlas.png", "glb": "balls.glb", "tiles": len(tiles), "balls": balls}
    with open(os.path.join(OUT, "manifest.json"), "w", encoding="utf-8") as f:
        json.dump(manifest, f, indent=1)


# export_pack.py sets EXPORT_KEEP to reuse the built meshes instead of writing the Roblox files.
if not globals().get("EXPORT_KEEP"):
    write_roblox()
    result = {"tiles": len(tiles), "balls": [(b["name"], b["tris"]) for b in balls]}
