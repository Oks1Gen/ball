"""glTF splits vertices at material/normal boundaries; verify welded topology."""
import bpy,bmesh,json
from pathlib import Path
BASE=Path(__file__).resolve().parent.parent
s=bpy.data.scenes.new('GLB_WeldVerification');bpy.context.window.scene=s
bpy.ops.import_scene.gltf(filepath=str(BASE/'model/nautilus-shell.glb'))
issues=[];removed=0
for ob in s.objects:
    if ob.type!='MESH':continue
    bm=bmesh.new();bm.from_mesh(ob.data);before=len(bm.verts)
    bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=.00001)
    removed+=before-len(bm.verts)
    edges=sum(not e.is_manifold for e in bm.edges)
    degenerate=sum(f.calc_area()<1e-10 for f in bm.faces)
    if edges or degenerate:issues.append({'mesh':ob.name,'nonmanifold_edges':edges,'degenerate_faces':degenerate})
    bm.free()
assert not issues,issues
p=BASE/'work/validation.json';report=json.loads(p.read_text(encoding='utf-8'))
report['glb']['welded_topology']={'issues':issues,'split_boundary_vertices':removed,'tolerance':.00001}
report['glb']['split_topology_note']='Raw glTF vertices are split at material/normal boundaries. Welding confirms a closed surface.'
p.write_text(json.dumps(report,indent=2),encoding='utf-8')
print('GLB WELDED TOPOLOGY PASS',removed)
