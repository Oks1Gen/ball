"""Prove animated vertices stay inside exported navigation bounds and cycles close."""
import bpy,json
from pathlib import Path
OUT=Path(__file__).resolve().parent
bpy.ops.wm.open_mainfile(filepath=str(OUT/'animated-wildlife.blend'))
meta=json.loads((OUT/'rig-manifest.json').read_text());scene=bpy.context.scene
assert len([o for o in scene.objects if o.type=='MESH'])==len(meta)
assert not [o for o in scene.objects if o.type not in ('MESH','ARMATURE')]
report=[]
for entry in meta:
    obj=bpy.data.objects[entry['name']];first=None;maximum=0;seam=0
    for frame in range(1,122,4):
        scene.frame_set(frame);dg=bpy.context.evaluated_depsgraph_get();evaluated=obj.evaluated_get(dg);mesh=evaluated.to_mesh()
        points=[v.co.copy() for v in mesh.vertices]
        maximum=max(maximum,max(p.length for p in points))
        if first is None:first=points
        if frame==121:seam=max((a-b).length for a,b in zip(first,points))
        evaluated.to_mesh_clear()
    assert maximum<=entry['radius'],(entry['name'],'envelope',maximum,entry['radius'])
    assert seam<.0001,(entry['name'],'cycle seam',seam)
    report.append({'name':entry['name'],'sampledMaximumRadius':maximum,'conservativeRadius':entry['radius'],'cycleSeam':seam,'frames':31})
(OUT/'deformation-validation.json').write_text(json.dumps(report,indent=2),encoding='utf-8',newline='')
print('DEFORMATION_ENVELOPE_AND_CYCLE_PASS',len(report))
