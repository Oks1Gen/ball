"""Build the approved egg stand in a separate Blender scene; never edits Studio.
Run in Blender with exec(compile(open(__file__, encoding='utf8').read(), __file__, 'exec')).
One Blender unit = five Roblox studs. Front faces -Y, up is +Z.
"""
import bpy
import math
import json
import bmesh
from pathlib import Path
from mathutils import Vector, Matrix

HERE = Path(__file__).resolve().parent
INCLUDE_EGGS = False  # Current approved model: empty stand, colored seats retained.
ROOT = HERE.parents[2]
HERE.mkdir(parents=True, exist_ok=True)
scene = bpy.data.scenes.new('EggStand_Arc_Final')
bpy.context.window.scene = scene
scene.unit_settings.system = 'METRIC'
scene.unit_settings.scale_length = 1.0
asset = bpy.data.collections.new('EggStand_Asset')
scene.collection.children.link(asset)
stage = bpy.data.collections.new('Presentation_ExcludedFromExport')
scene.collection.children.link(stage)

def lin(c):
    return c / 12.92 if c < .04045 else ((c + .055) / 1.055) ** 2.4

materials = {}
def mat(name, rgb, rough=.38):
    m = bpy.data.materials.new('Stand_' + name)
    m.diffuse_color = (*[lin(c) for c in rgb], 1)
    m.use_nodes = True
    bs = m.node_tree.nodes.get('Principled BSDF')
    bs.inputs['Base Color'].default_value = m.diffuse_color
    bs.inputs['Roughness'].default_value = rough
    materials[name] = m
    return m

gray=mat('CoolGray',(.67,.73,.81))
dark=mat('Charcoal',(.105,.14,.205))
red=mat('Red',(.95,.045,.055))
green=mat('Green',(.1,.92,.19))
cyan=mat('Cyan',(.02,.78,1))
purple=mat('Purple',(.67,.055,.96))
crimson=mat('Crimson',(.36,.025,.025))
gold=mat('Gold',(1,.72,.08))
ice=mat('Ice',(.12,.86,1))
blue=mat('Blue',(.025,.3,.97))
leaf=mat('Leaf',(.48,.97,.055))

def mesh(name, verts, faces, material, collection=asset):
    me=bpy.data.meshes.new(name+'_Mesh'); me.from_pydata(verts,[],faces); me.update()
    ob=bpy.data.objects.new(name,me); collection.objects.link(ob); me.materials.append(material)
    return ob

def bevel(ob, amount=.025):
    mod=ob.modifiers.new('Small edge bevel','BEVEL'); mod.width=amount; mod.segments=1
    mod.affect='EDGES'
    return ob

def prism(name, poly, bottom, top, material, collection=asset):
    n=len(poly)
    verts=[(x,y,z)for z in (bottom,top)for x,y in poly]
    faces=[tuple(reversed(range(n))),tuple(range(n,n*2))]
    faces += [(i,(i+1)%n,(i+1)%n+n,i+n) for i in range(n)]
    return mesh(name,verts,faces,material,collection)

def rect(x,y,w,d):
    return [(x-w/2,y-d/2),(x+w/2,y-d/2),(x+w/2,y+d/2),(x-w/2,y+d/2)]

def octagon(x,y,r):
    return [(x+r*math.cos(math.pi/8+i*math.pi/4),y+r*math.sin(math.pi/8+i*math.pi/4)) for i in range(8)]

def studs(name, boxes, material):
    vs=[]; fs=[]
    for x,y,z,w,d,h in boxes:
        off=len(vs)
        vs.extend([(x+dx*w/2,y+dy*d/2,z+dz*h/2) for dz in (-1,1) for dy in (-1,1) for dx in (-1,1)])
        fs.extend([tuple(off+i for i in f)for f in [(0,2,3,1),(4,5,7,6),(0,1,5,4),(2,6,7,3),(0,4,6,2),(1,3,7,5)]])
    return mesh(name,vs,fs,material) if vs else None

xs=[-12.1,-7.28,-2.44,2.44,7.28,12.1]
ys=[-1.65,-.96,-.12,-.12,-.96,-1.65]
centers=[(-9.68,-1.44),(-4.88,-.48),(0,0),(4.88,-.48),(9.68,-1.44)]
names=['Common','Uncommon','Volcanic','Rare','Rainbow']
colors=[red,green,dark,cyan,purple]
tops=[]
for i,(cx,cy) in enumerate(centers):
    x0,x1=xs[i:i+2]; y0,y1=ys[i:i+2]
    poly=[(x0,y0-1.85),(x1,y1-1.85),(x1,y1+1.85),(x0,y0+1.85)]
    if i==0:
        poly=[(x0+.38,y0-1.85),(x1,y1-1.85),(x1,y1+1.85),(x0+.38,y0+1.85),(x0,y0+1.47),(x0,y0-1.47)]
    elif i==4:
        poly=[(x0,y0-1.85),(x1-.38,y1-1.85),(x1,y1-1.47),(x1,y1+1.47),(x1-.38,y1+1.85),(x0,y0+1.85)]
    prism(names[i]+'_Foundation',poly,0,.16,dark)
    body=prism(names[i]+'_Bay',poly,.16,.64,gray)
    # Only bevel exterior silhouette lightly; matching seam planes remain aligned.
    bevel(body,.015)
    boxes=[]
    for ix in range(math.ceil(x0/.4),math.floor(x1/.4)+1):
        x=ix*.4
        if x<x0+.18 or x>x1-.18:continue
        t=(x-x0)/(x1-x0); mid=y0+(y1-y0)*t
        for iy in range(math.ceil((mid-1.6)/.4),math.floor((mid+1.6)/.4)+1):
            y=iy*.4
            if math.hypot(x-cx,y-cy)<1.55:continue
            boxes.append((x,y,.665,.22,.22,.05))
        boxes.append((x,mid-1.86,.4,.22,.05,.22))
    studs(names[i]+'_Studs',boxes,gray)
    # Rear edging is continuous gray, never grass.
    strip=[(x0,y0+1.60),(x1,y1+1.60),(x1,y1+1.85),(x0,y0+1.85)]
    prism(names[i]+'_RearRim',strip,.64,.84,gray)
    z=.64
    if i==2:
        bevel(prism('Volcanic_RaisedBay',octagon(cx,cy,1.95),z,z+.18,gray))
        z+=.18
    bevel(prism(names[i]+'_SeatRim',octagon(cx,cy,1.53),z,z+.13,colors[i]),.018)
    # A second, lighter top creates a shallow rim without a deep bowl.
    light=mat(names[i]+'_SeatInset',tuple(min(1,c*.75+.25)for c in ({0:(.95,.045,.055),1:(.1,.92,.19),2:(.105,.14,.205),3:(.02,.78,1),4:(.67,.055,.96)}[i])))
    prism(names[i]+'_SeatInset',octagon(cx,cy,1.36),z+.13,z+.145,light)
    tops.append(z+.145)

bevel(prism('Center_Step_Lower',rect(0,-2.58,4.35,1.02),0,.23,gray),.025)
bevel(prism('Center_Step_Upper',rect(0,-2.18,3.85,.65),.23,.46,gray),.025)
studs('CenterStep_Studs',[(x*.4,-2.95,.252,.22,.22,.045)for x in range(-5,6)]+[(x*.4,-2.28,.482,.22,.22,.045)for x in range(-4,5)],gray)

# Load original four egg assets; keep their authored geometry rather than approximate it.
source=Path.home()/'Downloads'/'6 интерактивных яиц.blend'
prefix=('Flame shard','Fire heart','Living spiral','Emerald leaf','Forest heart','Forest crown','Ice curled','Ice crown','Ice central','Arcane upper','Arcane lower','Arcane jewel','Arcane heart','Amethyst perimeter','Golden four','Golden crescent')
shells=['Fire Egg','Forest Egg','Ice Egg','Arcane Egg']
if source.exists():
    with bpy.data.libraries.load(str(source),link=False) as (src,dst):
        dst.objects=[n for n in src.objects if n in shells or n.startswith(prefix)]
    eggs=[o for o in dst.objects if o]
    for o in eggs: asset.objects.link(o)
else:
    before=set(bpy.data.objects)
    bpy.ops.import_scene.fbx(filepath=str(ROOT/'RojoTest/assets/imports/Eggs6_Simple.fbx'),use_image_search=False)
    eggs=[o for o in bpy.data.objects if o not in before and (o.name.split('.')[0] in shells or o.name.startswith(prefix))]
    for o in eggs:
        for c in list(o.users_collection):c.objects.unlink(o)
        asset.objects.link(o)
bpy.context.view_layer.update()

groups=[[],[],[],[],[]]
for ob in eggs:
    n=ob.name
    if n.startswith(('Fire Egg','Fire heart','Flame shard')):i=0
    elif n.startswith(('Forest','Living spiral','Emerald leaf')):i=1
    elif n.startswith(('Ice ',)):i=3
    else:i=4
    groups[i].append(ob)
    material = red if n.startswith('Fire Egg') else gold if i==0 else green if n.startswith('Forest Egg') else gold if n.startswith('Living spiral') else leaf if i==1 else blue if n.startswith('Ice Egg') else ice if i==3 else purple if n.startswith(('Arcane Egg','Amethyst','Arcane heart')) else gold
    if ob.type=='MESH':
        ob.data.materials.clear(); ob.data.materials.append(material)
        for p in ob.data.polygons:p.material_index=0
    elif ob.type=='CURVE':
        ob.data.materials.clear(); ob.data.materials.append(material)

# The premium egg is already archived as exact triangle geometry and original palette.
data=json.loads((ROOT/'RojoTest/assets/imports/decorated-egg-colors/02.json').read_text(encoding='utf8'))
verts=[(v[0],-v[2],v[1])for v in data['vertices']]
faces=[tuple(v-1 for v in t[:3])for t in data['triangles']]
vol=mesh('Volcanic_Original',verts,faces,crimson)
for name,col in [('VolcanicBasalt',(.14,.025,.025)),('VolcanicLava',(.55,.025,.015)),('VolcanicGold',(.4,.055,.025)),('VolcanicVermilion',(.38,.025,.02))]:
    vol.data.materials.append(mat(name,col))
for p,t in zip(vol.data.polygons,data['triangles']):p.material_index=t[3]-1
groups[2]=[vol]

for i,obs in enumerate(groups):
    bpy.context.view_layer.update()
    points=[o.matrix_world@Vector(v) for o in obs for v in o.bound_box]
    lo=Vector([min(v[k]for v in points)for k in range(3)])
    hi=Vector([max(v[k]for v in points)for k in range(3)])
    factor=2.85/(hi.z-lo.z)
    center=Vector(((lo.x+hi.x)/2,(lo.y+hi.y)/2,lo.z))
    target=Vector((*centers[i],tops[i]))
    root=bpy.data.objects.new('Egg_'+names[i],None);asset.objects.link(root);root.location=target
    bpy.context.view_layer.update()
    for o in obs:
        mw=Matrix.Translation(target)@Matrix.Scale(factor,4)@Matrix.Translation(-center)@o.matrix_world
        o.parent=root; o.matrix_world=mw
    bpy.context.view_layer.update()
    actual=[o.matrix_world@Vector(v)for o in obs for v in o.bound_box]
    assert abs(min(v.z for v in actual)-tops[i])<.001, 'Egg must rest on its pad'
    assert abs((min(v.x for v in actual)+max(v.x for v in actual))/2-centers[i][0])<.001, 'Egg must align with pad'

# A simple neutral presentation studio, always excluded from mesh exports.
floor=prism('PreviewGround',rect(0,0,200,200),-.16,-.06,mat('PreviewGround',(.24,.3,.39)),stage)
def aim(ob,point):ob.rotation_euler=(Vector(point)-ob.location).to_track_quat('-Z','Y').to_euler()
def camera(name,position,target,scale):
    c=bpy.data.cameras.new(name);o=bpy.data.objects.new(name,c);stage.objects.link(o);o.location=position;aim(o,target);c.type='ORTHO';c.ortho_scale=scale;return o
front=camera('Camera_Front',(6,-28,14),(0,-.25,1),27)
top=camera('Camera_Top',(0,-.4,32),(0,-.4,0),27)
top.rotation_euler=(0,0,0)
for name,pos,power,size in [('Key',(-8,-10,16),3800,10),('Fill',(10,-3,10),2600,9),('Rim',(2,8,13),4200,8)]:
    l=bpy.data.lights.new(name,'AREA');l.energy=power;l.shape='DISK';l.size=size
    o=bpy.data.objects.new(name,l);stage.objects.link(o);o.location=pos;aim(o,(0,0,0))
scene.world=bpy.data.worlds.new('EggStand_StudioWorld');scene.world.use_nodes=True
scene.world.node_tree.nodes['Background'].inputs[0].default_value=(.22,.27,.36,1)
scene.world.node_tree.nodes['Background'].inputs[1].default_value=.6
scene.render.engine='CYCLES';scene.cycles.samples=40
scene.cycles.use_denoising=True
scene.render.resolution_x=1800;scene.render.resolution_y=900;scene.render.resolution_percentage=100
scene.view_settings.view_transform='Standard'
scene.camera=front
scene.render.image_settings.file_format='PNG'

# Bake flat material palette into UVs for durable Roblox FBX/GLB import.
for ob in list(asset.objects):
    if ob.type=='CURVE':
        dg=bpy.context.evaluated_depsgraph_get()
        converted=bpy.data.meshes.new_from_object(ob.evaluated_get(dg),depsgraph=dg)
        replacement=bpy.data.objects.new(ob.name+'_Mesh',converted);asset.objects.link(replacement)
        replacement.parent=ob.parent;replacement.matrix_world=ob.matrix_world
        old_name=ob.name
        for group in groups:
            if ob in group:group[group.index(ob)]=replacement
        bpy.data.objects.remove(ob,do_unlink=True)
        replacement.name=old_name
# Close source ornament tube ends and weld coincident premium-egg seams.
for ob in asset.objects:
    if ob.type!='MESH':continue
    bm=bmesh.new();bm.from_mesh(ob.data)
    if any(not e.is_manifold for e in bm.edges):
        bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=.00001)
        boundary=[e for e in bm.edges if e.is_boundary]
        if boundary:bmesh.ops.holes_fill(bm,edges=boundary,sides=0)
        if any(e.is_boundary for e in bm.edges):
            bmesh.ops.solidify(bm,geom=list(bm.faces),thickness=.012)
        bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces))
        bm.to_mesh(ob.data);ob.data.update()
    bm.free()
if not INCLUDE_EGGS:
    for root in [o for o in asset.objects if o.type=='EMPTY' and o.name.startswith('Egg_')]:
        for child in list(root.children_recursive):bpy.data.objects.remove(child,do_unlink=True)
        bpy.data.objects.remove(root,do_unlink=True)
    groups=[]
allmats=[]
for ob in asset.objects:
    if ob.type=='MESH':
        for m in ob.data.materials:
            if m and m not in allmats:allmats.append(m)
width=128
image=bpy.data.images.new('EggStand_Palette',width=width,height=8,alpha=True)
pixels=[]
for y in range(8):
    for x in range(width):
        m=allmats[min(len(allmats)-1,int(x*len(allmats)/width))]
        pixels.extend(m.diffuse_color)
image.pixels=pixels
image.filepath_raw=str(HERE/'palette.png');image.file_format='PNG';image.save();image.pack()
for m in allmats:
    m.use_nodes=True
    bs=m.node_tree.nodes.get('Principled BSDF')
    tex=m.node_tree.nodes.new('ShaderNodeTexImage');tex.image=image;tex.interpolation='Closest'
    m.node_tree.links.new(tex.outputs['Color'],bs.inputs['Base Color'])
for ob in asset.objects:
    if ob.type!='MESH':continue
    for old_uv in list(ob.data.uv_layers):ob.data.uv_layers.remove(old_uv)
    uv=ob.data.uv_layers.new(name='PaletteUV')
    ob.data.uv_layers.active_index=len(ob.data.uv_layers)-1
    uv.active_render=True
    for poly in ob.data.polygons:
        m=ob.data.materials[poly.material_index]
        u=(allmats.index(m)+.5)/len(allmats)
        for li in poly.loop_indices:uv.data[li].uv=(u,.5)

bpy.context.view_layer.update()
for ob in bpy.context.selected_objects:ob.select_set(False)
for ob in asset.objects:ob.select_set(True)
bpy.context.view_layer.objects.active=next(o for o in asset.objects if o.type=='MESH')
if INCLUDE_EGGS:
    bpy.ops.export_scene.fbx(filepath=str(HERE/'egg-stand-with-eggs.fbx'),use_selection=True,object_types={'MESH','EMPTY'},bake_anim=False,path_mode='COPY',embed_textures=True,axis_forward='-Z',axis_up='Y',use_custom_props=True)
bpy.ops.export_scene.gltf(filepath=str(HERE/('egg-stand-with-eggs.glb' if INCLUDE_EGGS else 'stand-only.glb')),use_selection=True,use_active_scene=True,export_format='GLB')
for ob in asset.objects:ob.select_set(not ob.name.startswith(('Egg_','Volcanic_Original')) and not any(ob in g for g in groups))
bpy.ops.export_scene.fbx(filepath=str(HERE/'stand-only.fbx'),use_selection=True,object_types={'MESH'},bake_anim=False,path_mode='COPY',embed_textures=True,axis_forward='-Z',axis_up='Y')
for ob in asset.objects:ob.select_set(True)
for area in bpy.context.screen.areas:
    if area.type=='VIEW_3D':
        area.spaces.active.region_3d.view_perspective='CAMERA'
        area.spaces.active.shading.type='MATERIAL'
scene['RobloxStudsPerBlenderUnit']=5
scene['SourceEggCentersRoblox']='Common (103.8,276); Uncommon (79.8,280.8); Volcanic (55.4,283.2); Rare (31,280.8); Rainbow (7,276)'
bpy.ops.wm.save_as_mainfile(filepath=str(HERE/'egg-stand.blend'))
result={'blend':str(HERE/'egg-stand.blend'),'objects':len(asset.objects),'eggs':len(groups),'render_ready':True}
