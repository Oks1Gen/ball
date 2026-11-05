"""Durable Roblox faceted surface fallback from exact Blender triangles.
Does not require mesh uploads or session-only EditableMesh. Run in Blender.
Each surface triangle is covered by two thin noncolliding WedgeParts.
The source FBX remains the lower-instance-count mesh asset for the 3D Importer.
"""
import json, math, xml.etree.ElementTree as ET
from pathlib import Path
from mathutils import Vector, Matrix

HERE=Path(__file__).resolve().parent
ALPHA=1
data=json.loads((HERE/'geometry.json').read_text(encoding='utf8'))
root=ET.Element('roblox',version='4')
ET.SubElement(root,'External').text='null';ET.SubElement(root,'External').text='nil'
ref=0
def item(parent,cls,name):
    global ref
    ref+=1
    el=ET.SubElement(parent,'Item',{'class':cls,'referent':'E'+str(ref)})
    p=ET.SubElement(el,'Properties');ET.SubElement(p,'string',name='Name').text=name
    return el,p

def vector(p,name,vs):
    el=ET.SubElement(p,'Vector3',name=name)
    for k,v in zip('XYZ',vs):ET.SubElement(el,k).text=f'{v:.8f}'

def cfxml(p,name,center,rot):
    el=ET.SubElement(p,'CoordinateFrame',name=name)
    for k,v in zip(['X','Y','Z']+[f'R{r}{c}'for r in range(3)for c in range(3)],list(center)+[rot[r][c]for r in range(3)for c in range(3)]):
        ET.SubElement(el,k).text=f'{v:.9f}'

def part(parent,name,center,size,rot,color,glow=False,cls='WedgePart',transparent=False):
    _,p=item(parent,cls,name)
    vector(p,'Size',size);cfxml(p,'CFrame',center,rot)
    col=ET.SubElement(p,'Color3',name='Color')
    for k,v in zip('RGB',color):ET.SubElement(col,k).text=str(v)
    ET.SubElement(p,'token',name='Material').text='288'if glow else'272'
    for name,val in (('Anchored',True),('CanCollide',False),('CanTouch',False),('CanQuery',False),('CastShadow',not glow and not transparent)):
        ET.SubElement(p,'bool',name=name).text=str(val).lower()
    for face in ('Top','Bottom','Left','Right','Front','Back'):ET.SubElement(p,'token',name=face+'Surface').text='0'
    ET.SubElement(p,'float',name='Transparency').text=str(1-ALPHA)

THICKNESS=.008
stats=[]
templates,_=item(root,'Folder','OceanEggTemplates')
for egg in data['eggs']:
    model,mp=item(templates,'Model',egg['name'])
    total=0
    for source in egg['meshes']:
        group,_=item(model,'Model',source['name'])
        ALPHA=source.get('alpha',1)
        vs=[Vector(v)for v in source['vertices']]
        for i,t in enumerate(source['triangles']):
            a,b,c=[vs[j]for j in t['v']]
            ab,ac,bc=b-a,c-a,c-b
            if ab.length_squared>max(ac.length_squared,bc.length_squared):a,c=c,a
            elif ac.length_squared>max(ab.length_squared,bc.length_squared):a,b=b,a
            ab,ac,bc=b-a,c-a,c-b
            normal=ac.cross(ab)
            if normal.length<1e-8:continue
            right=normal.normalized();up=bc.cross(right).normalized();back=bc.normalized()
            height=abs(ab.dot(up))
            for suffix,mid,r,z,length in (('A',(a+b)/2,right,back,abs(ab.dot(back))),('B',(a+c)/2,-right,-back,abs(ac.dot(back)))):
                if min(height,length)<.0005:continue
                rot=Matrix((r,up,z)).transposed()
                part(group,f'Facet_{i+1:03}{suffix}',mid,(THICKNESS,height,length),rot,t['c'],t['glow'])
                total+=1
    stats.append({'name':egg['name'],'parts':total,'heightStuds':10})
ET.ElementTree(root).write(HERE/'ocean-eggs.rbxmx',encoding='utf-8',xml_declaration=True)
(HERE/'native-validation.json').write_text(json.dumps({'thicknessStuds':THICKNESS,'eggs':stats},indent=2),encoding='utf8')
result={'nativeFile':str(HERE/'ocean-eggs.rbxmx'),'eggs':stats}
