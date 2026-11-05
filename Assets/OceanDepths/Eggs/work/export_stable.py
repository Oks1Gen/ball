"""Clean asset export using normal .blend saves; avoids scene library-write crash."""
import bpy, json, math, struct
from pathlib import Path
from mathutils import Vector
from mathutils.kdtree import KDTree
BASE=Path(__file__).resolve().parent.parent
OUT=BASE/'model';WORK=BASE/'work'
presentation=WORK/'ocean-eggs-presentation.blend'
source=bpy.data.scenes['Ocean Eggs • Common to Legendary']
assert source.get('asset_revision')==2
names=sorted(o.name for o in source.objects if o.type=='EMPTY' and 'rarity' in o)
report={}

def stats(scene):
    pts=[];tris=0;meshes=[]
    for ob in scene.objects:
        if ob.type!='MESH':continue
        ob.data.calc_loop_triangles();tris+=len(ob.data.loop_triangles);meshes.append(ob)
        pts.extend(ob.matrix_world@v.co for v in ob.data.vertices)
    return {'mesh_count':len(meshes),'triangles':tris,'bounds_min':[min(p[k] for p in pts) for k in range(3)],'bounds_max':[max(p[k] for p in pts) for k in range(3)]},pts

clean=bpy.data.scenes.new('OceanEggs_Models_Only')
for name in names:
    root=bpy.data.objects[name]
    clean.collection.objects.link(root)
    for ob in root.children:clean.collection.objects.link(ob)
bpy.context.window.scene=clean
keep=set(clean.objects)
for ob in list(bpy.data.objects):
    if ob not in keep:bpy.data.objects.remove(ob,do_unlink=True)
for scene in list(bpy.data.scenes):
    if scene!=clean:bpy.data.scenes.remove(scene)
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'ocean-eggs-lineup.blend'))

for name in names:
    bpy.ops.wm.open_mainfile(filepath=str(OUT/'ocean-eggs-lineup.blend'))
    s=bpy.context.scene;root=bpy.data.objects[name]
    keep={root,*root.children}
    for ob in list(bpy.data.objects):
        if ob not in keep:bpy.data.objects.remove(ob,do_unlink=True)
    root.location=(0,0,0)
    s.name=name
    bpy.context.view_layer.update()
    measured,pts=stats(s)
    tree=KDTree(len(pts))
    for i,p in enumerate(pts):tree.insert(p,i)
    tree.balance();a=math.tau/root['rotational_symmetry'];ca,sa=math.cos(a),math.sin(a)
    measured['symmetry_vertex_max_error']=max(tree.find(Vector((p.x*ca-p.y*sa,p.x*sa+p.y*ca,p.z)))[2] for p in pts)
    bpy.ops.wm.save_as_mainfile(filepath=str(OUT/(name+'.blend')),copy=True)
    for ob in s.objects:ob.select_set(True)
    bpy.context.view_layer.objects.active=next(o for o in s.objects if o.type=='MESH')
    bpy.ops.export_scene.gltf(filepath=str(OUT/(name+'.glb')),export_format='GLB',use_selection=True,export_animations=False,export_cameras=False,export_lights=False)
    bpy.ops.export_scene.fbx(filepath=str(OUT/(name+'.fbx')),use_selection=True,object_types={'EMPTY','MESH'},use_mesh_modifiers=True,mesh_smooth_type='FACE',add_leaf_bones=False,bake_anim=False,axis_forward='Z',axis_up='Y',apply_unit_scale=True,apply_scale_options='FBX_SCALE_UNITS',path_mode='COPY',embed_textures=True)
    report[name]={'source':measured}
    for ext in ('glb','fbx'):
        check=bpy.data.scenes.new('Check_'+ext);bpy.context.window.scene=check
        if ext=='glb':bpy.ops.import_scene.gltf(filepath=str(OUT/(name+'.glb')))
        else:bpy.ops.import_scene.fbx(filepath=str(OUT/(name+'.fbx')))
        bpy.context.view_layer.update();info,_=stats(check)
        assert not any(o.type in ('CAMERA','LIGHT') for o in check.objects)
        for key in ('bounds_min','bounds_max'):
            assert max(abs(a-b) for a,b in zip(info[key],measured[key]))<.003,(name,ext,key,info[key],measured[key])
        info['material_alpha_min']=min((m.diffuse_color[3] for o in check.objects if o.type=='MESH' for m in o.data.materials if m),default=1)
        report[name][ext]=info
        bpy.context.window.scene=s
        for ob in list(check.objects):bpy.data.objects.remove(ob,do_unlink=True)
        bpy.data.scenes.remove(check)
    with open(OUT/(name+'.glb'),'rb') as f:
        header=f.read(12);size,kind=struct.unpack('<II',f.read(8));j=json.loads(f.read(size))
    assert not any('uri' in b for b in j.get('buffers',[]))
    assert not any('uri' in im for im in j.get('images',[]))
    report[name]['glb']['self_contained']=True
    report[name]['glb']['materials']=[{'name':m.get('name'),'alphaMode':m.get('alphaMode','OPAQUE'),'transmission':m.get('extensions',{}).get('KHR_materials_transmission',{}).get('transmissionFactor',0)} for m in j.get('materials',[])]
    (WORK/'export-validation.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
    (WORK/'pipeline-status.txt').write_text('Verified '+name,encoding='utf-8')

# Validate clean .blend contents by reopening the actual files.
for name in names:
    bpy.ops.wm.open_mainfile(filepath=str(OUT/(name+'.blend')))
    assert len(bpy.data.scenes)==1
    assert not any(o.type not in ('MESH','EMPTY') for o in bpy.context.scene.objects)
    actual,_=stats(bpy.context.scene)
    assert actual['mesh_count']==report[name]['source']['mesh_count']
    report[name]['blend_verified']=True
(WORK/'export-validation.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
(WORK/'pipeline-status.txt').write_text('COMPLETE',encoding='utf-8')
print('ALL FIVE EGG PACKAGES VERIFIED')
