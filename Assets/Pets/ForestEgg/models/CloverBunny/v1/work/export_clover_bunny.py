"""Save a clean editable asset and portable, evaluated GLB/FBX copies."""
import bpy, json, bmesh, math, shutil, struct
from pathlib import Path
from mathutils import Vector

BASE=Path('C:/Users/dakem/Documents/RobloxGames/ball/Assets/Pets/ForestEgg/models/CloverBunny/v1')
MODEL=BASE/'model';WORK=BASE/'work'
scene=bpy.data.scenes['CloverBunny'];asset=bpy.data.collections['CloverBunny_Asset']
bpy.context.window.scene=scene;bpy.context.view_layer.update()
root=bpy.data.objects['CloverBunny']
images={n.image for o in asset.objects if o.type in {'MESH','CURVE'} for m in o.data.materials if m and m.use_nodes for n in m.node_tree.nodes if n.type=='TEX_IMAGE' and n.image}
for im in images:
    if not im.packed_file:im.pack()
blend=MODEL/'CloverBunny.blend'
bpy.data.libraries.write(str(blend),{scene},compress=True)
with bpy.data.libraries.load(str(blend)) as (source,target):
    saved_inventory={'scenes':list(source.scenes),'objects':list(source.objects),'images':list(source.images)}
assert saved_inventory['scenes']==['CloverBunny'], saved_inventory
assert not any(n.startswith('CB_Preview') or n in {'Cube','Camera','Light'} for n in saved_inventory['objects'])

export_scene=bpy.data.scenes.new('CB_Export_Check')
col=bpy.data.collections.new('CB_Export_Geometry');export_scene.collection.children.link(col)
bpy.context.window.scene=scene;bpy.context.view_layer.update();dg=bpy.context.evaluated_depsgraph_get()
er=bpy.data.objects.new('CloverBunny_ExportRoot',None);col.objects.link(er)
stats=[]
for obj in asset.objects:
    if obj.type not in {'MESH','CURVE'}:continue
    ev=obj.evaluated_get(dg)
    mesh=bpy.data.meshes.new_from_object(ev,preserve_all_data_layers=True,depsgraph=dg)
    # Curve end-caps have coincident end vertices: weld in the export copy.
    if obj.type=='CURVE':
        bm=bmesh.new();bm.from_mesh(mesh)
        bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=1e-6)
        bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces))
        bm.to_mesh(mesh);bm.free();mesh.update()
    ex=bpy.data.objects.new(obj.name+'_Export',mesh);col.objects.link(ex)
    ex.matrix_world=obj.matrix_world.copy();ex.parent=er
    mesh.calc_loop_triangles()
    stats.append({'name':obj.name,'triangles':len(mesh.loop_triangles),'degenerate':sum(t.area<1e-12 for t in mesh.loop_triangles),'materials':[m.name for m in mesh.materials if m]})

def bounds(sc):
    bpy.context.window.scene=sc;bpy.context.view_layer.update()
    pts=[o.matrix_world@Vector(corner) for o in sc.objects if o.type=='MESH' for corner in o.bound_box]
    return {'min':[min(p[i] for p in pts) for i in range(3)],'max':[max(p[i] for p in pts) for i in range(3)],'size':[max(p[i] for p in pts)-min(p[i] for p in pts) for i in range(3)]}

bpy.context.window.scene=export_scene
for ob in export_scene.objects:ob.select_set(True)
bpy.context.view_layer.objects.active=er
expected=bounds(export_scene)
glb=MODEL/'CloverBunny.glb';fbx=MODEL/'CloverBunny.fbx'
bpy.ops.export_scene.gltf(filepath=str(glb),export_format='GLB',use_selection=True,use_active_scene=True,export_animations=False,export_cameras=False,export_lights=False,export_apply=True,export_yup=True,export_materials='EXPORT',export_texcoords=True,export_normals=True)
bpy.ops.export_scene.fbx(filepath=str(fbx),use_selection=True,global_scale=1.0,apply_unit_scale=True,apply_scale_options='FBX_SCALE_UNITS',axis_forward='Z',axis_up='Y',object_types={'MESH','EMPTY'},use_mesh_modifiers=True,mesh_smooth_type='OFF',use_triangles=True,bake_anim=False,path_mode='COPY',embed_textures=True)

raw=glb.read_bytes();assert raw[:4]==b'glTF'
n,kind=struct.unpack_from('<II',raw,12);doc=json.loads(raw[20:20+n])
external=[r.get('uri') for key in ('buffers','images') for r in doc.get(key,[]) if r.get('uri')]
assert not external,external

# Separate validation copies do not carry working PNG files beside them.
roundtrip=WORK/'roundtrip';roundtrip.mkdir(exist_ok=True)
for p in (blend,glb,fbx):shutil.copy2(p,roundtrip/p.name)
report={'source_parts':len(stats),'triangles':sum(r['triangles'] for r in stats),'max_part_triangles':max(r['triangles'] for r in stats),'degenerate':sum(r['degenerate'] for r in stats),'bounds':expected,'source_front':'-Y','saved_blend_inventory':saved_inventory,'packed_source_images':[im.name for im in images],'glb_external_uris':external,'parts':stats,'roundtrip':{}}
assert report['degenerate']==0
assert report['triangles']<10000,report['triangles']

def inspect(sc,label):
    b=bounds(sc)
    delta=max(abs(b['min'][i]-expected['min'][i]) for i in range(3))
    delta=max(delta,max(abs(b['max'][i]-expected['max'][i]) for i in range(3)))
    mats={m for o in sc.objects if o.type=='MESH' for m in o.data.materials if m}
    imgs={n.image for m in mats if m.use_nodes for n in m.node_tree.nodes if n.type=='TEX_IMAGE' and n.image}
    eye=[o for o in sc.objects if o.type=='MESH' and 'EyeWhite' in o.name]
    body=[o for o in sc.objects if o.type=='MESH' and 'CB_Body' in o.name]
    assert len(eye)==2 and len(body)==1,(label,[o.name for o in sc.objects])
    ey=(sum((o.matrix_world@Vector(c)).y for o in eye for c in o.bound_box)/16)
    assert ey<-.95,(label,ey)
    assert delta<.002,(label,b,expected)
    assert not any(o.type in {'LIGHT','CAMERA'} for o in sc.objects)
    assert len(imgs)>=2,(label,[m.name for m in mats])
    return {'bounds':b,'max_bounds_error':delta,'mesh_count':sum(o.type=='MESH' for o in sc.objects),'material_count':len(mats),'images':[{'name':im.name,'size':list(im.size),'packed':bool(im.packed_file),'filepath':im.filepath} for im in imgs],'face_front_y':ey,'objects':[o.name for o in sc.objects]}

# Append saved BLEND into a new scene in this same live Blender session.
before=set(bpy.data.scenes)
with bpy.data.libraries.load(str(roundtrip/'CloverBunny.blend'),link=False) as (src,dst):dst.scenes=list(src.scenes)
saved=next(sc for sc in bpy.data.scenes if sc not in before)
saved.name='CB_Roundtrip_BLEND'
report['roundtrip']['blend']=inspect(saved,'blend')

for label,filename in [('glb','CloverBunny.glb'),('fbx','CloverBunny.fbx')]:
    sc=bpy.data.scenes.new('CB_Roundtrip_'+label.upper())
    bpy.context.window.scene=sc
    if label=='glb':
        bpy.ops.import_scene.gltf(filepath=str(roundtrip/filename),import_pack_images=True)
    else:
        bpy.ops.import_scene.fbx(filepath=str(roundtrip/filename),use_custom_normals=True)
    report['roundtrip'][label]=inspect(sc,label)

original=bpy.data.scenes['Scene']
original_state=json.loads((WORK/'original-scene.json').read_text(encoding='utf-8'))
report['original_scene_preserved']=all(name in original.objects and max(abs(original.objects[name].matrix_world[i][j]-st['matrix'][i][j]) for i in range(4) for j in range(4))<1e-7 for name,st in original_state.items())
assert report['original_scene_preserved']
(WORK/'export-validation.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
bpy.context.window.scene=scene
bpy.context.view_layer.update()
for ob in bpy.context.selected_objects:ob.select_set(False)
bpy.context.view_layer.objects.active=bpy.data.objects['CB_Body']
result={'files':[str(p) for p in (blend,glb,fbx)],'triangles':report['triangles'],'max_part_triangles':report['max_part_triangles'],'roundtrip':{k:{'bounds_error':v['max_bounds_error'],'mesh_count':v['mesh_count'],'images':len(v['images'])} for k,v in report['roundtrip'].items()},'original_scene_preserved':report['original_scene_preserved']}
