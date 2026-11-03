"""Reconstruct the five approved reference eggs in Blender; assets only, no world rebuild.
Authoring coordinates: X right, -Y front, Z up. Each finished egg is 10 Roblox studs high.
Run in Blender with __file__ assigned to this file. Deterministic procedural source.
"""
import bpy, bmesh, math, random, json
from pathlib import Path
from mathutils import Vector, Matrix, Euler

HERE = Path(__file__).resolve().parent
HERE.mkdir(parents=True, exist_ok=True)
if bpy.context.object and bpy.context.object.mode != 'OBJECT':
    bpy.ops.object.mode_set(mode='OBJECT')
backup = HERE / 'blender-session-before-eggs.blend'
if not backup.exists():
    bpy.ops.wm.save_as_mainfile(filepath=str(backup), copy=True)
for old in list(bpy.data.collections):
    if old.name in ('ElementalEggs_Asset', 'Presentation_NotExported', 'ExportTemporary'):
        for ob in list(old.objects):bpy.data.objects.remove(ob,do_unlink=True)
        bpy.data.collections.remove(old)
old=bpy.data.scenes.get('ElementalEggs_Reference_v1')
if old:
    bpy.context.window.scene=next(s for s in bpy.data.scenes if s!=old)
    bpy.data.scenes.remove(old)
scene = bpy.data.scenes.new('ElementalEggs_Reference_v1')
bpy.context.window.scene = scene
scene.unit_settings.system = 'METRIC'
scene.unit_settings.scale_length = 1
asset = bpy.data.collections.new('ElementalEggs_Asset')
scene.collection.children.link(asset)
stage = bpy.data.collections.new('Presentation_NotExported')
scene.collection.children.link(stage)
MATS = []
EGGS = []

def lin(x):
    return x/12.92 if x <= .04045 else ((x+.055)/1.055)**2.4

def material(name, color, rough=.43, metal=0, emission=0):
    m = bpy.data.materials.new('Egg_' + name)
    m.use_nodes = True
    m.diffuse_color = (*[lin(c) for c in color], 1)
    p = m.node_tree.nodes.get('Principled BSDF')
    p.inputs['Base Color'].default_value = m.diffuse_color
    p.inputs['Roughness'].default_value = rough
    p.inputs['Metallic'].default_value = metal
    if emission:
        p.inputs['Emission Color'].default_value = m.diffuse_color
        p.inputs['Emission Strength'].default_value = emission
    m['srgb'] = list(color)
    m['glow'] = emission > 0
    MATS.append(m)
    return m

bark = material('Bark', (.34,.145,.052))
bark_light = material('BarkWarm', (.48,.245,.09))
leaf_dark = material('LeafEmerald', (.035,.46,.08))
leaf_mid = material('LeafGreen', (.19,.70,.025))
leaf_lime = material('LeafLime', (.50,.88,.018))
leaf_light = material('LeafTip', (.67,.96,.025))
ice_core = material('IceCore', (.035,.72,.94), emission=.3)
ice_white = material('IceWhite', (.82,.94,1))
ice_pale = material('IcePale', (.60,.85,.98))
ice_blue = material('IceBlue', (.09,.67,.95), rough=.27)
ice_cyan = material('IceCyan', (.06,.88,1), rough=.25)
lava_core = material('LavaGold', (1,.51,.015), emission=1.2)
lava_edge = material('LavaOrange', (1,.19,.008), emission=.25)
rock = material('VolcanicRock', (.19,.155,.205))
rock_red = material('VolcanicWarm', (.28,.14,.18))
rock_top = material('VolcanicSlate', (.27,.235,.285))
void_core = material('VoidLight', (.83,.015,1), emission=.65)
void_dark = material('VoidDark', (.14,.012,.27))
void_mid = material('VoidPurple', (.31,.012,.58))
void_light = material('VoidViolet', (.50,.025,.84))
void_tip = material('VoidAmethyst', (.64,.025,.96), rough=.3)
ivory = material('Ivory', (.94,.89,.74), rough=.39)
ivory_light = material('IvoryLight', (1,.97,.86), rough=.4)
ivory_warm = material('IvoryWarm', (.85,.77,.59), rough=.43)
gold = material('Gold', (1,.66,.025), rough=.29, metal=.28)
gold_light = material('GoldLight', (1,.83,.10), rough=.3, metal=.2)
gold_dark = material('GoldRecess', (.69,.36,.012), rough=.36, metal=.18)
gem = material('Turquoise', (.015,.82,.85), rough=.25)

def mesh(name, verts, faces, mats, indices=None, parent=None, collection=None):
    me = bpy.data.meshes.new(name + '_Mesh')
    me.from_pydata(verts, [], faces)
    me.update()
    ob = bpy.data.objects.new(name, me)
    (collection or asset).objects.link(ob)
    for m in mats:
        me.materials.append(m)
    if indices:
        for p,i in zip(me.polygons, indices): p.material_index = i
    bm = bmesh.new(); bm.from_mesh(me)
    bmesh.ops.recalc_face_normals(bm, faces=list(bm.faces))
    bm.to_mesh(me); bm.free()
    if parent:
        ob.parent = parent
    return ob

def root(name):
    ob = bpy.data.objects.new(name, None)
    asset.objects.link(ob)
    ob.empty_display_type = 'PLAIN_AXES'
    ob['AssetTheme'] = name
    EGGS.append(ob)
    return ob

def eggpoint(d, h=2.8, radius=1.02):
    d = Vector(d).normalized()
    return Vector((d.x*radius*(.96-.15*d.z), d.y*radius*(.96-.15*d.z), h*(d.z+1)/2))

def core(parent, mat, radius=.98, h=2.8, segments=16, rings=8):
    vs=[(0,0,0)]
    for j in range(1,rings):
        t=math.pi*j/rings
        for i in range(segments):
            a=2*math.pi*i/segments
            vs.append(eggpoint((math.sin(t)*math.cos(a),math.sin(t)*math.sin(a),-math.cos(t)),h,radius))
    vs.append((0,0,h)); fs=[]
    for i in range(segments): fs.append((0,1+(i+1)%segments,1+i))
    for j in range(rings-2):
        for i in range(segments):
            a=1+j*segments+i; b=1+j*segments+(i+1)%segments
            c=b+segments; d=a+segments
            fs.extend([(a,b,c),(a,c,d)])
    top=len(vs)-1; start=1+(rings-2)*segments
    for i in range(segments):fs.append((start+i,start+(i+1)%segments,top))
    return mesh(parent.name+'_InnerShell',vs,fs,[mat],parent=parent)

def cells(count, seed):
    rng=random.Random(seed); ps=[]
    for i in range(count):
        z=1-2*(i+.5)/count
        a=i*math.pi*(3-math.sqrt(5))+rng.uniform(-.18,.18)
        r=math.sqrt(1-z*z)
        ps.append(Vector((r*math.cos(a),r*math.sin(a),z)))
    result=[]
    for i,p in enumerate(ps):
        corners=[]
        for j,q in enumerate(ps):
            if i==j:continue
            for k in range(j+1,len(ps)):
                if k==i:continue
                d=(p-q).cross(p-ps[k])
                if d.length<1e-7:continue
                d.normalize()
                for v in (d,-d):
                    a=p.dot(v)
                    if all(a>=s.dot(v)-1e-6 for s in ps):
                        if not any((v-t).length<1e-4 for t in corners):corners.append(v.copy())
        u=p.cross(Vector((0,0,1)))
        if u.length<.01:u=p.cross(Vector((0,1,0)))
        u.normalize();v=p.cross(u).normalized()
        corners.sort(key=lambda q:math.atan2(q.dot(v),q.dot(u)))
        result.append((p,corners))
    return result

def plates(parent,count,seed,mats,side,shrink=.90,raise_by=.07,h=2.8,radius=1.02,top_gold=False):
    rng=random.Random(seed)
    for i,(p,poly) in enumerate(cells(count,seed)):
        if len(poly)<3:continue
        inner=[(p+(v-p)*shrink).normalized() for v in poly]
        n=len(inner)
        outer=[eggpoint(v,h,radius)+Vector((v.x,v.y,v.z*.7))*raise_by for v in inner]
        back=[eggpoint(v,h,radius-.07) for v in inner]
        bevel=[x.lerp(eggpoint(p,h,radius),.16)+p*raise_by*.3 for x in outer]
        peak=eggpoint(p,h,radius)+p*(raise_by+.06+rng.random()*.035)
        vs=back+outer+bevel+[peak]
        fs=[];ids=[]
        for j in range(n):
            k=(j+1)%n
            fs.extend([(j,k,n+k,n+j),(n+j,n+k,2*n+k,2*n+j),(2*n+j,2*n+k,3*n)])
            ids.extend([len(mats),0,rng.randrange(len(mats))])
        fs.append(tuple(reversed(range(n))));ids.append(len(mats))
        chosen=[gold,gold_light] if top_gold and p.z>.84 else mats
        # Keep all indices valid when using the gold cap.
        chosen=(chosen+[chosen[-1]]*len(mats))[:len(mats)]
        mesh(parent.name+f'_Plate_{i+1:02}',vs,fs,chosen+[side],ids,parent)

def leaf(parent,name,a,z0,z1,width,twist,mats,rad=1.04,bulge=.10,tipflare=.05):
    ts=[0,.27,.57,.81,1]
    vs=[]; rows=[]
    for row,t in enumerate(ts):
        z=z0+(z1-z0)*t
        az=a+twist*(t-.5)
        w=width*(math.sin(math.pi*t)**.75)
        # Surface follows the egg; the tip gently peels away from it.
        dz=max(-.995,min(.995,2*z/2.8-1))
        rr=rad*math.sqrt(1-dz*dz)*(.96-.15*dz)+tipflare*(t**4)
        if row in (0,len(ts)-1):
            rows.append([len(vs)])
            vs.append((rr*math.cos(az),rr*math.sin(az),z))
        else:
            rows.append([])
            for off in (-1,0,1):
                phi=az+off*w/max(rr,.35)
                r=rr+(bulge if off==0 else 0)
                rows[-1].append(len(vs));vs.append((r*math.cos(phi),r*math.sin(phi),z))
    fs=[]
    fs.extend([(rows[0][0],rows[1][1],rows[1][0]),(rows[0][0],rows[1][2],rows[1][1])])
    for j in (1,2):
        a0,b=rows[j],rows[j+1]
        fs.extend([(a0[0],a0[1],b[1]),(a0[0],b[1],b[0]),(a0[1],a0[2],b[2]),(a0[1],b[2],b[1])])
    fs.extend([(rows[3][0],rows[3][1],rows[4][0]),(rows[3][1],rows[3][2],rows[4][0])])
    outline=[rows[0][0]]+[rows[j][0]for j in (1,2,3)]+[rows[4][0]]+[rows[j][-1]for j in (3,2,1)]
    n=len(vs)
    vs += [(x*.955,y*.955,z) for x,y,z in vs]
    top=list(fs)
    fs += [tuple(v+n for v in reversed(f))for f in top]
    for j,u in enumerate(outline):
        v=outline[(j+1)%len(outline)];fs.append((u,v,v+n,u+n))
    ids=[(i//2)%len(mats)for i in range(len(top))]+[0]*(len(fs)-len(top))
    ob=mesh(name,vs,fs,mats,ids,parent)
    # A convex leaf volume prevents thin folded strips from cutting through one another.
    hull=bmesh.new()
    for co in vs:hull.verts.new(co)
    bmesh.ops.convex_hull(hull,input=list(hull.verts),use_existing_faces=False)
    loose=[v for v in hull.verts if not v.link_faces]
    if loose:bmesh.ops.delete(hull,geom=loose,context='VERTS')
    bmesh.ops.recalc_face_normals(hull,faces=list(hull.faces))
    for f in hull.faces:
        center=f.calc_center_median();radial=Vector((center.x,center.y,0)).normalized()
        f.material_index=(1 if f.normal.dot(radial)>.35 and len(mats)>1 else 0)
        if f.normal.z>.35 and len(mats)>2:f.material_index=2
    hull.to_mesh(ob.data);hull.free()
    return ob

def crystal(parent,name,base,length,width,axis,mats,sides=5):
    axis=Vector(axis).normalized()
    rot=Vector((0,0,1)).rotation_difference(axis).to_matrix()
    vs=[]
    for z,r in ((0,.65),(length*.28,1),(length*.65,.78)):
        for i in range(sides):
            a=i*2*math.pi/sides
            vs.append(Vector(base)+rot@Vector((math.cos(a)*width*r,math.sin(a)*width*r,z)))
    vs.append(Vector(base)+axis*length)
    fs=[tuple(reversed(range(sides)))];ids=[0]
    for j in range(2):
        for i in range(sides):
            k=(i+1)%sides;fs.append((j*sides+i,j*sides+k,(j+1)*sides+k,(j+1)*sides+i));ids.append(i%len(mats))
    for i in range(sides):fs.append((2*sides+i,2*sides+(i+1)%sides,3*sides));ids.append(i%len(mats))
    return mesh(name,vs,fs,mats,ids,parent)

meadow=root('Meadow')
core(meadow,bark,radius=.80)
for band,(lo,hi,n,w,tw) in enumerate(((.03,1.75,5,.65,1.02),(.53,2.56,5,.65,1.05),(1.40,2.91,4,.47,.78))):
    for i in range(n):
        a=-math.pi/2+i*2*math.pi/n+band*.73
        ms=([leaf_dark,leaf_mid,leaf_mid] if band==0 else [leaf_mid,leaf_lime,leaf_light])
        leaf(meadow,f'Meadow_Leaf_{band}_{i}',a,lo,hi,w,tw,ms,tipflare=.13)

glacier=root('Glacier')
core(glacier,ice_core,radius=1.035)
plates(glacier,18,52,[ice_white,ice_pale,ice_white],ice_blue,shrink=.90,raise_by=.075)
for i,(x,y,z,l,w) in enumerate(((0,.04,2.54,.83,.23),(-.38,.05,2.48,.60,.20),(.40,.04,2.44,.65,.19),(-.70,.18,2.28,.48,.18),(.72,.15,2.23,.50,.18))):
    crystal(glacier,f'Glacier_Crown_{i}',(x,y,z),l,w,(x*.4,0,1),[ice_cyan,ice_blue,ice_pale])
for i,a in enumerate((-2.7,-1.75,-.65,.15,1.7)):
    crystal(glacier,f'Glacier_BaseCrystal_{i}',(.78*math.cos(a),.78*math.sin(a),.23),.65,.22,(.8*math.cos(a),.8*math.sin(a),.9),[ice_blue,ice_cyan,ice_pale])

magma=root('Magma')
core(magma,lava_core,radius=.92)
plates(magma,17,16,[rock,rock_top,rock_red],lava_edge,shrink=.89,raise_by=.095)

void=root('Void')
core(void,void_core,radius=.82,h=2.62)
plates(void,9,43,[void_dark,void_mid,void_light],void_dark,shrink=.96,raise_by=.045)
for i,(x,y,z,l,w) in enumerate(((0,.06,2.48,.95,.29),(-.41,.08,2.38,.66,.21),(.43,.12,2.36,.67,.22))):
    crystal(void,f'Void_Crown_{i}',(x,y,z),l,w,(x*.25,0,1),[void_dark,void_mid,void_tip,void_light])
for i,a in enumerate((-2.55,-.55,.85,2)):
    leaf(void,f'Void_Blade_{i}',a,.04,1.68,.24,.25,[void_dark,void_mid,void_light],rad=1.12,bulge=.12,tipflare=.15)

celestial=root('Celestial')
core(celestial,gold_dark,radius=1.035)
plates(celestial,21,31,[ivory,ivory_light,ivory_warm],gold,shrink=.91,raise_by=.075,top_gold=True)
rot=Euler((math.radians(11),math.radians(-30),math.radians(2))).to_matrix()
vs=[];N=40
for i in range(N):
    a=i*2*math.pi/N
    for r,z in ((1.33,-.065),(1.51,-.065),(1.51,.065),(1.33,.065)):
        vs.append(rot@Vector((r*math.cos(a),r*math.sin(a),z))+Vector((0,0,1.42)))
fs=[];ids=[]
for i in range(N):
    for k in range(4):
        fs.append((4*i+k,4*((i+1)%N)+k,4*((i+1)%N)+(k+1)%4,4*i+(k+1)%4));ids.append((k+1)%3)
mesh('Celestial_OrbitRing',vs,fs,[gold,gold_light,gold_dark],ids,celestial)
for i,(a,z,w,l) in enumerate(((-1.95,1.95,.13,.32),(-1.18,.70,.14,.36),(-1.45,2.35,.10,.19))):
    dz=2*z/2.8-1;r=1.09*math.sqrt(max(0,1-dz*dz))*(.96-.15*dz)
    pos=Vector((r*math.cos(a),r*math.sin(a),z))
    normal=Vector((math.cos(a),math.sin(a),.12)).normalized()
    crystal(celestial,f'Celestial_Gem_{i}',pos,l,w,normal,[gem,ice_cyan,ice_blue]if i==2 else[gold,gold_light,gold_dark],sides=4)

# Ground-normalize each asset, keep 10-stud exact visible height, origin at base.
for i,rt in enumerate(EGGS):
    for ob in rt.children:
        for v in ob.data.vertices:v.co.z=max(0,v.co.z-.12)
    verts=[ob.matrix_local@v.co for ob in rt.children if ob.type=='MESH' for v in ob.data.vertices]
    low=min(v.z for v in verts);high=max(v.z for v in verts)
    scale=10/(high-low)
    for ob in rt.children:
        for v in ob.data.vertices:v.co=Vector((v.co.x*scale,v.co.y*scale,(v.co.z-low)*scale))
    rt.location=(i*8.8-17.6,0,0)
    rt['DisplayHeightStuds']=10
    rt['PivotAtBase']=True

# Shared flat palette atlas, per-face UVs, native material colors also retained.
size=256;tile=32
image=bpy.data.images.new('ElementalEggs_Palette',width=size,height=size,alpha=True)
pixels=[0.]*(size*size*4)
for mi,m in enumerate(MATS):
    cx=(mi%8)*tile;cy=(mi//8)*tile
    col=(*[lin(c)for c in m['srgb']],1)
    for y in range(cy,cy+tile):
        for x in range(cx,cx+tile):pixels[(y*size+x)*4:(y*size+x)*4+4]=col
image.pixels.foreach_set(pixels)
image.filepath_raw=str(HERE/'palette.png');image.file_format='PNG';image.save();image.pack()
for ob in asset.objects:
    if ob.type!='MESH':continue
    uv=ob.data.uv_layers.new(name='PaletteUV')
    for p in ob.data.polygons:
        mi=MATS.index(ob.data.materials[p.material_index])
        center=((mi%8+.5)/8,(mi//8+.5)/8)
        for li in p.loop_indices:uv.data[li].uv=center

scene.render.engine='CYCLES';scene.cycles.samples=16
scene.cycles.use_denoising=True
scene.render.resolution_x=2100;scene.render.resolution_y=850;scene.render.resolution_percentage=100
scene.world=bpy.data.worlds.new('Eggs_StudioWorld');scene.world.use_nodes=True
scene.world.node_tree.nodes['Background'].inputs[0].default_value=(.24,.32,.44,1)
scene.world.node_tree.nodes['Background'].inputs[1].default_value=.45
scene.view_settings.view_transform='Standard'
scene.view_settings.look='None'
scene.view_settings.exposure=-1.1
mesh('PreviewFloor',[(-100,-100,-.07),(100,-100,-.07),(100,100,-.07),(-100,100,-.07)],[(0,1,2,3)],[material('PreviewBlue',(.57,.69,.81),rough=.8)],collection=stage)
def aim(ob,point):ob.rotation_euler=(Vector(point)-ob.location).to_track_quat('-Z','Y').to_euler()
def area(name,pos,power,size,color):
    d=bpy.data.lights.new(name,'AREA');d.energy=power;d.shape='DISK';d.size=size;d.color=color
    ob=bpy.data.objects.new(name,d);stage.objects.link(ob);ob.location=pos;aim(ob,(0,0,4));return ob
area('Key',(-20,-28,37),26000,23,(1,.94,.86))
area('Fill',(25,-12,20),15000,22,(.71,.85,1))
area('Rim',(5,16,27),23000,18,(.82,.90,1))
d=bpy.data.cameras.new('ReferenceCamera');cam=bpy.data.objects.new('ReferenceCamera',d);stage.objects.link(cam)
cam.location=(0,-65,20);aim(cam,(0,0,4.9));d.type='ORTHO';d.ortho_scale=49;scene.camera=cam
scene.render.filepath=str(HERE/'preview-front.png')
bpy.ops.wm.save_as_mainfile(filepath=str(HERE/'elemental-eggs.blend'))

# Mesh payload is exact Blender geometry, local to each egg, +Y is Roblox up.
payload={'schema':1,'heightStuds':10,'front':'+Z','eggs':[]}
validation=[]
for rt in EGGS:
    chunks=[];totaltri=0;degenerate=0;nonmanifold=0
    for ob in rt.children:
        if ob.type!='MESH':continue
        me=ob.data;me.calc_loop_triangles()
        bm=bmesh.new();bm.from_mesh(me);nonmanifold+=sum(not e.is_manifold for e in bm.edges);bm.free()
        tris=[]
        for t in me.loop_triangles:
            a,b,c=[me.vertices[j].co for j in t.vertices]
            if (b-a).cross(c-a).length<1e-7:degenerate+=1;continue
            m=me.materials[t.material_index]
            tris.append({'v':list(t.vertices),'c':list(m['srgb']),'glow':bool(m['glow'])})
        chunks.append({'name':ob.name,'vertices':[[round(v.co.x,6),round(v.co.z,6),round(-v.co.y,6)]for v in me.vertices],'triangles':tris})
        totaltri+=len(tris)
    payload['eggs'].append({'name':rt.name,'meshes':chunks})
    validation.append({'name':rt.name,'objects':len(chunks),'triangles':totaltri,'degenerate':degenerate,'nonmanifoldEdges':nonmanifold})
(HERE/'geometry.json').write_text(json.dumps(payload,separators=(',',':')),encoding='utf8')
(HERE/'validation.json').write_text(json.dumps(validation,indent=2),encoding='utf8')
bpy.ops.object.select_all(action='DESELECT')
for rt in EGGS:
    rt.select_set(True)
    for ob in rt.children:ob.select_set(True)
bpy.context.view_layer.objects.active=EGGS[0]
# Export palette-textured duplicates, leave the source materials intact.
export_collection=bpy.data.collections.new('ExportTemporary');scene.collection.children.link(export_collection)
pm=bpy.data.materials.new('ElementalEggs_SharedPalette');pm.use_nodes=True
tex=pm.node_tree.nodes.new('ShaderNodeTexImage');tex.image=image;tex.interpolation='Closest'
bs=pm.node_tree.nodes.get('Principled BSDF');bs.inputs['Roughness'].default_value=.42
pm.node_tree.links.new(tex.outputs['Color'],bs.inputs['Base Color'])
bpy.ops.object.select_all(action='DESELECT')
copies=[]
for rt in EGGS:
    er=rt.copy();export_collection.objects.link(er);copies.append(er);er.select_set(True)
    for ob in rt.children:
        cp=ob.copy();cp.data=ob.data.copy();export_collection.objects.link(cp);cp.parent=er
        cp.data.materials.clear();cp.data.materials.append(pm)
        for p in cp.data.polygons:p.material_index=0
        cp.select_set(True);copies.append(cp)
bpy.context.view_layer.objects.active=copies[0]
bpy.ops.export_scene.fbx(filepath=str(HERE/'elemental-eggs.fbx'),use_selection=True,object_types={'EMPTY','MESH'},axis_forward='-Z',axis_up='Y',apply_unit_scale=True,global_scale=1,path_mode='COPY',embed_textures=True,mesh_smooth_type='FACE',add_leaf_bones=False)
bpy.ops.export_scene.gltf(filepath=str(HERE/'elemental-eggs.glb'),use_selection=True,use_active_scene=True,export_format='GLB',export_yup=True)
for ob in copies:bpy.data.objects.remove(ob,do_unlink=True)
bpy.data.collections.remove(export_collection)
for rt in EGGS:
    for ob in rt.children:ob.select_set(True)
bpy.context.view_layer.objects.active=EGGS[0].children[0]
for screen in bpy.data.screens:
    for ar in screen.areas:
        if ar.type=='VIEW_3D':
            ar.spaces.active.region_3d.view_distance=60
            ar.spaces.active.region_3d.view_location=Vector((0,0,5))
bpy.ops.wm.save_as_mainfile(filepath=str(HERE/'elemental-eggs.blend'))
result={'file':str(HERE/'elemental-eggs.blend'),'validation':validation,'fbx':str(HERE/'elemental-eggs.fbx')}
