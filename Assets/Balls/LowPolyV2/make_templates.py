"""Write RojoTest/src/shared/BallTemplates.rbxmx from the uploaded Low Poly V2 meshes.

Run with plain Python after export_roblox.py and the Open Cloud upload. MESHES holds the inner MeshIds
that game:GetObjects returned for the uploaded Model, plus the size and position Roblox gave each
MeshPart. Roblox's glTF importer turns the scene 180 deg about Y, so each part is turned back:
ball centre at the origin, front (Blender -Y) facing -Z. FitSize is the largest outer dimension;
BallVisuals scales it to the requested diameter so every ball, accessories included, looks the
same size, while the pivot stays at the ball centre.
"""
import base64
import os
import struct

ROOT = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(ROOT, "..", "..", "..", "RojoTest", "src", "shared", "BallTemplates.rbxmx")
MODEL_ASSET = 72414326263846
ATLAS = "rbxassetid://125793810196493"

# Game stone id -> (part name, MeshId, Size, Position as imported).
MESHES = [
    ("Pebble", "Ball_01_Rubber", 73462181734739, (1.999594, 2.016529, 2.016888), (0.008723, 0.002350, 0.002362)),
    ("Smooth", "Ball_02_Classic", 84909701317103, (1.998990, 1.999090, 2.038552), (0, 0, 0)),
    ("Golden", "Ball_03_Beach", 88101141057174, (2.001665, 1.989432, 1.979995), (-0.000240, 0.004131, -0.002387)),
    ("Ruby", "Ball_04_Basketball", 112644403609426, (1.988902, 1.989701, 1.994572), (-0.000871, -0.000988, 0.001732)),
    ("Emerald", "Ball_05_Leather", 130090105407534, (2.070000, 2.042268, 2.117337), (0, 0, 0)),
    ("Galaxy", "Ball_06_Steel", 75431251297599, (1.967899, 1.967899, 1.967899), (0, 0, 0)),
    ("Rainbow", "Ball_07_Gold", 85649873211801, (2.419975, 2.319319, 2.048400), (0.210013, 0.155783, 0)),
    ("DragonSun", "Ball_08_Storm", 125908551287478, (2.372130, 2.214500, 2.372130), (0, 0, 0)),
    ("BlackHole", "Ball_09_Volcano", 77213453662376, (2.573266, 2.561936, 2.084739), (0.022310, 0.222946, -0.001370)),
    ("WorldCreator", "Ball_10_Sun", 110588632339103, (2.980000, 2.465058, 2.963787), (0.030000, 0.143521, 0)),
]


def attributes(values):
    # Roblox attribute blob: u32 count, then per entry u32 name length, name, type byte, value.
    blob = struct.pack("<I", len(values))
    for name, number in values.items():
        raw = name.encode()
        blob += struct.pack("<I", len(raw)) + raw + b"\x06" + struct.pack("<d", number)
    return base64.b64encode(blob).decode()


def vec(tag, name, v):
    return f'<{tag} name="{name}"><X>{v[0]}</X><Y>{v[1]}</Y><Z>{v[2]}</Z></{tag}>'


items = []
for i, (game_id, part, mesh, size, pos) in enumerate(MESHES):
    # Rotation 180 deg about Y: (x, y, z) -> (-x, y, -z).
    x, y, z = -pos[0], pos[1], -pos[2]
    cframe = (f'<CoordinateFrame name="CFrame"><X>{x}</X><Y>{y}</Y><Z>{z}</Z>'
              "<R00>-1</R00><R01>0</R01><R02>0</R02><R10>0</R10><R11>1</R11><R12>0</R12>"
              "<R20>0</R20><R21>0</R21><R22>-1</R22></CoordinateFrame>")
    props = "".join([
        f'<string name="Name">{part}</string>',
        vec("Vector3", "Size", size),
        cframe,
        '<Color3 name="Color"><R>1</R><G>1</G><B>1</B></Color3>',
        '<token name="Material">272</token>',
        f'<Content name="MeshId"><url>rbxassetid://{mesh}</url></Content>',
        f'<Content name="TextureID"><url>{ATLAS}</url></Content>',
        '<bool name="Anchored">true</bool><bool name="CanCollide">false</bool>',
        '<bool name="CanTouch">false</bool><bool name="CanQuery">false</bool>',
        '<bool name="DoubleSided">false</bool>',
    ])
    # Fit by the outer bounds so a ball with a ring, spark or spikes looks no bigger than a plain one.
    fit = {"FitSize": max(size)}
    model_props = (f'<string name="Name">{game_id}</string>'
                   f'<BinaryString name="AttributesSerialize">{attributes(fit)}</BinaryString>')
    items.append(f'<Item class="Model" referent="MODEL{i}"><Properties>{model_props}</Properties>'
                 f'<Item class="MeshPart" referent="PART{i}"><Properties>{props}</Properties></Item></Item>')

xml = ('<roblox version="4"><External>null</External><External>nil</External>'
       '<Item class="Folder" referent="ROOT"><Properties><string name="Name">BallTemplates</string></Properties>'
       + "".join(items) + "</Item></roblox>")
with open(OUT, "w", encoding="utf-8", newline="") as f:
    f.write(xml)
print("wrote", os.path.normpath(OUT), len(MESHES), "templates")
