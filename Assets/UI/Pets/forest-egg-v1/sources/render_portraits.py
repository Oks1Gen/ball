"""Stage the saved Forest Egg models for front-left UI portrait generation."""

import sys
from pathlib import Path

import bpy
from bpy_extras.object_utils import world_to_camera_view
from mathutils import Vector


SOURCES = Path(__file__).resolve().parent
PROJECT = SOURCES.parents[4]
MODELS = PROJECT / 'Assets' / 'Pets' / 'ForestEgg' / 'models'
PETS = ('BloomFox', 'MoonOwl', 'GroveGuardian')


def aim(obj, point):
    obj.rotation_euler = (Vector(point) - obj.location).to_track_quat('-Z', 'Y').to_euler()


for pet in sys.argv[sys.argv.index('--')+1:] or PETS:
    bpy.ops.wm.open_mainfile(filepath=str(MODELS / pet / 'v1' / 'model' / f'{pet}.blend'))
    scene = bpy.context.scene
    scene.render.engine = 'CYCLES'
    scene.cycles.samples = 28
    scene.cycles.use_denoising = True
    scene.render.film_transparent = True
    scene.render.image_settings.file_format = 'PNG'
    scene.render.image_settings.color_mode = 'RGBA'
    scene.render.resolution_x = scene.render.resolution_y = 768
    scene.render.resolution_percentage = 100
    scene.view_settings.view_transform = 'Standard'
    scene.view_settings.look = 'None'
    scene.world = bpy.data.worlds.new('Portrait fill')
    scene.world.use_nodes = True
    scene.world.node_tree.nodes.get('Background').inputs[0].default_value = (.96, .97, 1, 1)
    scene.world.node_tree.nodes.get('Background').inputs[1].default_value = .45

    # Stage the asymmetric tails on the visible side for the left-facing icon.
    root = bpy.data.objects[pet]
    if pet != 'MoonOwl':
        root.scale.x = -1
    for label, loc, energy, size in (
        ('Key', (-3.9, -4.5, 6.6), 420, 5),
        ('Fill', (4.2, -3.6, 4.6), 185, 4.4),
        ('Rim', (1.6, 4.4, 5.7), 275, 4.5),
    ):
        data = bpy.data.lights.new(label, 'AREA')
        data.energy, data.size = energy, size
        obj = bpy.data.objects.new(label, data)
        scene.collection.objects.link(obj)
        obj.location = loc
        aim(obj, (0, .55, 1.45))

    cam = bpy.data.objects.new('Portrait camera', bpy.data.cameras.new('Portrait camera'))
    scene.collection.objects.link(cam)
    scene.camera = cam
    cam.data.type = 'ORTHO'
    cam.data.ortho_scale = 4.5
    cam.location = (-5.05, -10.5, 5.38)
    aim(cam, (0, .25, 1.48))
    bpy.context.view_layer.update()

    projected = []
    graph = bpy.context.evaluated_depsgraph_get()
    for obj in root.children:
        if obj.type not in {'MESH', 'CURVE'}:
            continue
        evaluated = obj.evaluated_get(graph)
        data = evaluated.to_mesh()
        projected.extend(world_to_camera_view(scene, cam, evaluated.matrix_world @ v.co) for v in data.vertices)
        evaluated.to_mesh_clear()

    left, right = min(p.x for p in projected), max(p.x for p in projected)
    bottom, top = min(p.y for p in projected), max(p.y for p in projected)
    span = max(right - left, top - bottom)
    old_scale = cam.data.ortho_scale
    cam.data.ortho_scale = old_scale * span / .83
    cam.data.shift_x = ((left + right) * .5 - .5) * old_scale / cam.data.ortho_scale
    cam.data.shift_y = ((bottom + top) * .5 - .5) * old_scale / cam.data.ortho_scale
    scene.render.filepath = str(SOURCES / f'{pet}-render.png')
    bpy.ops.render.render(write_still=True)
