import bpy,json
from pathlib import Path
BASE=Path(__file__).resolve().parent.parent
s=bpy.context.scene
def srgb(v):return v*12.92 if v<=.0031308 else 1.055*v**(1/2.4)-.055
eggs=[]
for root in sorted([o for o in s.objects if o.type=='EMPTY' and 'rarity' in o],key=lambda o:o.name):
    name=root.name.split('_',2)[2];meshes=[]
    for ob in root.children:
        if ob.type!='MESH':continue
        ob.data.calc_loop_triangles();groups={}
        for t in ob.data.loop_triangles:
            m=ob.data.materials[t.material_index]
            p=next(n for n in m.node_tree.nodes if n.type=='BSDF_PRINCIPLED')
            alpha=round(p.inputs['Alpha'].default_value,3);glow=p.inputs['Emission Strength'].default_value>.2
            key=(alpha,glow)
            groups.setdefault(key,[]).append({'v':list(t.vertices),'c':[srgb(c) for c in p.inputs['Base Color'].default_value[:3]],'glow':glow})
        for i,((alpha,glow),tris) in enumerate(groups.items()):
            meshes.append({'name':ob.name+'_'+str(i),'alpha':alpha,'vertices':[[v.co.x,v.co.z,-v.co.y] for v in ob.data.vertices],'triangles':tris})
    eggs.append({'name':name,'meshes':meshes})
(BASE/'work/geometry.json').write_text(json.dumps({'schema':1,'eggs':eggs},separators=(',',':')),encoding='utf-8')
print('Exported',sum(len(e['meshes']) for e in eggs),'components')
