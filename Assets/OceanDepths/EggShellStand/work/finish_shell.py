"""Headless render, clean ordinary-save export and independent round-trip checks."""
import bpy, bmesh, json, math, struct
from pathlib import Path
from mathutils import Vector
BASE=Path(__file__).resolve().parent.parent
WORK=BASE/'work'; OUT=BASE/'model'
s=bpy.data.scenes['Nautilus Shell • Option 5'];bpy.context.window.scene=s
asset=bpy.data.collections['NautilusShell_Asset']
stage=bpy.data.collections['Presentation_NotExported.001'] if 'Presentation_NotExported.001' in bpy.data.collections else bpy.data.collections['Presentation_NotExported']
# Collection identity is resolved from the selected scene, not a suffixed global name.
stage=next(c for c in s.collection.children if c!=asset)
camera=s.camera
floor=next(o for o in stage.objects if o.name.startswith('Preview_Ground'))
prefs=bpy.context.preferences.addons['cycles'].preferences
prefs.compute_device_type='ONEAPI';prefs.get_devices()
for d in prefs.devices:d.use=d.type=='ONEAPI'
s.cycles.device='GPU'; s.cycles.samples=32
s.render.resolution_x=1400;s.render.resolution_y=1100

def aim(pos,target=(0,0,.95),scale=8.7):
    camera.location=pos
    camera.rotation_euler=(Vector(target)-camera.location).to_track_quat('-Z','Y').to_euler()
    camera.data.ortho_scale=scale
def render(name):
    s.render.filepath=str(WORK/(name+'.png'));bpy.ops.render.render(write_still=True)

for name,pos in [('shell-front',(7,-11,8)),('shell-right',(12,0,6)),('shell-back',(-7,11,7)),('shell-left',(-12,0,6)),('shell-top',(0,-.01,15))]:
    aim(pos);render(name)
floor.hide_render=True
under_data=bpy.data.lights.new('Underside_CheckFill','AREA');under_data.energy=380;under_data.size=6
under=bpy.data.objects.new('Underside_CheckFill',under_data);stage.objects.link(under);under.location=(0,-2,-7)
under.rotation_euler=(Vector((0,0,.5))-under.location).to_track_quat('-Z','Y').to_euler()
aim((0,-.01,-12),(0,0,.65));camera.rotation_euler.rotate_axis('Z',math.pi)
render('shell-underside');floor.hide_render=False
bpy.data.objects.remove(under,do_unlink=True)

# Actual source egg, cloned only into the non-exported presentation collection.
egg_source=bpy.data.objects['01_Common_Kelp']
egg_objects=[]
eggroot=egg_source.copy();eggroot.name='ScalePreview_KelpEgg';stage.objects.link(eggroot)
eggroot.location=(0,0,1.92);eggroot.rotation_euler=(0,0,0)
for ob in egg_source.children:
    copy=ob.copy();copy.name='ScalePreview_'+ob.name;stage.objects.link(copy);copy.parent=eggroot;egg_objects.append(copy)
egg_objects.append(eggroot)
aim((8,-12,9),(0,0,2.7),9.7)
render('shell-with-egg')
for ob in egg_objects:bpy.data.objects.remove(ob,do_unlink=True)

# Block-character at 3.4 source units, roughly 5.5 game studs at the egg display scale.
proxy=[]
parts=[('Torso',(0,0,2.01),(1.15,.56,1.34)),('Head',(0,0,3.04),(.72,.72,.72)),
       ('LegL',(-.31,0,.66),(.53,.56,1.32)),('LegR',(.31,0,.66),(.53,.56,1.32)),
       ('ArmL',(-.91,0,2.0),(.48,.55,1.25)),('ArmR',(.91,0,2.0),(.48,.55,1.25))]
grey=bpy.data.materials['Nautilus_BlueFacet']
for name,pos,dims in parts:
    bpy.ops.mesh.primitive_cube_add(size=1,location=(pos[0]+5.1,pos[1],pos[2]))
    ob=bpy.context.object;ob.name='ScaleProxy_'+name;ob.dimensions=dims
    for c in list(ob.users_collection):c.objects.unlink(ob)
    stage.objects.link(ob);ob.data.materials.append(grey);proxy.append(ob)
aim((6,-14,9),(1.5,0,1.5),11.5);render('shell-character-scale')
for ob in proxy:bpy.data.objects.remove(ob,do_unlink=True)
aim((7,-11,8));s.render.filepath=str(WORK/'shell-front.png')
bpy.ops.wm.save_as_mainfile(filepath=str(WORK/'shell-review.blend'))

def stats(scene):
    pts=[];triangles=0;meshes=0;issues=[]
    for ob in scene.objects:
        if ob.type!='MESH':continue
        meshes+=1;ob.data.calc_loop_triangles();triangles+=len(ob.data.loop_triangles)
        assert len(ob.data.loop_triangles)<10000,(ob.name,'per-mesh triangle budget')
        pts.extend(ob.matrix_world@v.co for v in ob.data.vertices)
        bm=bmesh.new();bm.from_mesh(ob.data)
        edges=sum(not e.is_manifold for e in bm.edges)
        degenerate=sum(f.calc_area()<1e-10 for f in bm.faces)
        if edges or degenerate:issues.append({'mesh':ob.name,'nonmanifold_edges':edges,'degenerate_faces':degenerate})
        bm.free()
    return {'mesh_count':meshes,'triangles':triangles,'bounds_min':[min(v[i] for v in pts) for i in range(3)],'bounds_max':[max(v[i] for v in pts) for i in range(3)],'issues':issues}

# Source is still on disk. This is a separate process, so cleanup cannot touch the UI.
clean=bpy.data.scenes.new('NautilusShell_Model')
for ob in list(asset.objects):clean.collection.objects.link(ob)
bpy.context.window.scene=clean
keep=set(clean.objects)
for ob in list(bpy.data.objects):
    if ob not in keep:bpy.data.objects.remove(ob,do_unlink=True)
for scene in list(bpy.data.scenes):
    if scene!=clean:bpy.data.scenes.remove(scene)
for col in list(bpy.data.collections):bpy.data.collections.remove(col)
bpy.data.orphans_purge(do_local_ids=True,do_linked_ids=True,do_recursive=True)
bpy.context.view_layer.update()
source=stats(clean);assert not source['issues'],source['issues']
for ob in clean.objects:ob.select_set(True)
bpy.context.view_layer.objects.active=next(o for o in clean.objects if o.type=='MESH')
for area in bpy.context.screen.areas:
    if area.type=='VIEW_3D':
        sp=area.spaces.active;sp.shading.type='MATERIAL';sp.overlay.show_overlays=False
        sp.region_3d.view_distance=9.2;sp.region_3d.view_location=(0,0,1)
        sp.region_3d.view_rotation=(Vector((0,0,1))-Vector((7,-11,8))).to_track_quat('-Z','Y')
        sp.region_3d.view_perspective='PERSP'
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'nautilus-shell.blend'))
bpy.ops.export_scene.gltf(filepath=str(OUT/'nautilus-shell.glb'),export_format='GLB',use_selection=True,export_animations=False,export_cameras=False,export_lights=False)
bpy.ops.export_scene.fbx(filepath=str(OUT/'nautilus-shell.fbx'),use_selection=True,object_types={'EMPTY','MESH'},use_mesh_modifiers=True,mesh_smooth_type='FACE',add_leaf_bones=False,bake_anim=False,axis_forward='Z',axis_up='Y',apply_unit_scale=True,apply_scale_options='FBX_SCALE_UNITS',path_mode='COPY',embed_textures=True)
report={'source':source}
for ext in ('glb','fbx'):
    check=bpy.data.scenes.new('RoundTrip_'+ext);bpy.context.window.scene=check
    if ext=='glb':bpy.ops.import_scene.gltf(filepath=str(OUT/'nautilus-shell.glb'))
    else:bpy.ops.import_scene.fbx(filepath=str(OUT/'nautilus-shell.fbx'))
    bpy.context.view_layer.update();info=stats(check)
    assert all(o.type in ('EMPTY','MESH') for o in check.objects)
    for key in ('bounds_min','bounds_max'):
        assert max(abs(a-b) for a,b in zip(info[key],source[key]))<.003,(ext,key,info[key],source[key])
    info['materials']=sorted(set(m.name for o in check.objects if o.type=='MESH' for m in o.data.materials if m))
    report[ext]=info
    # Same studio illumination for the actual imported geometry.
    bpy.ops.wm.open_mainfile(filepath=str(WORK/'shell-review.blend'))
    review=bpy.data.scenes['Nautilus Shell • Option 5'];bpy.context.window.scene=review
    for ob in list(bpy.data.collections['NautilusShell_Asset'].objects):ob.hide_render=True
    before=set(review.objects)
    if ext=='glb':bpy.ops.import_scene.gltf(filepath=str(OUT/'nautilus-shell.glb'))
    else:bpy.ops.import_scene.fbx(filepath=str(OUT/'nautilus-shell.fbx'))
    bpy.context.view_layer.update()
    review.render.filepath=str(WORK/('shell-'+ext+'.png'));bpy.ops.render.render(write_still=True)
    report[ext]['same_light_render']=str(WORK/('shell-'+ext+'.png'))

with open(OUT/'nautilus-shell.glb','rb') as f:
    f.read(12);size,kind=struct.unpack('<II',f.read(8));doc=json.loads(f.read(size))
assert not any('uri' in b for b in doc.get('buffers',[]))
assert not any('uri' in im for im in doc.get('images',[]))
report['glb']['self_contained']=True
bpy.ops.wm.open_mainfile(filepath=str(OUT/'nautilus-shell.blend'))
assert len(bpy.data.scenes)==1
assert all(o.type in ('EMPTY','MESH') for o in bpy.context.scene.objects)
report['blend_reopened']=True
report['final']=stats(bpy.context.scene)
(WORK/'validation.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
(WORK/'pipeline-status.txt').write_text('COMPLETE',encoding='utf-8')
print('NAUTILUS SHELL COMPLETE',json.dumps(source))
