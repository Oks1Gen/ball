import json
import math
from pathlib import Path
import bpy
from mathutils import Vector

OUT=Path(__file__).resolve().parent
expected=sum(json.loads((OUT/'validation.json').read_text())['triangles'].values())
checks={}
for ext,op in [('glb',bpy.ops.import_scene.gltf),('fbx',bpy.ops.import_scene.fbx)]:
    bpy.ops.wm.read_factory_settings(use_empty=True)
    op(filepath=str(OUT/f'location-kit.{ext}'))
    tris=0
    for o in bpy.context.scene.objects:
        if o.type=='MESH':o.data.calc_loop_triangles();tris+=len(o.data.loop_triangles)
    assert tris==expected,(ext,tris,expected)
    checks[ext]={'triangles':tris,'meshes':sum(o.type=='MESH' for o in bpy.context.scene.objects)}
bpy.ops.wm.open_mainfile(filepath=str(OUT/'location-kit.blend'))
scene=bpy.context.scene
for i,empty in enumerate([o for o in scene.objects if o.type=='EMPTY']):
    empty.location=(i%3*27, i//3*34,0)
    # The squid uses a much larger silhouette in world; normalize it just for this sheet.
    if empty.name=='AbyssSquid':empty.scale=(.6,)*3
scene.render.engine='CYCLES';scene.cycles.samples=16
scene.render.resolution_x=1400;scene.render.resolution_y=1100;scene.render.resolution_percentage=100
if scene.world is None:scene.world=bpy.data.worlds.new('PreviewWorld')
scene.world.color=(.35,.35,.35)
scene.world.use_nodes=True
scene.world.node_tree.nodes.get('Background').inputs['Color'].default_value=(.65,.7,.8,1)
scene.world.node_tree.nodes.get('Background').inputs['Strength'].default_value=.85
scene.view_settings.view_transform='Standard'
for loc,power,size in [((20,-30,70),4200,50),((-30,40,30),2800,40),((70,60,50),4000,30)]:
    bpy.ops.object.light_add(type='AREA',location=loc);o=bpy.context.object;o.data.energy=power;o.data.shape='DISK';o.data.size=size
bpy.ops.object.camera_add();camera=bpy.context.object;scene.camera=camera;camera.data.type='ORTHO';camera.data.ortho_scale=100
target=Vector((27,28,8))
for name,vector in [('front',(65,-100,70)),('back',(-65,100,65)),('top',(0,-1,135)),('underside',(40,-100,-60))]:
    camera.location=target+Vector(vector);camera.rotation_euler=(target-camera.location).to_track_quat('-Z','Y').to_euler()
    scene.render.filepath=str(OUT/f'kit-{name}.png');bpy.ops.render.render(write_still=True)
(OUT/'roundtrip-validation.json').write_text(json.dumps(checks,indent=2),encoding='utf8')
print(checks)
