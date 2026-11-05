import bpy,bmesh,math
from mathutils import Vector
from pathlib import Path
for name,sides,radius,zoff,xy in [('Shell_RolledIvoryLip',6,.092,.015,1),('Shell_ContinuousAquaLipSeam',4,.034,-.067,.999)]:
    points=[]
    for j in range(96):
        a=math.tau*j/96;scallop=1+.035*math.cos(12*a)
        points.append(Vector((2.92*math.cos(a)*scallop*xy,2.20*math.sin(a)*scallop*xy,.64+1.03+.19*math.sin(a)+.038*math.cos(12*a)+zoff)))
    vertices=[];faces=[]
    for i,p in enumerate(points):
        tangent=(points[(i+1)%96]-points[(i-1)%96]).normalized()
        side=tangent.cross(Vector((0,0,1))).normalized();normal=side.cross(tangent).normalized()
        for k in range(sides):
            a=math.tau*k/sides;vertices.append(tuple(p+radius*(side*math.cos(a)+normal*math.sin(a))))
    for i in range(96):
        for k in range(sides):faces.append((i*sides+k,i*sides+(k+1)%sides,((i+1)%96)*sides+(k+1)%sides,((i+1)%96)*sides+k))
    ob=bpy.data.objects[name];materials=list(ob.data.materials)
    me=bpy.data.meshes.new(name+'_PeriodicMesh');me.from_pydata(vertices,[],faces);me.update()
    bm=bmesh.new();bm.from_mesh(me);bmesh.ops.recalc_face_normals(bm,faces=bm.faces);bm.to_mesh(me);bm.free()
    for m in materials:me.materials.append(m)
    for p in me.polygons:p.use_smooth=True
    ob.data=me
for ob in list(bpy.data.collections['NautilusShell_Asset'].objects):
    if ob.name.startswith('Underside_StructuralFlute_'):bpy.data.objects.remove(ob,do_unlink=True)
root=bpy.data.objects['NautilusShell'];root['asset_revision']=3
root['triangles']=sum(sum(len(p.vertices)-2 for p in ob.data.polygons) for ob in bpy.data.collections['NautilusShell_Asset'].objects if ob.type=='MESH')
bpy.ops.wm.save_as_mainfile(filepath=str(Path(__file__).parent/'shell-authoring.blend'))
result={'revision':3,'triangles':root['triangles'],'rim':'continuous periodic geometry'}
