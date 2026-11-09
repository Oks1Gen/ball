"""Reference matching: broad folded ear, softer light, economical small meshes."""
import bpy, math, ast
from pathlib import Path
from mathutils import Vector

BASE=Path('C:/Users/dakem/Documents/RobloxGames/ball/Assets/Pets/ForestEgg/models/CloverBunny/v1')
WORK=BASE/'work'
scene=bpy.data.scenes['CloverBunny'];preview=bpy.data.scenes['CB_Preview']
asset=bpy.data.collections['CloverBunny_Asset'];root=bpy.data.objects['CloverBunny']
materials={k:bpy.data.materials['CB_'+k] for k in ['Cream','Pink','Nose','Mouth','Clover','CloverStem','EyeWhite','Glint']}
tree=ast.parse((WORK/'build_clover_bunny.py').read_text(encoding='utf-8'))
helpers=[n for n in tree.body if isinstance(n,ast.FunctionDef) and n.name in {'own','ellipsoid','catmull','ear_frame','aim','png_rgba','iris_pixel'}]
exec(compile(ast.Module(body=helpers,type_ignores=[]),'clover_helpers','exec'))

bpy.data.libraries.write(str(WORK/'clover-first-pass.blend'), {scene}, compress=True)
bpy.context.window.scene=scene
bpy.context.view_layer.active_layer_collection=bpy.context.view_layer.layer_collection.children[asset.name]

def refined_ear(name, points, width, pink_end):
    old=[bpy.data.objects['CB_'+name],bpy.data.objects['CB_'+name+'_Pink']]
    steps,radial=32,16
    def shape(t):
        if t<.13:return .69+.31*math.sin(t/.13*math.pi/2)
        if t<.74:return 1.0
        return math.sqrt(max(.0004,1-((t-.74)/.26)**2))
    vv,ff=[],[]
    for i in range(steps+1):
        t=i/steps;c,s,f=ear_frame(points,t);r=shape(t)
        for j in range(radial):
            a=2*math.pi*j/radial
            vv.append(c+s*(width*r*math.cos(a))+f*(.135*r*math.sin(a)))
    for i in range(steps):
        for j in range(radial):
            a=i*radial+j;b=i*radial+(j+1)%radial
            ff.append((a,a+radial,b+radial,b))
    ff.extend([tuple(range(radial)),tuple(reversed([steps*radial+j for j in range(radial)]))])
    me=bpy.data.meshes.new('CB_'+name+'_RefinedMesh');me.from_pydata(vv,[],ff);me.update()
    old[0].data=me;me.materials.append(materials['Cream'])
    for p in me.polygons:p.use_smooth=True
    vv,ff=[],[];n,k=18,6
    for i in range(n+1):
        v=i/n;t=.10+(pink_end-.10)*v;c,s,f=ear_frame(points,t);r=shape(t)
        iw=width*r*.65*max(.025,math.sin(math.pi*v)**.35)
        for j in range(k+1):
            u=(j/k*2-1)*iw
            dep=.135*r*math.sqrt(max(.01,1-(u/(width*r))**2))+.003
            vv.append(c+s*u+f*dep)
    for i in range(n):
        for j in range(k):
            a=i*(k+1)+j;ff.append((a,a+1,a+k+2,a+k+1))
    me=bpy.data.meshes.new('CB_'+name+'_PinkRefinedMesh');me.from_pydata(vv,[],ff);me.update()
    old[1].data=me;me.materials.append(materials['Pink'])
    for p in me.polygons:p.use_smooth=True

refined_ear('Ear_Upright',[(-.53,-.43,2.13),(-.68,-.43,2.57),(-.84,-.43,3.03),(-.94,-.43,3.43),(-.90,-.43,3.58)],.265,.90)
refined_ear('Ear_Folded',[(.32,-.40,2.12),(.45,-.40,2.56),(.62,-.39,2.96),(.82,-.40,3.22),(1.08,-.43,3.24),(1.29,-.47,3.16),(1.39,-.50,3.04)],.285,.68)
for name in ('Ear_Upright','Ear_Folded','Ear_Upright_Pink','Ear_Folded_Pink'):
    obj=bpy.data.objects['CB_'+name]
    if not obj.modifiers.get('Smooth ear silhouette'):
        sub=obj.modifiers.new('Smooth ear silhouette','SUBSURF');sub.levels=1;sub.render_levels=1
        dec=obj.modifiers.new('Economical smooth ear','DECIMATE');dec.ratio=.32

import struct,zlib
png_rgba(WORK/'textures/iris-green.png',256,iris_pixel)
for image in bpy.data.images:
    if image.name.startswith('iris-green'):
        if image.packed_file:image.unpack(method='REMOVE')
        image.reload();image.pack()

def replace_ellipsoid(name,scale,segments,rings,mat):
    obj=bpy.data.objects['CB_'+name]
    tmp=ellipsoid(name+'_temp',tuple(obj.location),scale,mat,segments,rings)
    obj.data=tmp.data
    bpy.data.objects.remove(tmp,do_unlink=True)

for side in ('L','R'):
    replace_ellipsoid('EyeWhite_'+side,(.302,.057,.348),20,10,'EyeWhite')
    replace_ellipsoid('Catchlight_Main_'+side,(.071,.017,.080),12,6,'Glint')
    replace_ellipsoid('Catchlight_Small_'+side,(.028,.011,.032),10,6,'Glint')
replace_ellipsoid('Nose',(.103,.044,.063),16,8,'Nose')
replace_ellipsoid('Tail',(.30,.28,.30),20,10,'Cream')
replace_ellipsoid('Tail_Lobe_L',(.15,.19,.18),12,6,'Cream')
replace_ellipsoid('Tail_Lobe_R',(.16,.18,.18),12,6,'Cream')
for name,scale in [('Top',(.083,.040,.103)),('Left',(.097,.043,.077)),('Right',(.097,.043,.077)),('Bottom',(.078,.039,.087))]:
    replace_ellipsoid('Clover_'+name,scale,12,6,'Clover')
for o in asset.objects:
    if o.type=='CURVE':o.data.resolution_u=5;o.data.bevel_resolution=2

preview.world.node_tree.nodes.get('Background').inputs['Strength'].default_value=.22
preview.view_settings.exposure=.20
for name,power in [('Key',300),('Fill',170),('Rim',250)]:
    bpy.data.lights['CB_Preview_'+name].energy=power
preview.camera.location=(5,-8,5.0);aim(preview.camera,(0,0,1.78))
bpy.context.view_layer.update()
result={'refined_ear':True,'light_rebalanced':True}
