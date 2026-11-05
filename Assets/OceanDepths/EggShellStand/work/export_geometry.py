import bpy,json
from pathlib import Path
def srgb(v):return 12.92*v if v<=.0031308 else 1.055*v**(1/2.4)-.055
meshes=[]
for ob in bpy.context.scene.objects:
    if ob.type!='MESH':continue
    ob.data.calc_loop_triangles()
    colors=[]
    for m in ob.data.materials:
        p=next(n for n in m.node_tree.nodes if n.type=='BSDF_PRINCIPLED')
        colors.append([round(srgb(v),6) for v in p.inputs['Base Color'].default_value[:3]])
    vertices=[]
    for v in ob.data.vertices:
        p=ob.matrix_world@v.co;vertices.append([round(p.x,6),round(p.z,6),round(-p.y,6)])
    meshes.append({'name':ob.name,'vertices':vertices,'colors':colors,'triangles':[[*t.vertices,t.material_index] for t in ob.data.loop_triangles]})
out=Path(__file__).parent/'geometry.json'
out.write_text(json.dumps({'schema':1,'revision':3,'meshes':meshes},separators=(',',':')),encoding='utf-8')
print('EXACT SHELL GEOMETRY',len(meshes),out.stat().st_size)
