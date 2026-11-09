import bpy, json
from pathlib import Path
root=Path(__file__).resolve().parents[1]
report={}
for suffix in ['blend','glb','fbx']:
 bpy.ops.wm.read_factory_settings(use_empty=True)
 path=root/'model'/('pet-workshop.'+suffix)
 if suffix=='blend': bpy.ops.wm.open_mainfile(filepath=str(path))
 elif suffix=='glb': bpy.ops.import_scene.gltf(filepath=str(path))
 else: bpy.ops.import_scene.fbx(filepath=str(path))
 meshes=[o for o in bpy.context.scene.objects if o.type=='MESH']
 assert len(meshes)==39,(suffix,len(meshes))
 tris=sum(len(p.vertices)-2 for o in meshes for p in o.data.polygons)
 assert tris<10000 and all(o.data.materials for o in meshes)
 report[suffix]={'meshes':len(meshes),'triangles':tris,'materials':len(bpy.data.materials)}
(root/'work'/'verification.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
print(json.dumps(report))
