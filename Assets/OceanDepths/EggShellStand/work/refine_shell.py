"""Refine handle attachment: hide the roots inside the wall rather than above it."""
import bpy, math
from pathlib import Path
from mathutils import Vector
for sign,label in [(-1,'Left'),(1,'Right')]:
    points=[];radii=[]
    for j in range(57):
        t=j/56;a=math.pi+math.tau*t;r=.85*(1-t)+.15*t
        points.append(Vector((sign*(2.75+r*math.cos(a)),-1.30-.025*math.sin(a),1.15+r*math.sin(a))))
        radii.append(.205-.085*t)
    inset=[Vector((p.x,p.y-r*1.10,p.z)) for p,r in zip(points,radii)]
    for suffix,path,rs,sides,depth in [('_IvoryScroll',points,radii,10,1.16),('_AquaInlay',inset,[r*.32 for r in radii],6,.4)]:
        ob=bpy.data.objects['Volute_'+label+suffix]
        for i,p in enumerate(path):
            tangent=(path[min(i+1,len(path)-1)]-path[max(i-1,0)]).normalized()
            side=tangent.cross(Vector((0,1,0))).normalized();normal=side.cross(tangent).normalized()
            for k in range(sides):
                a=math.tau*k/sides
                ob.data.vertices[i*sides+k].co=p+rs[i]*(side*math.cos(a)+normal*math.sin(a)*depth)
        ob.data.update()
bpy.data.objects['NautilusShell']['asset_revision']=2
bpy.ops.wm.save_as_mainfile(filepath=str(Path(__file__).parent/'shell-authoring.blend'))
result={'revision':2,'refined':'Scroll roots join the lower shell wall'}
