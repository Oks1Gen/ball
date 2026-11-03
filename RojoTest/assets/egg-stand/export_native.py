"""Export Blender's stand primitives as durable native Roblox Parts/WedgeParts.
Run in the connected Blender with __file__ set. Omits only tiny bevel modifiers.
No EditableMesh, uploaded mesh, texture, or runtime tessellation is required.
"""
import bpy
import json
import math
import xml.etree.ElementTree as ET
from pathlib import Path
from mathutils import Vector, Matrix

HERE=Path(__file__).resolve().parent
scene=bpy.context.scene
collection=next(c for c in scene.collection.children if c.name.startswith('EggStand_Asset'))
parts=[]
def rgb(v):return 12.92*v if v<=.0031308 else 1.055*v**(1/2.4)-.055
def remap(v):return Vector((-v.x*5,v.z*5,v.y*5))
def add(name,group,kind,center,size,color,rotation=None,collision=True):
    if min(size)<.001:return
    rot=rotation or Matrix.Identity(3)
    parts.append({'name':name,'group':group,'class':kind,'size':list(size),'cf':list(center)+[rot[r][c]for r in range(3)for c in range(3)],'color':color,'collide':collision})

def triangle(name,group,a,b,c,thickness,color,collision):
    ab,ac,bc=b-a,c-a,c-b
    if ab.length_squared>max(ac.length_squared,bc.length_squared):a,c=c,a
    elif ac.length_squared>max(ab.length_squared,bc.length_squared):a,b=b,a
    ab,ac,bc=b-a,c-a,c-b
    right=ac.cross(ab).normalized();up=bc.cross(right).normalized();back=bc.normalized()
    height=abs(ab.dot(up))
    for suffix,mid,r,z,length in [('A',(a+b)/2,right,back,abs(ab.dot(back))),('B',(a+c)/2,-right,-back,abs(ac.dot(back)))]:
        rotation=Matrix((r,up,z)).transposed()
        add(name+suffix,group,'WedgePart',mid,Vector((thickness,height,length)),color,rotation,collision)

for ob in collection.objects:
    if ob.type!='MESH':continue
    name=ob.name.split('.')[0]
    group=name.split('_')[0] if name.split('_')[0]in ['Common','Uncommon','Volcanic','Rare','Rainbow']else 'CenterSteps'
    color=[round(rgb(v),6)for v in ob.data.materials[0].diffuse_color[:3]]
    verts=[remap(ob.matrix_world@v.co)for v in ob.data.vertices]
    if 'Studs' in name:
        assert len(verts)%8==0
        for index in range(0,len(verts),8):
            vs=verts[index:index+8]
            lo=Vector([min(v[k]for v in vs)for k in range(3)])
            hi=Vector([max(v[k]for v in vs)for k in range(3)])
            add(name+str(index//8+1),group,'Part',(lo+hi)/2,hi-lo,color,collision=False)
    else:
        n=len(verts)//2
        assert len(verts)==n*2 and len(ob.data.polygons)==n+2,name
        bottom=min(v.y for v in verts);top=max(v.y for v in verts)
        poly=[Vector((v.x,(bottom+top)/2,v.z))for v in verts[:n]]
        # Axis-aligned rectangles become a single Part, other outlines become solid wedges.
        xs=set(round(v.x,5)for v in poly);zs=set(round(v.z,5)for v in poly)
        collide=not name.endswith('RearRim')
        if n==4 and len(xs)==2 and len(zs)==2:
            lo=Vector((min(xs),bottom,min(zs)));hi=Vector((max(xs),top,max(zs)))
            add(name,group,'Part',(lo+hi)/2,hi-lo,color,collision=collide)
        else:
            for i in range(1,n-1):triangle(name+str(i),group,poly[0],poly[i],poly[i+1],top-bottom,color,collide)

root=ET.Element('roblox',version='4')
ET.SubElement(root,'External').text='null';ET.SubElement(root,'External').text='nil'
def item(parent,kind,name):
    el=ET.SubElement(parent,'Item',{'class':kind,'referent':name});p=ET.SubElement(el,'Properties')
    ET.SubElement(p,'string',name='Name').text=name
    return el,p
model,props=item(root,'Model','EggStandTemplate')
groups={}
for group in ['Common','Uncommon','Volcanic','Rare','Rainbow','CenterSteps']:
    groups[group]=item(model,'Model',group)[0]
def vector(p,name,values):
    e=ET.SubElement(p,'Vector3',name=name)
    for k,v in zip('XYZ',values):ET.SubElement(e,k).text=str(v)
def part_xml(part):
    el,p=item(groups[part['group']],part['class'],part['name'])
    vector(p,'Size',part['size'])
    cf=ET.SubElement(p,'CoordinateFrame',name='CFrame')
    for k,v in zip(['X','Y','Z']+[f'R{r}{c}'for r in range(3)for c in range(3)],part['cf']):ET.SubElement(cf,k).text=str(v)
    c=ET.SubElement(p,'Color3',name='Color')
    for k,v in zip('RGB',part['color']):ET.SubElement(c,k).text=str(v)
    ET.SubElement(p,'token',name='Material').text='1088'
    for k,v in [('Anchored',True),('CanCollide',part['collide']),('CanTouch',False),('CanQuery',part['collide']),('CastShadow','Studs'not in part['name'])]:ET.SubElement(p,'bool',name=k).text=str(v).lower()
    for face in ['Top','Bottom','Left','Right','Front','Back']:ET.SubElement(p,'token',name=face+'Surface').text='0'
for part in parts:part_xml(part)
# Seat points are semantic markers, independent of the decorative polygon decomposition.
for group,x,z,y in [('Common',48.4,-7.2,3.925),('Uncommon',24.4,-2.4,3.925),('Volcanic',0,0,4.825),('Rare',-24.4,-2.4,3.925),('Rainbow',-48.4,-7.2,3.925)]:
    p={'name':'SeatCenter','group':group,'class':'Part','size':[.1,.1,.1],'cf':[x,y,z,1,0,0,0,1,0,0,0,1],'color':[1,1,1],'collide':False}
    part_xml(p)
    xml=groups[group][-1].find('Properties');ET.SubElement(xml,'float',name='Transparency').text='1'
ET.indent(root,space='  ')
ET.ElementTree(root).write(HERE/'egg-stand.rbxmx',encoding='utf-8',xml_declaration=True)
(HERE/'native-parts.json').write_text(json.dumps(parts,separators=(',',':')),encoding='utf8')
result={'parts':len(parts),'file':str(HERE/'egg-stand.rbxmx'),'width':121,'permanent':True}
