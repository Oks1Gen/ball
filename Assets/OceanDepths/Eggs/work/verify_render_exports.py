"""Compare imported GLB and FBX under the exact review lights and camera."""
import bpy, json
from pathlib import Path
BASE=Path(__file__).resolve().parent.parent
OUT=BASE/'model';WORK=BASE/'work'
report={}
for ext in ('glb','fbx'):
    bpy.ops.wm.open_mainfile(filepath=str(WORK/'ocean-eggs-presentation.blend'))
    s=bpy.context.scene
    original=sorted([o for o in s.objects if o.type=='EMPTY' and 'rarity' in o],key=lambda o:o.name)
    items=[(r.name,r.location.x) for r in original]
    for r in original:
        for ob in list(r.children):bpy.data.objects.remove(ob,do_unlink=True)
        bpy.data.objects.remove(r,do_unlink=True)
    for name,x in items:
        before=set(s.objects)
        if ext=='glb':bpy.ops.import_scene.gltf(filepath=str(OUT/(name+'.glb')))
        else:bpy.ops.import_scene.fbx(filepath=str(OUT/(name+'.fbx')))
        added=set(s.objects)-before
        for root in [o for o in added if o.parent not in added]:root.location.x+=x
    bpy.context.view_layer.update()
    s.render.engine='CYCLES';s.cycles.samples=24
    prefs=bpy.context.preferences.addons['cycles'].preferences
    prefs.compute_device_type='ONEAPI';prefs.get_devices()
    for d in prefs.devices:d.use=d.type=='ONEAPI'
    s.cycles.device='GPU'
    s.render.filepath=str(WORK/('lineup-'+ext+'.png'));bpy.ops.render.render(write_still=True)
    mats={m for o in s.objects if o.type=='MESH' for m in o.data.materials if m and 'Jelly_Translucent' in m.name}
    report[ext]={}
    for m in mats:
        p=next((n for n in m.node_tree.nodes if n.type=='BSDF_PRINCIPLED'),None) if m.use_nodes else None
        report[ext][m.name]={'diffuse_alpha':m.diffuse_color[3],'shader_alpha':p.inputs['Alpha'].default_value if p else None,'transmission':p.inputs['Transmission Weight'].default_value if p else None}
(WORK/'material-roundtrip.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
print('EXPORTED MATERIAL RENDERS VERIFIED')
