"""Six surface views plus an approximate 5.5-stud block-character scale check."""
import bpy, math
from pathlib import Path
from mathutils import Vector

BASE=Path(__file__).resolve().parent.parent
WORK=BASE/'work'
s=bpy.data.scenes['Ocean Eggs • Common to Legendary'];bpy.context.window.scene=s
roots=sorted([o for o in s.objects if o.type=='EMPTY' and 'rarity' in o],key=lambda o:o.name)
camera=s.camera
floor=bpy.data.objects['Preview_Ground']
def aim(pos,target=(0,0,2.3)):
    camera.location=pos
    camera.rotation_euler=(Vector(target)-camera.location).to_track_quat('-Z','Y').to_euler()
def render(name):
    s.render.filepath=str(WORK/(name+'.png'))
    bpy.ops.render.render(write_still=True)
s.render.engine='CYCLES';s.cycles.samples=24
prefs=bpy.context.preferences.addons['cycles'].preferences
prefs.compute_device_type='ONEAPI';prefs.get_devices()
for d in prefs.devices:d.use=d.type=='ONEAPI'
s.cycles.device='GPU'
s.render.resolution_x=2000;s.render.resolution_y=650;camera.data.ortho_scale=30.4
aim((0,-38,12))
for name,angle in [('lineup-front',0),('lineup-right',math.pi/2),('lineup-back',math.pi),('lineup-left',3*math.pi/2)]:
    for r in roots:r.rotation_euler.z=angle
    bpy.context.view_layer.update();render(name)
for r in roots:r.rotation_euler.z=0
aim((0,-.01,42),(0,0,2.2));render('lineup-top')
floor.hide_render=True
aim((0,-.01,-35),(0,0,1));camera.rotation_euler.rotate_axis('Z',math.pi);render('lineup-underside')
floor.hide_render=False
# A neutral scale proxy, deliberately confined to the presentation collection.
stage=bpy.data.collections['Presentation_NotExported']
proxy_col=bpy.data.collections.new('ScaleProxy_NotExported');s.collection.children.link(proxy_col)
grey=bpy.data.materials.new('Preview_CharacterGrey');grey.diffuse_color=(.18,.22,.28,1)
pieces=[('Torso',(0,0,1.50),(.94,.48,1.02)),('Head',(0,0,2.27),(.57,.57,.57)),('LegL',(-.25,0,.53),(.43,.46,.99)),('LegR',(.25,0,.53),(.43,.46,.99)),('ArmL',(-.72,0,1.52),(.38,.45,.94)),('ArmR',(.72,0,1.52),(.38,.45,.94))]
for name,xyz,dim in pieces:
    bpy.ops.mesh.primitive_cube_add(size=1,location=(xyz[0]-15.5,xyz[1],xyz[2]))
    ob=bpy.context.object;ob.name='ScaleProxy_'+name;ob.dimensions=dim
    for col in list(ob.users_collection):col.objects.unlink(ob)
    proxy_col.objects.link(ob);ob.data.materials.append(grey)
camera.data.ortho_scale=34.5;aim((-1.1,-38,12),(-1.1,0,2.3));render('lineup-character-scale')
for ob in list(proxy_col.objects):bpy.data.objects.remove(ob,do_unlink=True)
bpy.data.collections.remove(proxy_col)
camera.data.ortho_scale=30.4;aim((0,-38,12))
s.render.filepath=str(WORK/'lineup-front.png')
for a in bpy.context.screen.areas if bpy.context.screen else []:
    if a.type=='VIEW_3D':
        a.spaces.active.region_3d.view_perspective='CAMERA'
        a.spaces.active.region_3d.view_camera_zoom=23
        a.spaces.active.overlay.show_overlays=False
bpy.ops.wm.save_as_mainfile(filepath=str(WORK/'ocean-eggs-presentation.blend'))
result={'renders':7,'scene':s.name}
