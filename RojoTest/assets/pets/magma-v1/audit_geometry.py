"""Read-only topology check of the five saved authoring assets."""
import json
from pathlib import Path
import bpy
import bmesh

here=Path(__file__).resolve().parent
root=here.parents[3]
rows=[]
for name in ['CoalMole','CinderGecko','EmberRam','BlazeBat','InfernoPhoenix']:
    path=root/'Assets/Pets/MagmaEgg/models'/name/'v1/model'/f'{name}.blend'
    bpy.ops.wm.open_mainfile(filepath=str(path))
    graph=bpy.context.evaluated_depsgraph_get()
    assert len(bpy.data.scenes)==1
    assert not any(o.type in {'CAMERA','LIGHT'} for o in bpy.context.scene.objects)
    for obj in bpy.context.scene.objects:
        if obj.type!='MESH': continue
        evaluated=obj.evaluated_get(graph)
        mesh=evaluated.to_mesh()
        bm=bmesh.new();bm.from_mesh(mesh)
        bad=sum(1 for edge in bm.edges if not edge.is_manifold)
        volume=bm.calc_volume(signed=True)
        assert bad==0 and volume>0,(name,obj.name,bad,volume)
        rows.append(dict(pet=name,part=obj.name,nonManifoldEdges=bad,signedVolume=volume))
        bm.free();evaluated.to_mesh_clear()
(here/'verify-topology.json').write_text(json.dumps(rows,indent=2)+'\n',encoding='utf-8',newline='')
print('Closed, outward-facing solid parts:',len(rows))
