"""Low Poly V2 ball pack: ten procedural balls built from Assets/Balls/References/2026-10-31-low-poly-v2.

Run inside Blender (Blender Lab MCP add-on or Text Editor). Idempotent: rebuilds the pack scene.
Set ONLY = ["01", "05"] before exec to rebuild a subset.
"""
import math
import random
import zlib

import bmesh
import bpy
from mathutils import Matrix, Quaternion, Vector

ONLY = globals().get("ONLY")
SCENE_NAME = "BallPack_LowPolyV2"
PACK_COLL = "BallPack_LowPolyV2"
STAGE_COLL = "BallPack_Stage"
PHI = (1 + 5 ** 0.5) / 2
FRONT = Vector((0.0, -math.cos(math.radians(10)), math.sin(math.radians(10))))

BALLS = [
    ("01", "Ball_01_Rubber"),
    ("02", "Ball_02_Classic"),
    ("03", "Ball_03_Beach"),
    ("04", "Ball_04_Basketball"),
    ("05", "Ball_05_Leather"),
    ("06", "Ball_06_Steel"),
    ("07", "Ball_07_Gold"),
    ("08", "Ball_08_Storm"),
    ("09", "Ball_09_Volcano"),
    ("10", "Ball_10_Sun"),
]
SPACING_X = 3.6
LAYOUT = {code: ((i % 5 - 2) * SPACING_X, 0.0 if i < 5 else 4.4) for i, (code, _) in enumerate(BALLS)}

# name: (hex sRGB, roughness, emission strength)
PALETTE = {
    "rubber_red": ("#FB3442", 0.55, 0.0),
    "rubber_groove": ("#B80F27", 0.6, 0.0),
    "classic_white": ("#F5F3F8", 0.5, 0.0),
    "classic_black": ("#37363E", 0.5, 0.0),
    "classic_seam": ("#BDB9CB", 0.6, 0.0),
    "beach_yellow": ("#FFD20A", 0.5, 0.0),
    "beach_cyan": ("#14BDFF", 0.5, 0.0),
    "beach_white": ("#F7F5FB", 0.5, 0.0),
    "beach_valve": ("#F2F0F5", 0.45, 0.0),
    "bball_orange": ("#FF7418", 0.55, 0.0),
    "bball_channel": ("#393744", 0.6, 0.0),
    "leather_top": ("#C9622C", 0.6, 0.0),
    "leather_bevel": ("#B05326", 0.6, 0.0),
    "leather_wall": ("#8A3D1C", 0.65, 0.0),
    "leather_seam": ("#4B2211", 0.7, 0.0),
    "leather_stitch": ("#F4E0B4", 0.5, 0.0),
    "steel_silver": ("#C8CAD6", 0.45, 0.0),
    "steel_blue": ("#7A85C6", 0.45, 0.0),
    "steel_silver_hi": ("#DCDEE6", 0.45, 0.0),
    "steel_blue_hi": ("#8E98D4", 0.45, 0.0),
    "steel_slate": ("#363849", 0.55, 0.0),
    "steel_bolt": ("#D6D8E0", 0.4, 0.0),
    "gold_a": ("#FFC414", 0.45, 0.0),
    "gold_b": ("#FFD332", 0.45, 0.0),
    "gold_c": ("#FFB40C", 0.45, 0.0),
    "gold_bevel": ("#FFE45A", 0.45, 0.0),
    "gold_wall": ("#E8901A", 0.5, 0.0),
    "gold_seam": ("#CF640E", 0.55, 0.0),
    "storm_body": ("#23339F", 0.6, 0.0),
    "storm_body_dark": ("#1C2885", 0.6, 0.0),
    "storm_violet": ("#6656D6", 0.55, 0.0),
    "storm_violet_hi": ("#7A6DE6", 0.55, 0.0),
    "storm_violet_dark": ("#4D3FBF", 0.6, 0.0),
    "storm_band": ("#3B5EE0", 0.55, 0.0),
    "storm_band_dark": ("#2D47C4", 0.6, 0.0),
    "storm_cyan": ("#62F2FF", 0.45, 0.3),
    "storm_cyan_hi": ("#9AF8FF", 0.45, 0.3),
    "storm_cyan_side": ("#33CDF5", 0.5, 0.2),
    "storm_bolt": ("#FFD21C", 0.45, 0.0),
    "storm_bolt_hi": ("#FFE55A", 0.45, 0.0),
    "storm_bolt_side": ("#F2AA0C", 0.5, 0.0),
    "volc_rock_a": ("#3A3240", 0.7, 0.0),
    "volc_rock_b": ("#2C2731", 0.7, 0.0),
    "volc_rock_c": ("#4A2E44", 0.7, 0.0),
    "volc_crevice": ("#1E1820", 0.8, 0.0),
    "volc_lava_red": ("#FF4D0D", 0.5, 0.45),
    "volc_lava_orange": ("#FF8400", 0.5, 0.55),
    "volc_lava_yellow": ("#FFC20A", 0.5, 0.7),
    "volc_wall_glow": ("#FF5A12", 0.55, 0.35),
    "volc_spike": ("#2B2630", 0.6, 0.0),
    "sun_core_a": ("#FFC21A", 0.5, 0.35),
    "sun_core_b": ("#FFD43C", 0.5, 0.35),
    "sun_core_c": ("#FFAA10", 0.5, 0.35),
    "sun_panel": ("#FBF6EA", 0.5, 0.0),
    "sun_panel_warm": ("#F3E5C6", 0.5, 0.0),
    "sun_rim": ("#F8BA1E", 0.45, 0.0),
    "sun_wall": ("#EAA010", 0.5, 0.0),
    "sun_ring": ("#F6B71C", 0.45, 0.0),
    "stage_floor": ("#D8D3F4", 0.95, 0.0),
}


def lin(hexstr):
    h = hexstr.lstrip("#")
    out = []
    for i in (0, 2, 4):
        c = int(h[i:i + 2], 16) / 255
        out.append(c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4)
    return (out[0], out[1], out[2], 1.0)


def material(key):
    hexstr, rough, emit = PALETTE[key]
    name = "LP2_" + key
    m = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    try:
        m.use_nodes = True
    except Exception:
        pass
    nt = m.node_tree
    nt.nodes.clear()
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    out.location = (500, 0)
    bsdf = nt.nodes.new("ShaderNodeBsdfPrincipled")
    bsdf.location = (200, 0)
    rgb = nt.nodes.new("ShaderNodeRGB")
    rgb.label = "Color"
    rgb.outputs[0].default_value = lin(hexstr)
    rgb.location = (-500, 150)
    attr = nt.nodes.new("ShaderNodeAttribute")
    attr.attribute_type = "GEOMETRY"
    attr.attribute_name = "lp_shade"
    attr.location = (-700, -150)
    add = nt.nodes.new("ShaderNodeMath")
    add.operation = "ADD"
    add.inputs[1].default_value = 1.0
    add.location = (-500, -150)
    mul = nt.nodes.new("ShaderNodeVectorMath")
    mul.operation = "MULTIPLY"
    mul.location = (-250, 0)
    nt.links.new(attr.outputs["Fac"], add.inputs[0])
    nt.links.new(rgb.outputs[0], mul.inputs[0])
    nt.links.new(add.outputs[0], mul.inputs[1])
    nt.links.new(mul.outputs[0], bsdf.inputs["Base Color"])
    bsdf.inputs["Roughness"].default_value = rough
    bsdf.inputs["Specular IOR Level"].default_value = 0.25
    if emit > 0:
        nt.links.new(mul.outputs[0], bsdf.inputs["Emission Color"])
        bsdf.inputs["Emission Strength"].default_value = emit
    nt.links.new(bsdf.outputs[0], out.inputs["Surface"])
    m.diffuse_color = lin(hexstr)
    m.roughness = rough
    return m


# ---------------------------------------------------------------------------
# Mesh building


def seed_of(text):
    return zlib.crc32(text.encode()) & 0xFFFFFFFF


class Part:
    def __init__(self, name, shade=(-0.07, 0.05)):
        self.name = name
        self.bm = bmesh.new()
        self.keys = []
        self.layer = self.bm.faces.layers.float.new("lp_shade")
        self.rng = random.Random(seed_of(name))
        self.shade = shade

    def mi(self, key):
        if key not in self.keys:
            self.keys.append(key)
        return self.keys.index(key)

    def v(self, co):
        return self.bm.verts.new(co)

    def f(self, verts, key, shade=None):
        face = self.bm.faces.new(verts)
        self.tag(face, key, shade)
        return face

    def tag(self, face, key, shade=None):
        face.material_index = self.mi(key)
        face[self.layer] = self.rng.uniform(*self.shade) if shade is None else shade

    def snapshot(self):
        return set(self.bm.faces)

    def new_faces(self, before):
        return [f for f in self.bm.faces if f not in before]


def finish(part, coll, parent, recalc=True):
    bm = part.bm
    if recalc:
        bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
    me = bpy.data.meshes.new(part.name)
    bm.to_mesh(me)
    bm.free()
    for k in part.keys:
        me.materials.append(material(k))
    me.shade_flat()
    obj = bpy.data.objects.new(part.name, me)
    coll.objects.link(obj)
    obj.parent = parent
    return obj


def ensure_slot(obj, key):
    mat = material(key)
    for i, m in enumerate(obj.data.materials):
        if m == mat:
            return i
    obj.data.materials.append(mat)
    return len(obj.data.materials) - 1


def bake_modifiers(obj):
    dg = bpy.context.evaluated_depsgraph_get()
    dg.update()
    ev = obj.evaluated_get(dg)
    me = bpy.data.meshes.new_from_object(ev, preserve_all_data_layers=True, depsgraph=dg)
    old = obj.data
    name = old.name
    obj.modifiers.clear()
    obj.data = me
    bpy.data.meshes.remove(old)
    me.name = name
    me.shade_flat()


def boolean_difference(obj, cutters, coll):
    for c in cutters:
        coll.objects.link(c)
        c.parent = obj.parent
        c.matrix_world = obj.matrix_world.copy()
        md = obj.modifiers.new(c.name, "BOOLEAN")
        md.operation = "DIFFERENCE"
        md.solver = "EXACT"
        md.object = c
    bake_modifiers(obj)
    for c in cutters:
        me = c.data
        bpy.data.objects.remove(c)
        bpy.data.meshes.remove(me)


def bevel(obj, width, angle=35):
    md = obj.modifiers.new("Bevel", "BEVEL")
    md.width = width
    md.segments = 1
    md.limit_method = "ANGLE"
    md.angle_limit = math.radians(angle)
    md.use_clamp_overlap = True
    bake_modifiers(obj)


def recolor_walls(obj, key, threshold=0.62):
    mi = ensure_slot(obj, key)
    for p in obj.data.polygons:
        c = Vector(p.center)
        if c.length > 1e-6 and abs(p.normal.dot(c.normalized())) < threshold:
            p.material_index = mi


def recolor_tiers(obj, tiers, low_key):
    """Colour faces by how much they face outward: tiers = [(min dot with radial, key), ...], highest first."""
    slots = [(t, ensure_slot(obj, k)) for t, k in tiers]
    low = ensure_slot(obj, low_key)
    for p in obj.data.polygons:
        c = Vector(p.center)
        d = p.normal.dot(c.normalized()) if c.length > 1e-6 else 1.0
        p.material_index = next((mi for t, mi in slots if d >= t), low)


def reshade(obj, seed, lo=-0.07, hi=0.05):
    me = obj.data
    attr = me.attributes.get("lp_shade")
    if attr is None or attr.domain != "FACE" or attr.data_type != "FLOAT":
        if attr is not None:
            me.attributes.remove(attr)
        attr = me.attributes.new("lp_shade", "FLOAT", "FACE")
    rng = random.Random(seed)
    for d in attr.data:
        d.value = rng.uniform(lo, hi)


def rotate_parts(coll, quat):
    m = quat.to_matrix().to_4x4()
    for ob in coll.objects:
        if ob.type == "MESH":
            ob.data.transform(m)


def mesh_object(name, bm):
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    return bpy.data.objects.new(name, me)


def slab_cutter(name, normal, offset, width, size=3.2):
    n = normal.normalized()
    rot = Vector((0, 0, 1)).rotation_difference(n).to_matrix().to_4x4()
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    m = Matrix.Translation(n * offset) @ rot @ Matrix.Diagonal((size, size, width, 1.0))
    bmesh.ops.transform(bm, matrix=m, verts=bm.verts)
    return mesh_object(name, bm)


def tube_cutter(name, center, axis, r_mid, width, length=4.0, segs=72):
    a = axis.normalized()
    e1, e2 = tangent_basis(a)
    bm = bmesh.new()
    rings = []
    for z in (-length / 2, length / 2):
        for r in (r_mid + width / 2, r_mid - width / 2):
            ring = []
            for k in range(segs):
                t = 2 * math.pi * k / segs
                ring.append(bm.verts.new(center + a * z + (e1 * math.cos(t) + e2 * math.sin(t)) * r))
            rings.append(ring)
    ob_, ib, ot, it = rings
    for k in range(segs):
        j = (k + 1) % segs
        bm.faces.new((ob_[k], ob_[j], ot[j], ot[k]))
        bm.faces.new((ib[j], ib[k], it[k], it[j]))
        bm.faces.new((ot[k], ot[j], it[j], it[k]))
        bm.faces.new((ob_[j], ob_[k], ib[k], ib[j]))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
    return mesh_object(name, bm)


# ---------------------------------------------------------------------------
# Sphere geometry helpers


def tangent_basis(c):
    a = Vector((0, 0, 1)) if abs(c.z) < 0.9 else Vector((1, 0, 0))
    e1 = a.cross(c).normalized()
    e2 = c.cross(e1).normalized()
    return e1, e2


def ico_base():
    raw = [(-1, PHI, 0), (1, PHI, 0), (-1, -PHI, 0), (1, -PHI, 0), (0, -1, PHI), (0, 1, PHI),
           (0, -1, -PHI), (0, 1, -PHI), (PHI, 0, -1), (PHI, 0, 1), (-PHI, 0, -1), (-PHI, 0, 1)]
    faces = [(0, 11, 5), (0, 5, 1), (0, 1, 7), (0, 7, 10), (0, 10, 11), (1, 5, 9), (5, 11, 4),
             (11, 10, 2), (10, 7, 6), (7, 1, 8), (3, 9, 4), (3, 4, 2), (3, 2, 6), (3, 6, 8),
             (3, 8, 9), (4, 9, 5), (2, 4, 11), (6, 2, 10), (8, 6, 7), (9, 8, 1)]
    return [Vector(v).normalized() for v in raw], faces


def geodesic(freq):
    v0, f0 = ico_base()
    verts, index, tris = [], {}, []

    def vid(p):
        p = p.normalized()
        k = (round(p.x, 4), round(p.y, 4), round(p.z, 4))
        if k not in index:
            index[k] = len(verts)
            verts.append(p)
        return index[k]

    for a, b, c in f0:
        A, B, C = v0[a], v0[b], v0[c]
        grid = {}
        for i in range(freq + 1):
            for j in range(freq + 1 - i):
                grid[i, j] = vid(A + (B - A) * (i / freq) + (C - A) * (j / freq))
        for i in range(freq):
            for j in range(freq - i):
                tris.append((grid[i, j], grid[i + 1, j], grid[i, j + 1]))
                if i + j < freq - 1:
                    tris.append((grid[i + 1, j], grid[i + 1, j + 1], grid[i, j + 1]))
    return verts, tris


def rand_tangent(p, rng):
    r = Vector((rng.uniform(-1, 1), rng.uniform(-1, 1), rng.uniform(-1, 1)))
    return r - p * r.dot(p)


def add_sphere(part, freq, radius, key_fn, jt=0.0, jr=0.0, seed=1, xform=None, vert_fn=None):
    verts, tris = geodesic(freq)
    rng = random.Random(seed)
    dirs = []
    bv = []
    for p in verts:
        q = p.copy()
        if xform is not None:
            q = (xform @ q).normalized()
        if jt:
            q = (q + rand_tangent(q, rng) * jt).normalized()
        r = radius * (1 + rng.uniform(-jr, jr))
        pos = q * r
        if vert_fn is not None:
            pos = vert_fn(pos)
        dirs.append(q)
        bv.append(part.v(pos))
    for t in tris:
        c = (dirs[t[0]] + dirs[t[1]] + dirs[t[2]]).normalized()
        part.f([bv[i] for i in t], key_fn(c))
    return dirs, tris


def order_ring(c, pts):
    e1, e2 = tangent_basis(c)
    return sorted(pts, key=lambda p: math.atan2(p.dot(e2), p.dot(e1)))


def face_normal(pts):
    n = Vector((0, 0, 0))
    for i in range(len(pts)):
        a, b = pts[i], pts[(i + 1) % len(pts)]
        n += a.cross(b)
    return n.normalized()


def inset_poly(q, dists, c):
    """Offset each edge of a CCW tangent-plane polygon inward by its own distance; intersect neighbours."""
    e1, e2 = tangent_basis(c)
    p2 = [(p.dot(e1), p.dot(e2)) for p in q]
    n = len(p2)
    lines = []
    for i in range(n):
        ax, ay = p2[i]
        bx, by = p2[(i + 1) % n]
        dx, dy = bx - ax, by - ay
        ln = math.hypot(dx, dy)
        nx, ny = -dy / ln, dx / ln
        lines.append(((ax + nx * dists[i], ay + ny * dists[i]), (dx, dy)))
    out = []
    for i in range(n):
        (px, py), (dx, dy) = lines[i - 1]
        (qx, qy), (ex, ey) = lines[i]
        den = dx * ey - dy * ex
        if abs(den) < 1e-9:
            x, y = qx, qy
        else:
            t = ((qx - px) * ey - (qy - py) * ex) / den
            x, y = px + dx * t, py + dy * t
        out.append(e1 * x + e2 * y)
    return out


def make_panel(part, c, corners, R=1.0, gap=0.02, chamfer=0.025, drop=0.02, base=0.88, bulge=0.03,
               mids=True, top="", bev=None, wall=None, edge_gap=None):
    """Raised faceted panel on the sphere: pyramid top, chamfer ring, walls down to `base`.

    top / bev / wall: colour key or callable(list_of_points) -> key.
    edge_gap: optional callable(corner_a, corner_b) -> gap for that edge (per-edge inset).
    """
    bev = bev or top
    wall = wall or bev
    c = c.normalized()
    corners = order_ring(c, [k.normalized() for k in corners])
    q = [k / k.dot(c) - c for k in corners]
    n = len(q)
    apo = 1e9
    for i in range(n):
        a, b = q[i], q[(i + 1) % n]
        d = b - a
        apo = min(apo, a.cross(d).length / d.length)
    gaps = [edge_gap(corners[i], corners[(i + 1) % n]) for i in range(n)] if edge_gap else None

    def ring(dist):
        if gaps:
            pts = inset_poly(q, [g + dist - gap for g in gaps], c)
        else:
            s = max(0.05, 1 - dist / apo)
            pts = [p * s for p in q]
        if mids:
            out = []
            for i in range(n):
                out.append(pts[i])
                out.append((pts[i] + pts[(i + 1) % n]) * 0.5)
            pts = out
        return pts

    def to3(p, r):
        return (c + p).normalized() * r

    ra, rb = ring(gap), ring(gap + chamfer)
    pa = [to3(p, R - drop) for p in ra]
    pb = [to3(p, R) for p in rb]
    pbase = [to3(p, base) for p in ra]
    pc = c * R * (1 + bulge)
    va = [part.v(p) for p in pa]
    vb = [part.v(p) for p in pb]
    vbase = [part.v(p) for p in pbase]
    vc = part.v(pc)

    def key(k, pts):
        return k(pts) if callable(k) else k

    m = len(va)
    for i in range(m):
        j = (i + 1) % m
        part.f([vc, vb[i], vb[j]], key(top, [pc, pb[i], pb[j]]))
        part.f([vb[i], va[i], va[j], vb[j]], key(bev, [pb[i], pa[i], pa[j], pb[j]]))
        part.f([va[i], vbase[i], vbase[j], va[j]], key(wall, [pa[i], pbase[i], pbase[j], pa[j]]))
    part.f(list(reversed(vbase)), key(wall, pbase))


def soccer_panels(rot):
    v0, f0 = ico_base()
    nbr = {i: set() for i in range(12)}
    for a, b, c in f0:
        nbr[a] |= {b, c}
        nbr[b] |= {a, c}
        nbr[c] |= {a, b}
    panels = []
    for i in range(12):
        corners = [v0[i] + (v0[j] - v0[i]) / 3 for j in nbr[i]]
        panels.append(("pent", v0[i], corners))
    for a, b, c in f0:
        A, B, C = v0[a], v0[b], v0[c]
        corners = [A + (B - A) / 3, A + (B - A) * 2 / 3, B + (C - B) / 3, B + (C - B) * 2 / 3,
                   C + (A - C) / 3, C + (A - C) * 2 / 3]
        panels.append(("hex", (A + B + C) / 3, corners))
    out = []
    for kind, cen, corners in panels:
        out.append((kind, (rot @ cen).normalized(), [(rot @ k).normalized() for k in corners]))
    return out


def soccer_edges(rot):
    """Middle thirds of icosahedron edges = the 30 hexagon-hexagon seams: (midpoint dir, along dir)."""
    v0, f0 = ico_base()
    edges = set()
    for a, b, c in f0:
        for x, y in ((a, b), (b, c), (c, a)):
            edges.add((min(x, y), max(x, y)))
    out = []
    for a, b in sorted(edges):
        mid = (rot @ ((v0[a] + v0[b]) * 0.5)).normalized()
        along = (rot @ (v0[b] - v0[a])).normalized()
        along = (along - mid * along.dot(mid)).normalized()
        out.append((mid, along))
    return out


def orient(center_dir, up_dir, front=FRONT, roll=0.0):
    q1 = center_dir.normalized().rotation_difference(front)
    u = q1 @ up_dir

    def proj(v):
        return (v - front * v.dot(front)).normalized()

    a, b = proj(u), proj(Vector((0, 0, 1)))
    ang = a.angle(b)
    sign = 1 if a.cross(b).dot(front) > 0 else -1
    q2 = Quaternion(front, sign * ang + math.radians(roll))
    return (q2 @ q1).to_matrix()


def icosa_neighbor(i):
    v0, f0 = ico_base()
    for a, b, c in f0:
        if i in (a, b, c):
            return [x for x in (a, b, c) if x != i][0]


def tube(part, pts, normals, widths, heights, sides, key, closed=False, phase=0.0, keys=None):
    """Low-poly tube along pts. Cross-section: ellipse width (binormal) x height (normal).

    A zero width at an open end collapses to a single tip vertex.
    """
    n = len(pts)
    rings = []
    for i in range(n):
        if closed:
            t = (pts[(i + 1) % n] - pts[(i - 1) % n]).normalized()
        else:
            t = (pts[min(i + 1, n - 1)] - pts[max(i - 1, 0)]).normalized()
        N = normals[i] - t * normals[i].dot(t)
        N.normalize()
        B = t.cross(N)
        if widths[i] < 1e-5 and not closed:
            rings.append(part.v(pts[i]))
            continue
        ring = []
        for k in range(sides):
            a = 2 * math.pi * k / sides + phase
            ring.append(part.v(pts[i] + B * (math.cos(a) * widths[i]) + N * (math.sin(a) * heights[i])))
        rings.append(ring)
    segs = n if closed else n - 1
    for i in range(segs):
        r0, r1 = rings[i], rings[(i + 1) % n]
        k_ = keys[i] if keys else key
        if isinstance(r0, list) and isinstance(r1, list):
            for k in range(sides):
                j = (k + 1) % sides
                part.f([r0[k], r0[j], r1[j], r1[k]], k_)
        elif isinstance(r1, list):
            for k in range(sides):
                part.f([r0, r1[(k + 1) % sides], r1[k]], k_)
        else:
            for k in range(sides):
                part.f([r0[k], r0[(k + 1) % sides], r1], k_)
    if not closed:
        if isinstance(rings[0], list):
            part.f(list(reversed(rings[0])), key)
        if isinstance(rings[-1], list):
            part.f(list(rings[-1]), keys[-1] if keys else key)


def gem_slab(part, outline, origin, X, Y, Z, t_edge, t_center, key, inset=0.8, bev_key=None):
    """Faceted slab from a star-shaped 2D outline: pyramid fans on both sides and a chamfer belt."""
    cu = sum(p[0] for p in outline) / len(outline)
    cv = sum(p[1] for p in outline) / len(outline)

    def P(u, v, z):
        return origin + X * u + Y * v + Z * z

    mid = [part.v(P(u, v, 0)) for u, v in outline]
    fr = [part.v(P(cu + (u - cu) * inset, cv + (v - cv) * inset, t_edge)) for u, v in outline]
    bk = [part.v(P(cu + (u - cu) * inset, cv + (v - cv) * inset, -t_edge)) for u, v in outline]
    cf = part.v(P(cu, cv, t_center))
    cb = part.v(P(cu, cv, -t_center))
    bk_key = bev_key or key
    n = len(outline)
    for i in range(n):
        j = (i + 1) % n
        part.f([cf, fr[i], fr[j]], key)
        part.f([fr[i], mid[i], mid[j], fr[j]], bk_key)
        part.f([mid[i], bk[i], bk[j], mid[j]], bk_key)
        part.f([cb, bk[j], bk[i]], key)


def star_outline(r_long, r_short, points=4, rot=0.0):
    out = []
    for i in range(points * 2):
        a = rot + math.pi * i / points
        r = r_long if i % 2 == 0 else r_short
        out.append((math.cos(a) * r, math.sin(a) * r))
    return out


def add_star(part, center, size, key, facing=None, rot=0.0):
    Z = (facing or -FRONT).normalized() * -1
    X, Y = tangent_basis(Z)
    gem_slab(part, star_outline(size, size * 0.26, 4, rot), center, X, Y, Z, size * 0.07, size * 0.2, key,
             inset=0.55)


def prism(part, center, axis, radius, height, sides, key, chamfer=0.0, top_key=None, phase=0.0):
    """Upright prism along axis from center (base) to center + axis*height, optional chamfered top."""
    a = axis.normalized()
    e1, e2 = tangent_basis(a)

    def ring(r, z):
        return [part.v(center + a * z + (e1 * math.cos(2 * math.pi * k / sides + phase)
                                          + e2 * math.sin(2 * math.pi * k / sides + phase)) * r)
                for k in range(sides)]

    b = ring(radius, 0)
    if chamfer > 0:
        m = ring(radius, height - chamfer)
        t = ring(radius - chamfer, height)
    else:
        m = None
        t = ring(radius, height)
    part.f(list(reversed(b)), key)
    for k in range(sides):
        j = (k + 1) % sides
        if m:
            part.f([b[k], b[j], m[j], m[k]], key)
            part.f([m[k], m[j], t[j], t[k]], top_key or key)
        else:
            part.f([b[k], b[j], t[j], t[k]], key)
    part.f(t, top_key or key)


def chamfer_box(part, center, X, Y, Z, size, chamfer, key):
    before = part.snapshot()
    m = Matrix((X.to_4d(), Y.to_4d(), Z.to_4d(), Vector((0, 0, 0, 1)))).transposed()
    m[0][3], m[1][3], m[2][3] = center
    bmesh.ops.create_cube(part.bm, size=1.0, matrix=m @ Matrix.Diagonal((*size, 1.0)))
    new = part.new_faces(before)
    edges = list({e for f in new for e in f.edges})
    bmesh.ops.bevel(part.bm, geom=edges, offset=chamfer, segments=1, affect="EDGES", clamp_overlap=True)
    for f in part.new_faces(before):
        part.tag(f, key)


# ---------------------------------------------------------------------------
# Balls


def ball_01(root, coll):
    body = Part("Ball_01_Rubber_Body")
    add_sphere(body, 4, 1.0, lambda c: "rubber_red", jt=0.04, jr=0.012, seed=101)
    obj = finish(body, coll, root)
    n = Vector((0.80, 0.30, 0.52)).normalized()
    boolean_difference(obj, [slab_cutter("cut_a", n, -0.12, 0.12), slab_cutter("cut_b", n, 0.44, 0.12)], coll)
    bevel(obj, 0.02)
    recolor_walls(obj, "rubber_groove")
    reshade(obj, 101, -0.08, 0.04)
    groove = Part("Ball_01_Rubber_Groove")
    add_sphere(groove, 4, 0.94, lambda c: "rubber_groove", seed=102)
    finish(groove, coll, root)


def ball_02(root, coll):
    rot = orient(ico_base()[0][0], ico_base()[0][icosa_neighbor(0)])
    shell = Part("Ball_02_Classic_Panels", shade=(-0.05, 0.03))
    for kind, cen, corners in soccer_panels(rot):
        k = "classic_black" if kind == "pent" else "classic_white"
        make_panel(shell, cen, corners, R=1.0, gap=0.012, chamfer=0.024, drop=0.026, base=0.9, bulge=0.035,
                   top=k)
    finish(shell, coll, root)
    seam = Part("Ball_02_Classic_Seams")
    add_sphere(seam, 4, 0.955, lambda c: "classic_seam", seed=202)
    finish(seam, coll, root)


def ball_03(root, coll):
    pole = Vector((0.36, -0.75, 0.55)).normalized()
    frame = orient(Vector((0, 0, 1)), Vector((0, 1, 0)), front=pole, roll=-62)
    segs, rings_n = 24, 10
    wedge_keys = ["beach_cyan", "beach_white", "beach_cyan", "beach_white", "beach_yellow", "beach_white"]
    per = segs // len(wedge_keys)
    body = Part("Ball_03_Beach_Body", shade=(-0.06, 0.04))
    rng = random.Random(303)

    def pt(theta, ph, r=1.0):
        return frame @ Vector((math.sin(theta) * math.cos(ph), math.sin(theta) * math.sin(ph), math.cos(theta))) * r

    top = body.v(pt(0, 0))
    bot = body.v(pt(math.pi, 0))
    grid = []
    for i in range(1, rings_n):
        row = []
        for j in range(segs):
            th = math.pi * i / rings_n + rng.uniform(-0.05, 0.05)
            row.append(body.v(pt(th, 2 * math.pi * j / segs, 1 + rng.uniform(-0.01, 0.01))))
        grid.append(row)
    for j in range(segs):
        jn = (j + 1) % segs
        k = wedge_keys[j // per]
        body.f([top, grid[0][j], grid[0][jn]], k)
        body.f([bot, grid[-1][jn], grid[-1][j]], k)
        for i in range(len(grid) - 1):
            a, b, c, d = grid[i][j], grid[i + 1][j], grid[i + 1][jn], grid[i][jn]
            if (i + j) % 2:
                body.f([a, b, c], k)
                body.f([a, c, d], k)
            else:
                body.f([a, b, d], k)
                body.f([b, c, d], k)
    finish(body, coll, root)
    valve = Part("Ball_03_Beach_Valve", shade=(-0.03, 0.02))
    prism(valve, pole * 0.96, pole, 0.12, 0.09, 10, "beach_valve", chamfer=0.035)
    prism(valve, pole * 1.04, pole, 0.05, 0.035, 8, "beach_valve", chamfer=0.015)
    finish(valve, coll, root)


def ball_04(root, coll):
    body = Part("Ball_04_Basketball_Body")
    add_sphere(body, 4, 1.0, lambda c: "bball_orange", jt=0.035, jr=0.012, seed=404)
    obj = finish(body, coll, root)
    w = 0.12
    cutters = [
        slab_cutter("cut_eq", Vector((0, 0, 1)), 0.0, w),
        slab_cutter("cut_mer", Vector((1, 0, 0)), 0.0, w),
        tube_cutter("cut_l", Vector((-1.5, 0, 0)), Vector((0, 1, 0)), 1.1, w),
        tube_cutter("cut_r", Vector((1.5, 0, 0)), Vector((0, 1, 0)), 1.1, w),
    ]
    boolean_difference(obj, cutters, coll)
    bevel(obj, 0.02)
    recolor_walls(obj, "bball_channel")
    reshade(obj, 404, -0.08, 0.05)
    channel = Part("Ball_04_Basketball_Channels")
    add_sphere(channel, 4, 0.94, lambda c: "bball_channel", seed=405)
    finish(channel, coll, root)
    rotate_parts(coll, Quaternion(Vector((1, 0, 0)), math.radians(14)) @ Quaternion(Vector((0, 1, 0)), math.radians(6))
                 @ Quaternion(Vector((0, 0, 1)), math.radians(20)))


def ball_05(root, coll):
    v0, _ = ico_base()
    _, f0 = ico_base()
    a, b, c = f0[0]
    hex_c = (v0[a] + v0[b] + v0[c]) / 3
    rot = orient(hex_c, v0[a])
    shell = Part("Ball_05_Leather_Panels", shade=(-0.06, 0.04))
    for kind, cen, corners in soccer_panels(rot):
        make_panel(shell, cen, corners, R=1.0, gap=0.03, chamfer=0.05, drop=0.055, base=0.88, bulge=0.075,
                   top="leather_top", bev="leather_bevel", wall="leather_wall")
    finish(shell, coll, root)
    seam = Part("Ball_05_Leather_Seams")
    add_sphere(seam, 4, 0.93, lambda c: "leather_seam", seed=505)
    finish(seam, coll, root)
    stitches = Part("Ball_05_Leather_Stitches", shade=(-0.03, 0.03))
    # A stitch on every one of the 30 hexagon-hexagon seams: the same pattern from every side.
    for mid, along in soccer_edges(rot):
        across = mid.cross(along).normalized()
        chamfer_box(stitches, mid * 0.99, across, along, mid, (0.22, 0.095, 0.09), 0.022, "leather_stitch")
    finish(stitches, coll, root)


def ball_06(root, coll):
    # Unrotated soccer layout: the eight hexagons over the cube corners (±1, ±1, ±1) carry the bolts,
    # so each axis view shows the same square of four bolts.
    v0, f0 = ico_base()
    rot = Matrix.Identity(3)
    paint = Vector((-0.55, -0.35, 0.75)).normalized()

    def two_tone(hi_key, lo_key, cen):
        # Split every panel the same way in its own tangent frame, so the back is as two-tone as the front.
        t = paint - cen * paint.dot(cen)
        if t.length < 0.2:
            t = Vector((1, 0, 0)) - cen * cen.x
        t.normalize()

        def fn(pts):
            n = face_normal(pts)
            tilt = n - cen * n.dot(cen)
            return hi_key if tilt.length > 1e-6 and tilt.normalized().dot(t) > -0.15 else lo_key
        return fn

    shell = Part("Ball_06_Steel_Panels", shade=(-0.04, 0.03))
    panels = soccer_panels(rot)
    for kind, cen, corners in panels:
        make_panel(shell, cen, corners, R=1.0, gap=0.06, chamfer=0.032, drop=0.035, base=0.92, bulge=0.035,
                   mids=False, top=two_tone("steel_silver", "steel_blue", cen),
                   bev=two_tone("steel_silver_hi", "steel_blue_hi", cen), wall="steel_slate")
    finish(shell, coll, root)
    seam = Part("Ball_06_Steel_Seams")
    add_sphere(seam, 4, 0.975, lambda c: "steel_slate", seed=606)
    finish(seam, coll, root)
    bolts = Part("Ball_06_Steel_Bolts", shade=(-0.03, 0.03))
    for a, b, c in f0:
        cen = v0[a] + v0[b] + v0[c]
        if abs(abs(cen.x) - abs(cen.y)) > 1e-6 or abs(abs(cen.y) - abs(cen.z)) > 1e-6:
            continue
        d = (rot @ cen).normalized()
        prism(bolts, d * 1.005, d, 0.18, 0.045, 6, "steel_slate", chamfer=0.014, phase=0.3)
        prism(bolts, d * 1.045, d, 0.115, 0.075, 6, "steel_bolt", chamfer=0.026, phase=0.3)
    finish(bolts, coll, root)


def ball_07(root, coll):
    v0, f0 = ico_base()
    a, b, c = f0[5]
    rot = orient((v0[a] + v0[b] + v0[c]) / 3, v0[a], roll=-10)
    rng = random.Random(707)
    shell = Part("Ball_07_Gold_Panels", shade=(-0.05, 0.05))
    for kind, cen, corners in soccer_panels(rot):
        make_panel(shell, cen, corners, R=1.0, gap=0.045, chamfer=0.032, drop=0.034, base=0.9, bulge=0.04,
                   top=lambda pts: rng.choice(("gold_a", "gold_a", "gold_b", "gold_c")),
                   bev="gold_bevel", wall="gold_wall")
    finish(shell, coll, root)
    seam = Part("Ball_07_Gold_Seams")
    add_sphere(seam, 4, 0.945, lambda c: "gold_seam", seed=708)
    finish(seam, coll, root)
    sparkle = Part("Ball_07_Gold_Sparkle", shade=(-0.03, 0.04))
    add_star(sparkle, Vector((1.12, -0.35, 1.02)), 0.3, "gold_a")
    finish(sparkle, coll, root)


def ball_08(root, coll):
    # Four-fold layout from the storm turnaround sheet (front, side and back views are identical):
    # a bolt every 90 deg of longitude (one facing -Y) across a zigzag cyan belt, mirrored violet
    # curls between them, a hexagon gem on each pole. The bottom half mirrors the top.
    rng = random.Random(808)
    bolt_lons = [math.radians(-90 + 90 * j) for j in range(4)]
    amp, half_w = math.radians(8), math.radians(7)

    def sph(lat, lon, r=1.0):
        return Vector((math.cos(lat) * math.cos(lon), math.cos(lat) * math.sin(lon), math.sin(lat))) * r

    def frame(lat, lon):
        p = sph(lat, lon)
        e = Vector((-math.sin(lon), math.cos(lon), 0.0))
        return p, e, p.cross(e)

    body = Part("Ball_08_Storm_Body", shade=(-0.08, 0.06))
    add_sphere(body, 4, 0.97, lambda c: rng.choice(("storm_body", "storm_body", "storm_body_dark")),
               jt=0.03, jr=0.01, seed=808)
    finish(body, coll, root)

    # Zigzag belt: two blue steps under a ridged cyan strip; 12 teeth, a valley under every bolt.
    band = Part("Ball_08_Storm_Band", shade=(-0.05, 0.05))

    def belt(hw, r, ridge, ch, drop, top, hi, lo, wall):
        prof = [(-hw, r - drop), (-hw + ch, r), (0.0, r + ridge), (hw - ch, r), (hw, r - drop)]
        keys = [lo, top, top, hi]
        rings = []
        for i in range(24):
            lon = bolt_lons[0] + math.radians(15 * i)
            lat0 = -amp if i % 2 == 0 else amp
            rings.append(([band.v(sph(lat0 + o, lon, rr)) for o, rr in prof],
                          [band.v(sph(lat0 - hw, lon, 0.9)), band.v(sph(lat0 + hw, lon, 0.9))]))
        for i in range(24):
            (a, ab), (b, bb) = rings[i], rings[(i + 1) % 24]
            for k in range(4):
                band.f([a[k], b[k], b[k + 1], a[k + 1]], keys[k])
            band.f([ab[0], bb[0], b[0], a[0]], wall)
            band.f([a[4], b[4], bb[1], ab[1]], wall)
            band.f([ab[1], bb[1], bb[0], ab[0]], wall)

    belt(half_w + 0.09, 1.0, 0.0, 0.02, 0.015, "storm_band_dark", "storm_band_dark", "storm_band_dark",
         "storm_body_dark")
    belt(half_w + 0.045, 1.035, 0.0, 0.02, 0.015, "storm_band", "storm_band", "storm_band", "storm_band_dark")
    belt(half_w, 1.07, 0.012, 0.025, 0.02, "storm_cyan", "storm_cyan_hi", "storm_cyan_side", "storm_cyan_side")
    finish(band, coll, root)

    gems = Part("Ball_08_Storm_Gems", shade=(-0.04, 0.04))
    for s in (1, -1):
        pole = Vector((0, 0, s))
        for rho, R, ch, drop, bulge, top, bev, wall in (
                (0.27, 1.035, 0.02, 0.015, 0.0, "storm_band", "storm_band", "storm_band_dark"),
                (0.2, 1.075, 0.035, 0.03, 0.03, "storm_cyan", "storm_cyan_hi", "storm_cyan_side")):
            corners = [sph(s * (math.pi / 2 - rho), math.radians(-90 + 60 * k)) for k in range(6)]
            make_panel(gems, pole, corners, R=R, gap=0.0, chamfer=ch, drop=drop, base=0.9, bulge=bulge,
                       top=top, bev=bev, wall=wall)
    finish(gems, coll, root)

    # Comma curls: a tapered tail that winds into a spiral. Two rows of eight per half, built once
    # 22.5 deg from the bolt at longitude 0, then mirrored across the bolt meridian and the equator
    # and repeated for every bolt.
    curls = Part("Ball_08_Storm_Curls", shade=(-0.06, 0.06))
    # (latitude, spiral radius, start angle, steps). The tube is as wide as the spiral is tight, so the
    # crescent and its rounded head fill a solid lobe and only a narrow spiral groove stays open.
    rows = [(35, 0.25, 200, 14), (61, 0.15, -30, 10)]
    for lat_deg, rho0, a0_deg, steps in rows:
        P, E, N = frame(math.radians(lat_deg), math.radians(22.5))
        w0 = 0.6 * rho0
        path = []
        for st in range(steps + 1):
            t = -0.3 + 1.3 * st / steps
            rho = rho0 * (1 - 0.6 * max(t, 0))
            ang = math.radians(a0_deg) + t * 1.4 * math.pi
            w = w0 * (1 - 0.25 * max(t - 0.6, 0) / 0.4) if t >= 0 else w0 * (t + 0.3) / 0.3
            path.append(((P + (E * math.cos(ang) + N * math.sin(ang)) * rho).normalized() * 1.02, w))
        ws = [w for _, w in path]
        for lon in bolt_lons:
            for my in (1, -1):
                for mz in (1, -1):
                    m = Matrix.Rotation(lon, 3, "Z") @ Matrix.Diagonal((1, my, mz))
                    pts = [m @ p for p, _ in path]
                    tube(curls, pts, [p.normalized() for p in pts], ws, [w * 0.8 for w in ws], 6, "storm_violet")
    obj = finish(curls, coll, root)
    recolor_tiers(obj, [(0.85, "storm_violet_hi"), (0.35, "storm_violet")], "storm_violet_dark")

    # Bolt: two long triangles, tips up and down, overlapping at the waist into a zigzag.
    bolts = Part("Ball_08_Storm_Bolts", shade=(-0.05, 0.05))
    half_len, width = 0.62, 0.7
    pieces = [([(0.10, 1.0), (-0.34, -0.08), (0.16, 0.04)], 1.16),
              ([(-0.10, -1.0), (0.34, 0.08), (-0.16, -0.04)], 1.17)]
    for lon in bolt_lons:
        O, E, N = frame(0.0, lon)
        for outline, R in pieces:
            pts = [(O + E * (u * width) + N * (v * half_len)).normalized() for u, v in outline]
            make_panel(bolts, sum(pts, Vector()), pts, R=R, gap=0.0, chamfer=0.03, drop=0.035, base=0.95,
                       bulge=0.03, top="storm_bolt", bev="storm_bolt_hi", wall="storm_bolt_side")
    finish(bolts, coll, root)


def ball_09(root, coll):
    import heapq

    rng = random.Random(909)
    # Rock plates are the cells of a jittered Goldberg sphere; a pentagon cell sits on top as the crater.
    verts, tris = geodesic(2)
    v0, _ = ico_base()
    up = v0[0].rotation_difference(Vector((0, 0, 1))).to_matrix()
    dirs = [(up @ p).normalized() for p in verts]
    top = max(range(len(dirs)), key=lambda i: dirs[i].z)
    jit = [p if i == top else (p + rand_tangent(p, rng) * 0.07).normalized() for i, p in enumerate(dirs)]
    corner = [(jit[a] + jit[b] + jit[c]).normalized() for a, b, c in tris]
    cells = {i: [] for i in range(len(jit))}
    for t, tri in enumerate(tris):
        for i in tri:
            cells[i].append(t)
    edge_tris = {}
    for t, (a, b, c) in enumerate(tris):
        for x, y in ((a, b), (b, c), (c, a)):
            edge_tris.setdefault((min(x, y), max(x, y)), []).append(t)
    graph = {t: [] for t in range(len(tris))}
    for ts in edge_tris.values():
        if len(ts) == 2:
            graph[ts[0]].append(ts[1])
            graph[ts[1]].append(ts[0])
    crater = set(cells[top])
    rim = {i for t in crater for i in tris[t]} - {top}

    # Rivers run along plate borders: shortest border path that hugs a guide line down the front.
    guides = [
        [Vector(v).normalized() for v in ((-0.2, -0.3, 0.93), (-0.42, -0.75, 0.5), (-0.38, -0.92, 0.05),
                                           (-0.5, -0.78, -0.38), (-0.4, -0.6, -0.7))],
        [Vector(v).normalized() for v in ((0.2, -0.3, 0.93), (0.48, -0.72, 0.5), (0.55, -0.83, 0.05),
                                           (0.5, -0.72, -0.45), (0.58, -0.48, -0.66))],
    ]
    # The back gets its own pair of rivers (mirrored, slightly turned) so no side is bare rock.
    turn = Quaternion(Vector((0, 0, 1)), math.radians(25))
    guides += [[turn @ Vector((v.x, -v.y, v.z)) for v in g] for g in guides]
    guides.append([Vector(v).normalized() for v in ((0.3, 0.1, 0.93), (0.8, 0.12, 0.5), (0.97, 0.05, 0.0),
                                                     (0.85, 0.22, -0.45), (0.6, 0.25, -0.75))])
    river_edges = set()
    river_samples = []
    for guide in guides:
        samples = [guide[i].lerp(guide[i + 1], s / 10).normalized() for i in range(len(guide) - 1) for s in range(11)]
        start = min(crater, key=lambda t: corner[t].angle(guide[0]))
        end = min(range(len(tris)), key=lambda t: corner[t].angle(guide[-1]))
        best, prev, pq = {start: 0.0}, {}, [(0.0, start)]
        while pq:
            d, t = heapq.heappop(pq)
            if t == end:
                break
            if d > best.get(t, 1e9):
                continue
            for u in graph[t]:
                if t in crater and u in crater:
                    continue
                mid = (corner[t] + corner[u]).normalized()
                w = corner[t].angle(corner[u]) * (1 + 12 * min(mid.angle(s) for s in samples))
                if d + w < best.get(u, 1e9):
                    best[u] = d + w
                    prev[u] = t
                    heapq.heappush(pq, (d + w, u))
        path = [end]
        while path[-1] != start:
            path.append(prev[path[-1]])
        for a, b in zip(path, path[1:]):
            river_edges.add(frozenset((a, b)))
            river_samples += [corner[a].lerp(corner[b], s / 6).normalized() for s in range(7)]

    def river_dist(d):
        return min(d.angle(s) for s in river_samples)

    def ckey(p):
        return (round(p.x, 4), round(p.y, 4), round(p.z, 4))

    tri_of = {ckey(corner[t]): t for t in range(len(tris))}
    river_gap, crater_gap, crevice_gap = 0.12, 0.1, 0.014

    def edge_gap(a, b):
        ta, tb = tri_of.get(ckey(a)), tri_of.get(ckey(b))
        if frozenset((ta, tb)) in river_edges:
            return river_gap
        return crater_gap if ta in crater and tb in crater else crevice_gap

    lava = Part("Ball_09_Volcano_Lava", shade=(-0.06, 0.06))
    pool_z = 0.8

    def lava_key(c):
        if c.z > 0.83:
            return "volc_lava_yellow"
        d = river_dist(c)
        if d < 0.05:
            return "volc_lava_yellow"
        if d < 0.1:
            return "volc_lava_orange"
        return "volc_lava_red" if d < 0.17 else "volc_crevice"

    add_sphere(lava, 5, 0.95, lava_key, seed=910,
               vert_fn=lambda p: Vector((p.x, p.y, min(p.z, pool_z))))
    finish(lava, coll, root)

    rocks = Part("Ball_09_Volcano_Rocks", shade=(-0.08, 0.06))
    for i, p in enumerate(jit):
        if i == top:
            continue
        R = 1.13 if i in rim else rng.uniform(1.0, 1.04)
        base_key = rng.choice(("volc_rock_a", "volc_rock_a", "volc_rock_b", "volc_rock_c"))

        def wall_fn(pts, base_key=base_key):
            n = face_normal(pts)
            c = sum(pts, Vector()) / len(pts)
            horiz = Vector((c.x, c.y, 0))
            if c.z > 0.6 and horiz.length > 1e-4 and n.dot(-horiz.normalized()) > 0.2:
                return "volc_wall_glow"
            if river_dist(c.normalized()) < 0.16:
                return "volc_wall_glow"
            return base_key

        make_panel(rocks, p, [corner[t] for t in cells[i]], R=R, gap=crevice_gap, chamfer=0.05, drop=0.05,
                   base=0.86, bulge=rng.uniform(0.03, 0.06), mids=False, top=base_key, bev=base_key,
                   wall=wall_fn, edge_gap=edge_gap)
    finish(rocks, coll, root)

    spikes = Part("Ball_09_Volcano_Spikes", shade=(-0.07, 0.07))
    for d, length, rad in (((-0.95, -0.15, 0.32), 0.55, 0.22), ((-0.88, -0.3, -0.38), 0.48, 0.21),
                           ((0.97, -0.12, 0.1), 0.52, 0.22), ((0.76, -0.4, -0.5), 0.46, 0.2),
                           ((-0.35, 0.8, 0.45), 0.45, 0.2), ((-0.6, 0.72, -0.35), 0.46, 0.2),
                           ((0.62, 0.7, 0.2), 0.48, 0.21)):
        a = Vector(d).normalized()
        e1, e2 = tangent_basis(a)
        length, rad = length * 0.9, rad * 1.25
        sides = 5
        ring = []
        for k in range(sides):
            ang = 2 * math.pi * k / sides + rng.uniform(-0.2, 0.2)
            r = rad * rng.uniform(0.8, 1.1)
            ring.append(spikes.v(a * 0.86 + (e1 * math.cos(ang) + e2 * math.sin(ang)) * r))
        mid = []
        for k in range(sides):
            ang = 2 * math.pi * (k + 0.5) / sides
            mid.append(spikes.v(a * (0.86 + length * 0.5) + (e1 * math.cos(ang) + e2 * math.sin(ang)) * rad * 0.8
                                + e2 * 0.03))
        tip = spikes.v(a * (0.86 + length) + e1 * rng.uniform(-0.06, 0.06) - Vector((0, 0, 0.04)))
        spikes.f(list(reversed(ring)), "volc_spike")
        for k in range(sides):
            j = (k + 1) % sides
            spikes.f([ring[k], ring[j], mid[k]], "volc_spike")
            spikes.f([ring[j], mid[j], mid[k]], "volc_spike")
            spikes.f([mid[k], mid[j], tip], "volc_spike")
    finish(spikes, coll, root)

    drops = Part("Ball_09_Volcano_Droplets", shade=(-0.05, 0.06))
    profile = [(0.0, -0.24), (0.08, -0.08), (0.115, 0.05), (0.08, 0.15), (0.0, 0.19)]
    for pos, sc, tilt, key in (((0.0, -0.05, 1.45), 1.15, 0.0, "volc_lava_orange"),
                               ((-0.3, -0.05, 1.27), 0.7, -0.35, "volc_lava_yellow"),
                               ((0.32, -0.05, 1.25), 0.62, 0.35, "volc_lava_orange")):
        axis = Quaternion(Vector((0, 1, 0)), tilt) @ Vector((0, 0, 1))
        e1, e2 = tangent_basis(axis)
        sides = 6
        rings = []
        for r, z in profile:
            if r == 0:
                rings.append(drops.v(Vector(pos) + axis * z * sc))
            else:
                rings.append([drops.v(Vector(pos) + axis * z * sc + (e1 * math.cos(2 * math.pi * k / sides)
                                                                     + e2 * math.sin(2 * math.pi * k / sides)) * r * sc)
                              for k in range(sides)])
        for i in range(len(rings) - 1):
            r0, r1 = rings[i], rings[i + 1]
            for k in range(sides):
                j = (k + 1) % sides
                if not isinstance(r0, list):
                    drops.f([r0, r1[j], r1[k]], key)
                elif not isinstance(r1, list):
                    drops.f([r0[k], r0[j], r1], key)
                else:
                    drops.f([r0[k], r0[j], r1[j], r1[k]], key)
    finish(drops, coll, root)
    rotate_parts(coll, Quaternion(Vector((1, 0, 0)), math.radians(24)))


def ball_10(root, coll):
    v0, _ = ico_base()
    rot = orient(v0[0], v0[icosa_neighbor(0)], roll=12)
    rng = random.Random(1010)
    core = Part("Ball_10_Sun_Core", shade=(-0.06, 0.06))
    add_sphere(core, 4, 0.94, lambda c: rng.choice(("sun_core_a", "sun_core_a", "sun_core_b", "sun_core_c")),
               jt=0.02, jr=0.01, seed=1011)
    finish(core, coll, root)
    shell = Part("Ball_10_Sun_Panels", shade=(-0.05, 0.03))
    window = math.cos(math.radians(45))

    def warp(d):
        # Pull the shell toward the front so the open window shrinks to ~40 degrees.
        th = d.angle(FRONT)
        if th < 1e-4 or th > math.pi - 1e-4:
            return d
        return (Quaternion(FRONT.cross(d).normalized(), -math.radians(17) * math.sin(th)) @ d).normalized()

    for kind, cen, corners in soccer_panels(rot):
        if cen.dot(FRONT) > window:
            continue
        cen, corners = warp(cen), [warp(k) for k in corners]
        make_panel(shell, cen, corners, R=1.07, gap=0.028, chamfer=0.06, drop=0.05, base=0.9, bulge=0.04,
                   top=lambda pts: rng.choice(("sun_panel", "sun_panel", "sun_panel_warm")),
                   bev="sun_rim", wall="sun_wall")
    finish(shell, coll, root)
    ring = Part("Ball_10_Sun_Ring", shade=(-0.04, 0.04))
    rq = Quaternion(Vector((0, 1, 0)), math.radians(-17)) @ Quaternion(Vector((1, 0, 0)), math.radians(-12))
    pts = []
    segs = 72
    for k in range(segs):
        a = 2 * math.pi * k / segs
        pts.append(rq @ Vector((math.cos(a) * 1.46, math.sin(a) * 1.46, 0)))
    nrm = [rq @ Vector((0, 0, 1)) for _ in pts]
    tube(ring, pts, nrm, [0.055] * segs, [0.045] * segs, 6, "sun_ring", closed=True)
    finish(ring, coll, root)
    stars = Part("Ball_10_Sun_Stars", shade=(-0.03, 0.04))
    add_star(stars, Vector((-1.2, -0.3, 1.12)), 0.26, "sun_ring")
    add_star(stars, Vector((1.3, -0.3, -0.5)), 0.22, "sun_ring")
    finish(stars, coll, root)


BUILDERS = {"01": ball_01, "02": ball_02, "03": ball_03, "04": ball_04, "05": ball_05,
            "06": ball_06, "07": ball_07, "08": ball_08, "09": ball_09, "10": ball_10}


# ---------------------------------------------------------------------------
# Scene


def get_scene():
    sc = bpy.data.scenes.get(SCENE_NAME) or bpy.data.scenes.new(SCENE_NAME)
    if bpy.context.window is not None:
        bpy.context.window.scene = sc
    return sc


def child_coll(parent, name):
    c = bpy.data.collections.get(name) or bpy.data.collections.new(name)
    if name not in parent.children:
        parent.children.link(c)
    return c


def remove_tree(obj):
    for ch in list(obj.children):
        remove_tree(ch)
    data = obj.data
    bpy.data.objects.remove(obj)
    if isinstance(data, bpy.types.Mesh) and data.users == 0:
        bpy.data.meshes.remove(data)


def setup_stage(sc):
    stage = child_coll(sc.collection, STAGE_COLL)
    world = bpy.data.worlds.get("LP2_World") or bpy.data.worlds.new("LP2_World")
    sc.world = world
    try:
        world.use_nodes = True
    except Exception:
        pass
    # Camera rays see the full lavender backdrop; lighting uses a dimmer copy for contrast.
    nt = world.node_tree
    nt.nodes.clear()
    out = nt.nodes.new("ShaderNodeOutputWorld")
    light_bg = nt.nodes.new("ShaderNodeBackground")
    light_bg.inputs[0].default_value = lin("#ECEAFA")
    light_bg.inputs[1].default_value = 0.55
    cam_bg = nt.nodes.new("ShaderNodeBackground")
    cam_bg.inputs[0].default_value = lin("#E9E6F8")
    cam_bg.inputs[1].default_value = 1.0
    path = nt.nodes.new("ShaderNodeLightPath")
    mix = nt.nodes.new("ShaderNodeMixShader")
    nt.links.new(path.outputs["Is Camera Ray"], mix.inputs[0])
    nt.links.new(light_bg.outputs[0], mix.inputs[1])
    nt.links.new(cam_bg.outputs[0], mix.inputs[2])
    nt.links.new(mix.outputs[0], out.inputs["Surface"])

    floor = bpy.data.objects.get("LP2_Floor")
    if floor is None:
        bm = bmesh.new()
        bmesh.ops.create_grid(bm, x_segments=1, y_segments=1, size=1)
        floor = mesh_object("LP2_Floor", bm)
        floor.data.materials.append(material("stage_floor"))
        stage.objects.link(floor)
    floor.location = (0, 2, 0)
    floor.scale = (300, 300, 1)

    sun = bpy.data.objects.get("LP2_Sun")
    if sun is None:
        sun = bpy.data.objects.new("LP2_Sun", bpy.data.lights.new("LP2_Sun", "SUN"))
        stage.objects.link(sun)
    sun.data.energy = 3.0
    sun.data.angle = math.radians(20)
    sun.data.color = (1.0, 0.98, 0.96)
    sun.rotation_euler = Vector((0.45, 0.55, -0.7)).to_track_quat("-Z", "Y").to_euler()

    cam = bpy.data.objects.get("LP2_Camera")
    if cam is None:
        cam = bpy.data.objects.new("LP2_Camera", bpy.data.cameras.new("LP2_Camera"))
        stage.objects.link(cam)
    cam.data.lens = 35
    target = Vector((0, 2.3, 0.9))
    cam.location = Vector((0, -17.5, 11.5))
    cam.rotation_euler = (target - cam.location).to_track_quat("-Z", "Y").to_euler()
    sc.camera = cam

    sc.render.engine = "BLENDER_EEVEE"
    sc.view_settings.view_transform = "Standard"
    sc.view_settings.look = "None"
    sc.view_settings.exposure = 0.0
    sc.render.resolution_x = 1920
    sc.render.resolution_y = 1080
    sc.render.film_transparent = False
    for attr, val in (("taa_render_samples", 48), ("use_shadows", True), ("use_raytracing", True),
                      ("use_fast_gi", True)):
        try:
            setattr(sc.eevee, attr, val)
        except Exception:
            pass


def build():
    sc = get_scene()
    setup_stage(sc)
    pack = child_coll(sc.collection, PACK_COLL)
    built = []
    for code, name in BALLS:
        if ONLY and code not in ONLY:
            continue
        coll = child_coll(pack, name)
        old = bpy.data.objects.get(name)
        if old is not None:
            remove_tree(old)
        for ob in list(coll.objects):
            remove_tree(ob)
        root = bpy.data.objects.new(name, None)
        root.empty_display_type = "SPHERE"
        root.empty_display_size = 1.0
        coll.objects.link(root)
        x, y = LAYOUT[code]
        root.location = (x, y, 1.0)
        BUILDERS[code](root, coll)
        tris = 0
        for ob in coll.objects:
            if ob.type == "MESH":
                tris += sum(len(p.vertices) - 2 for p in ob.data.polygons)
        built.append((name, tris))
    return built


result = {"built": build()}
