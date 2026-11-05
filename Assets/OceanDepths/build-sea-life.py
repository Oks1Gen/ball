"""Build the reef wildlife pack with Blender: blender -b -P build-sea-life.py."""
import json
import math
from pathlib import Path

import bmesh
import bpy

OUT = Path(__file__).resolve().parent
BLACK = "132039"
IVORY = "FFF0CE"


def linear(channel):
    value = channel / 255
    return value / 12.92 if value < 0.04045 else ((value + 0.055) / 1.055) ** 2.4


def material(color):
    existing = bpy.data.materials.get(color)
    if existing:
        return existing
    mat = bpy.data.materials.new(color)
    rgba = tuple(linear(int(color[i:i + 2], 16)) for i in (0, 2, 4)) + (1,)
    mat.diffuse_color = rgba
    mat.use_nodes = True
    shader = mat.node_tree.nodes.get("Principled BSDF")
    shader.inputs["Base Color"].default_value = rgba
    shader.inputs["Roughness"].default_value = 0.46
    return mat


def mesh(group, name, vertices, faces, colors):
    data = bpy.data.meshes.new(name)
    data.from_pydata(vertices, [], faces)
    obj = bpy.data.objects.new(name, data)
    group.objects.link(obj)
    palette = list(dict.fromkeys(colors))
    for color in palette:
        data.materials.append(material(color))
    for face, color in zip(data.polygons, colors, strict=True):
        face.material_index = palette.index(color)
    edit = bmesh.new()
    edit.from_mesh(data)
    bmesh.ops.recalc_face_normals(edit, faces=list(edit.faces))
    assert all(edge.is_manifold for edge in edit.edges), name
    assert all(face.calc_area() > 0.000001 for face in edit.faces), name
    edit.to_mesh(data)
    edit.free()
    data.update()
    return obj


def loft(group, name, rings, paint):
    width = len(rings[0])
    last = (len(rings) - 1) * width
    faces = [tuple(reversed(range(width))), tuple(range(last, last + width))]
    colors = [paint(0, 0), paint(len(rings) - 2, 0)]
    for row in range(len(rings) - 1):
        for k in range(width):
            a = row * width + k
            b = row * width + (k + 1) % width
            faces.append((a, b, b + width, a + width))
            colors.append(paint(row, k))
    return mesh(group, name, [vertex for ring in rings for vertex in ring], faces, colors)


def fish_body(group, rings, paint):
    sections = [
        [(x, half * math.cos(k * math.tau / 8), center + tall * math.sin(k * math.tau / 8))
         for k in range(8)]
        for x, half, tall, center in rings
    ]
    loft(group, "Hull", sections, paint)


def fin(group, name, points, thickness, base, edge=None):
    center = tuple(sum(p[axis] for p in points) / len(points) for axis in range(3))
    a = len(points)
    if edge:
        inside = [tuple(center[axis] + .83 * (p[axis] - center[axis]) for axis in range(3)) for p in points]
        front = [(x, y + thickness * .6, z) for x, y, z in inside]
        back = [(x, y - thickness * .6, z) for x, y, z in inside]
        vertices = points + front + back + [(center[0], center[1] + thickness, center[2]),
                                          (center[0], center[1] - thickness, center[2])]
        faces = []
        colors = []
        for k in range(a):
            nxt = (k + 1) % a
            faces.append((k, nxt, nxt + a, k + a))
            colors.append(edge)
            faces.append((nxt, k, k + 2 * a, nxt + 2 * a))
            colors.append(edge)
            faces.extend([(k + a, nxt + a, 3 * a), (nxt + 2 * a, k + 2 * a, 3 * a + 1)])
            colors.extend([base, base])
        return mesh(group, name, vertices, faces, colors)
    vertices = points + [(center[0], center[1] + thickness, center[2]),
                         (center[0], center[1] - thickness, center[2])]
    faces = []
    colors = []
    for k in range(a):
        nxt = (k + 1) % a
        faces.extend([(k, nxt, a), (nxt, k, a + 1)])
        colors.extend([base] * 2)
    mesh(group, name, vertices, faces, colors)


def eye(group, x, y, z, scale):
    for side in (-1, 1):
        for label, dx, dz, depth, radius, color in (
            ("Eye", 0, 0, 0, 0.165, BLACK),
            ("Glint", 0.044, 0.051, 0.035, 0.054, "FFFFFF"),
        ):
            ring = [(x + scale * (dx + radius * math.cos(k * math.tau / 8)),
                     side * (y + scale * depth),
                     z + scale * (dz + radius * math.sin(k * math.tau / 8))) for k in range(8)]
            fin(group, label, ring, scale * (0.064 if label == "Eye" else 0.018), color)


def species(scene, name):
    root = bpy.data.collections.new(name)
    scene.collection.children.link(root)
    groups = []
    for label in ("Body", "Fins", "Features"):
        group = bpy.data.collections.new(name + " " + label)
        root.children.link(group)
        groups.append(group)
    return root, groups


def box(group, name, center, size, color):
    vertices = [tuple(center[axis] + size[axis] * sign[axis] / 2 for axis in range(3))
                for sign in ((-1,-1,-1),(1,-1,-1),(1,1,-1),(-1,1,-1),
                             (-1,-1,1),(1,-1,1),(1,1,1),(-1,1,1))]
    mesh(group, name, vertices,
         [(0,3,2,1),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)], [color] * 6)


FISH = {
    "YellowTang": {
        "rings": [(-1.65,.13,.22,0),(-1.22,.34,.64,0),(-.66,.51,.94,.01),(.28,.53,1.0,.02),
                  (1.02,.41,.78,.02),(1.53,.29,.42,-.09),(1.88,.17,.15,-.22),(2.08,.12,.09,-.23)],
        "colors": ("FFD435", "FFEC65", "EFB11B"), "fin": "FFCE27", "tail": "FFCC26",
        "dorsal": [(-1.46,.3),(-1.27,.92),(-.98,1.51),(-.5,1.65),(.2,1.46),(.85,.75)],
        "eye": (1.28,.35,.19,1),
    },
    "Clownfish": {
        "rings": [(-1.56,.16,.24,0),(-1.24,.24,.40,0),(-1.12,.30,.52,0),(-.70,.44,.70,0),
                  (-.59,.48,.76,0),(.22,.56,.81,0),(.32,.56,.80,0),(.77,.52,.73,0),
                  (.87,.49,.70,0),(1.45,.37,.48,-.02),(1.76,.22,.21,-.11),(1.91,.12,.12,-.13)],
        "colors": ("F87921", "FFA335", "D84711"), "fin": "F66D1D", "tail": "FF8121",
        "dorsal": [(-1.18,.29),(-.80,.89),(-.47,.86),(-.30,1.04),(.12,1.30),(.56,1.28),(.90,.66)],
        "eye": (1.39,.38,.17,1.05),
    },
    "BlueTang": {
        "rings": [(-1.76,.14,.21,0),(-1.20,.28,.53,0),(-.66,.43,.82,.01),(.23,.50,.91,.04),
                  (.90,.44,.76,.03),(1.44,.29,.47,-.08),(1.80,.17,.16,-.2),(1.93,.12,.10,-.2)],
        "colors": ("267DEA", "318FFC", "16ACC3"), "fin": "234BD1", "tail": "FFE039",
        "dorsal": [(-1.59,.27),(-1.20,.79),(-.65,1.12),(.01,1.23),(.65,1.15),(1.07,.63)],
        "eye": (1.34,.36,.19,1),
    },
    "Butterflyfish": {
        "rings": [(-1.54,.15,.23,0),(-1.17,.31,.68,0),(-.89,.40,.91,0),(-.65,.45,1.04,0),
                  (.14,.46,1.05,.02),(.53,.40,.92,.01),(.88,.31,.72,-.03),(1.16,.24,.48,-.12),
                  (1.54,.16,.19,-.23),(1.83,.11,.09,-.25),(2.01,.08,.07,-.24)],
        "colors": ("FCE4B7", "FFF1CE", "E3BD84"), "fin": "F8C324", "tail": "FFCB30",
        "dorsal": [(-1.39,.35),(-1.19,1.18),(-.68,1.48),(-.12,1.50),(.45,1.32),(.79,.69)],
        "eye": (1.08,.28,.19,.93),
    },
}


def make_fish(scene, name, spec):
    root, (body, fins, details) = species(scene, name)

    def paint(row, k):
        if name == "Clownfish":
            if row in (1, 3, 5, 7):
                return BLACK
            if row in (2, 6):
                return IVORY
        if name == "BlueTang" and row in (1, 2, 3, 4) and k in (0, 3):
            return BLACK
        if name == "Butterflyfish" and row in (2, 6):
            return "322B37"
        return spec["colors"][1 if k in (1, 2) else 2 if k in (5, 6) else 0]

    fish_body(body, spec["rings"], paint)
    dorsal = spec["dorsal"]
    for label, line, color in (
        ("Dorsal", dorsal, spec["fin"]),
        ("Anal", [(x - .12, -.74 * z) for x, z in dorsal[:-1]] + [(0.31,-.46)], spec["fin"]),
        ("Tail", [(-1.38,.11),(-2.34,.75),(-2.30,-.62),(-1.38,-.12)], spec["tail"]),
    ):
        fin(fins, label, [(x, 0, z) for x, z in line], .125, color,
            BLACK if name == "Clownfish" else None)
    for side in (-1, 1):
        fin(fins, "Pectoral", [(x, y * side, z) for x, y, z in
            [(0.64,.36,-.07),(-.05,.60,-.48),(-.62,.58,-.28),(-.10,.47,.03)]],
            .09, "FFD544" if name == "BlueTang" else spec["fin"])
    eye(details, *spec["eye"])
    return root


def manta(scene):
    root, (body, fins, details) = species(scene, "MantaRay")
    # Wing cross-sections follow the leading edge, shoulder, belly and trailing edge.
    sections = [
        (0, 4.60, 1.50, -1.25, -4.35, 0, .98),
        (2.60, 4.22, 1.55, -.85, -3.90, -.06, .83),
        (5.30, 3.15, .90, -.70, -2.99, -.19, .55),
        (8.05, 2.26, .10, -.80, -1.97, -.07, .34),
        (10.60, 1.47, -.30, -1.13, -1.63, .59, .20),
        (12.55, .82, -.52, -1.04, -1.28, 1.47, .10),
        (13.65, -.78, -.94, -1.12, -1.27, 2.59, .039),
    ]
    rings = []
    for x, front, chest, belly, rear, z, depth in sections:
        rings.append([(x,y,z+depth*h) for y,h in
                      [(front,0),(chest,.92),(belly,.66),(rear,-.025),(belly,-.45),(chest,-.62)]])
    rings = [ [(-x, y, z) for x, y, z in ring] for ring in reversed(rings[1:]) ] + rings

    def paint(row, k):
        outer = min(row, 11-row)
        if k in (3, 4, 5):
            return "DCE6F6" if k == 4 else "B9CBEA"
        if k == 0 and outer < 2:
            return "7A8AC1"
        return ("384989", "2A3B79", "243568")[k]

    loft(body, "Wings", rings, paint)
    for sign in (-1, 1):
        # Two broad cyan markings sit against the shoulder, with hand-matched wing camber.
        for i, points in enumerate((
            [(3.75,2.10,.548),(5.76,1.74,.301),(7.57,.90,.192),(5.96,1.13,.376),(4.04,1.57,.568)],
            [(4.95,.79,.446),(6.38,.54,.409),(8.50,-.15,.355),(6.93,.16,.408),(5.18,.22,.425)],
        )):
            top = [(x * sign,y,z + .070) for x,y,z in points]
            bottom = [(x,y,z-.085) for x,y,z in top]
            loft(details, "Shoulder stripe", [bottom, top], lambda *_: ("23D8EE","10BCD8")[i])
        horn = [(2.20,3.45,.06,.55),(2.45,4.40,.04,.53),(2.79,5.44,.11,.43),
                (3.22,6.20,.27,.31),(3.47,6.62,.65,.21),(3.33,6.74,.94,.12)]
        horn_rings = [[(sign*(x+r*math.cos(k*math.tau/6)),y,z+r*math.sin(k*math.tau/6))
                       for k in range(6)] for x,y,z,r in horn]
        loft(fins,"Cephalic lobe",horn_rings,lambda row,k: "DFE9FF" if row >= 3 or k in (3,4) else "354882")
        box(details, "Eye", (sign * 2.57, 3.65, .41), (.62, .54, .70), BLACK)
        box(details, "Eye glint", (sign * 2.57, 3.93, .59), (.18, .035, .19), "FFFFFF")
    tail = [(0,-3.8,.03,.51),(.04,-5.1,.00,.36),(.18,-7.1,.08,.24),(.48,-9.20,.26,.14),
            (.95,-10.70,.57,.08),(1.55,-12.10,1.02,.025)]
    tail_rings = [[(x+r*math.cos(k*math.tau/6),y,z+r*.64*math.sin(k*math.tau/6))
                   for k in range(6)] for x,y,z,r in tail]
    loft(fins, "Tail", tail_rings, lambda *_: "28396F")
    return root


def studio_payload(roots):
    result = {}
    for root in roots:
        result[root.name] = []
        for group in root.children:
            vertices, triangles = [], []
            for obj in group.objects:
                data = obj.data
                data.calc_loop_triangles()
                offset = len(vertices)
                vertices.extend(tuple(round(a, 4) for a in (v.co.x, v.co.z, -v.co.y)) for v in data.vertices)
                triangles.extend(([offset+i+1 for i in t.vertices], data.materials[t.material_index].name)
                                 for t in data.loop_triangles)
            assert 0 < len(triangles) < 1000
            result[root.name].append({"name": group.name.split(" ")[-1], "v": vertices, "t": triangles})
    return result


def main():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    scene = bpy.context.scene
    scene.name = "Ocean Depths Sea Life"
    roots = [make_fish(scene, name, spec) for name, spec in FISH.items()] + [manta(scene)]
    payload = studio_payload(roots)
    (OUT / "sea-life-geometry.json").write_text(json.dumps(payload, separators=(",", ":")), encoding="utf-8")
    for root, x in zip(roots, (7, 14, 21, 28, -11), strict=True):
        origin = bpy.data.objects.new(root.name, None)
        root.objects.link(origin)
        origin.empty_display_size = 0.5
        origin.location.x = x
        for group in root.children:
            for obj in group.objects:
                obj.parent = origin
    bpy.context.preferences.filepaths.save_version = 0
    bpy.ops.wm.save_as_mainfile(filepath=str(OUT / "sea-life.blend"))
    bpy.ops.export_scene.gltf(filepath=str(OUT / "sea-life.glb"), export_format="GLB", export_yup=True)
    bpy.ops.export_scene.fbx(filepath=str(OUT / "sea-life.fbx"), object_types={"MESH", "EMPTY"}, add_leaf_bones=False)
    print({key: sum(len(group["t"]) for group in value) for key, value in payload.items()})


if __name__ == "__main__":
    main()
