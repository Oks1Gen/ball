"""Consolidate each authored pet into one textured Roblox mesh."""

import argparse
import json
import struct
import sys
import zlib
from pathlib import Path

import bpy
import numpy as np


HERE = Path(__file__).resolve().parent
parser = argparse.ArgumentParser()
parser.add_argument('--egg', default='ForestEgg')
parser.add_argument('--output', type=Path, default=HERE)
parser.add_argument('pets', nargs='*', default=('BloomFox', 'MoonOwl', 'GroveGuardian'))
args = parser.parse_args(sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else [])
MODELS = HERE.parents[3] / 'Assets' / 'Pets' / args.egg / 'models'
OUTPUT = args.output.resolve()
OUTPUT.mkdir(parents=True, exist_ok=True)
ATLAS = 1024
CELL = 341
PAD = 4
INNER = CELL - 2 * PAD


def save_png(path, array):
    def chunk(kind, data):
        return struct.pack('>I', len(data)) + kind + data + struct.pack('>I', zlib.crc32(kind + data))
    scanlines = b''.join(b'\0' + row.tobytes() for row in array[::-1])
    path.write_bytes(
        b'\x89PNG\r\n\x1a\n'
        + chunk(b'IHDR', struct.pack('>IIBBBBB', ATLAS, ATLAS, 8, 2, 0, 0, 0))
        + chunk(b'IDAT', zlib.compress(scanlines, 8))
        + chunk(b'IEND', b'')
    )


def material_image(material):
    if material.use_nodes:
        return next((n.image for n in material.node_tree.nodes if n.type == 'TEX_IMAGE' and n.image), None)
    return None


for name in args.pets:
    bpy.ops.wm.open_mainfile(filepath=str(MODELS / name / 'v1' / 'model' / (name + '.blend')))
    graph = bpy.context.evaluated_depsgraph_get()
    sources = [o for o in bpy.context.scene.objects if o.type in {'MESH', 'CURVE'}]
    materials = list(dict.fromkeys(m for o in sources for m in o.data.materials))
    atlas = np.full((ATLAS, ATLAS, 3), 255, dtype=np.uint8)
    uv_tiles = {}
    textures = [m for m in materials if material_image(m)]
    for index, mat in enumerate(textures):
        source = material_image(mat)
        width, height = source.size
        values = np.empty(width * height * 4, dtype=np.float32)
        source.pixels.foreach_get(values)
        pixels = values.reshape(height, width, 4)
        # Clover's authored blush is a translucent decal over the cream body.
        # Roblox's opaque shared atlas needs that background composited in.
        if mat.name == 'CB_Blush_Soft':
            coat = bpy.data.materials['CB_Cream']['SourceSRGB'].lstrip('#')
            background = np.array([int(coat[i:i+2], 16) / 255 for i in (0, 2, 4)])
            pixels[:, :, :3] = pixels[:, :, :3] * pixels[:, :, 3:4] + background * (1 - pixels[:, :, 3:4])
        # Sample the middle of each destination texel. Border extrusion stops atlas bleed.
        xs = np.clip(np.floor((np.arange(CELL) - PAD + .5) * width / INNER).astype(int), 0, width - 1)
        ys = np.clip(np.floor((np.arange(CELL) - PAD + .5) * height / INNER).astype(int), 0, height - 1)
        x, y = (index % 3) * CELL, (index // 3) * CELL
        atlas[y:y+CELL, x:x+CELL] = np.rint(pixels[np.ix_(ys, xs)][:, :, :3] * 255)
        uv_tiles[mat] = ((x + PAD + .5) / ATLAS, (y + PAD + .5) / ATLAS, (INNER - 1) / ATLAS)
    for index, mat in enumerate(m for m in materials if m not in uv_tiles):
        code = (mat.get('sRGB') or mat['SourceSRGB']).lstrip('#')
        x, y = (index % 16) * 64, 2 * CELL + (index // 16) * 64
        atlas[y:y+64, x:x+64] = [int(code[i:i+2], 16) for i in (0, 2, 4)]
        uv_tiles[mat] = ((x + 32) / ATLAS, (y + 32) / ATLAS, 0)
    atlas_path = OUTPUT / (name + '-atlas.png')
    save_png(atlas_path, atlas)
    image = bpy.data.images.load(str(atlas_path), check_existing=False)
    image.pack()
    packed = bpy.data.materials.new(name + ' atlas')
    packed.use_nodes = True
    nodes = packed.node_tree.nodes
    texture = nodes.new('ShaderNodeTexImage')
    texture.image = image
    packed.node_tree.links.new(texture.outputs['Color'], nodes.get('Principled BSDF').inputs['Base Color'])
    nodes.get('Principled BSDF').inputs['Roughness'].default_value = .39

    bpy.ops.object.select_all(action='DESELECT')
    for original in sources:
        evaluated = original.evaluated_get(graph)
        mesh = bpy.data.meshes.new_from_object(evaluated, depsgraph=graph)
        mesh.transform(evaluated.matrix_world)
        old_materials = list(mesh.materials)
        uv = mesh.uv_layers.active or mesh.uv_layers.new(name='UVMap')
        uv.name = 'UVMap'
        for polygon in mesh.polygons:
            u0, v0, scale = uv_tiles[old_materials[polygon.material_index]]
            for li in polygon.loop_indices:
                u, v = uv.data[li].uv
                uv.data[li].uv = (u0 + min(1, max(0, u))*scale, v0 + min(1, max(0, v))*scale)
        mesh.materials.clear()
        mesh.materials.append(packed)
        part = bpy.data.objects.new(original.name + ' packed', mesh)
        bpy.context.scene.collection.objects.link(part)
        part.select_set(True)
        bpy.context.view_layer.objects.active = part
    bpy.ops.object.join()
    body = bpy.context.object
    body.name = name
    body.data.calc_loop_triangles()
    triangles = len(body.data.loop_triangles)
    assert 0 < triangles < 10000
    assert all(triangle.area > 0 for triangle in body.data.loop_triangles)
    bpy.ops.export_scene.gltf(
        filepath=str(OUTPUT / (name + '.glb')), export_format='GLB', use_selection=True,
        export_apply=True, export_animations=False,
    )
    print('FOREST_MODEL', name, json.dumps({'triangles': triangles, 'dimensions': list(body.dimensions)}), flush=True)
