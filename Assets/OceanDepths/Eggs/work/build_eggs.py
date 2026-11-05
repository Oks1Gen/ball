"""Ocean eggs selected 3,10,4,8,6. Run in the connected Blender via MCP.
X right, -Y front, Z up. Modelling only; does not modify the Roblox map.
"""
import bpy, bmesh, math, json
from mathutils import Vector, Quaternion
from pathlib import Path

BASE = Path(__file__).resolve().parent.parent
OUT = BASE / 'model'
WORK = BASE / 'work'
OUT.mkdir(parents=True, exist_ok=True)
TAU = math.tau
if bpy.context.object and bpy.context.object.mode != 'OBJECT':
    bpy.ops.object.mode_set(mode='OBJECT')
if not (WORK / 'session-before-eggs.blend').exists():
    bpy.ops.wm.save_as_mainfile(filepath=str(WORK / 'session-before-eggs.blend'), copy=True)
old = bpy.data.scenes.get('Ocean Eggs • Common to Legendary')
if old:
    bpy.context.window.scene = next(s for s in bpy.data.scenes if s != old)
    for col in list(old.collection.children):
        for ob in list(col.all_objects): bpy.data.objects.remove(ob, do_unlink=True)
        bpy.data.collections.remove(col)
    bpy.data.scenes.remove(old)
    for m in list(bpy.data.materials):
        if m.name.startswith('OceanEgg_') and m.users == 0: bpy.data.materials.remove(m)
SCENE = bpy.data.scenes.new('Ocean Eggs • Common to Legendary')
bpy.context.window.scene = SCENE
SCENE['asset_revision']=2
ASSET = bpy.data.collections.new('OceanEggs_Models')
SCENE.collection.children.link(ASSET)
STAGE = bpy.data.collections.new('Presentation_NotExported')
SCENE.collection.children.link(STAGE)
ROOTS = []
PARTS = {}

def linear(c):
    return c / 12.92 if c <= .04045 else ((c + .055) / 1.055) ** 2.4

def mat(name, hexcolor, metal=0, rough=.4, emission=0, alpha=1, transmission=0):
    h = hexcolor.lstrip('#')
    srgb = [int(h[i:i+2], 16)/255 for i in (0,2,4)]
    c = tuple(linear(v) for v in srgb)
    m = bpy.data.materials.new('OceanEgg_' + name)
    m.use_nodes = True
    m.diffuse_color = (*c, alpha)
    p = next(n for n in m.node_tree.nodes if n.type == 'BSDF_PRINCIPLED')
    p.inputs['Base Color'].default_value = (*c,1)
    p.inputs['Metallic'].default_value = metal
    p.inputs['Roughness'].default_value = rough
    p.inputs['Alpha'].default_value = alpha
    p.inputs['Transmission Weight'].default_value = transmission
    p.inputs['IOR'].default_value = 1.36
    p.inputs['Coat Weight'].default_value = .18
    if emission:
        p.inputs['Emission Color'].default_value = (*c,1)
        p.inputs['Emission Strength'].default_value = emission
    if alpha < 1:
        m.surface_render_method = 'DITHERED'
        m.use_transparent_shadow = True
    m['reference_srgb_hex'] = hexcolor
    return m

TEAL = mat('Kelp_Teal', '#126477')
TEAL_L = mat('Kelp_TealFacet', '#1B7282')
TEAL_D = mat('Kelp_Deep', '#105A70')
SAND = mat('Kelp_Sand', '#C6AE79')
SAND_L = mat('Kelp_SandLight', '#E6CA8F')
OLIVE = mat('Kelp_StemOlive', '#7E962B')
OLIVE_L = mat('Kelp_StemEdge', '#B5BF32')
GOLD = mat('Gold', '#F0B72F', .24, .31)
GOLD_L = mat('GoldLight', '#FFD454', .22, .3)
GOLD_D = mat('GoldRecess', '#AB6716', .35, .37)
LEAF = mat('Kelp_AmberLeaf', '#EBB52A', .12, .4)
LEAF_L = mat('Kelp_AmberRidge', '#FFD14A', .1, .36)
ARMOR = mat('Leviathan_Teal', '#075375', .15, .34)
ARMOR_L = mat('Leviathan_TealFacet', '#087C94', .12, .33)
ARMOR_D = mat('Leviathan_Deep', '#053F5D', .08, .4)
IVORY = mat('Horn_Ivory', '#F4E7C3', 0, .4)
IVORY_D = mat('Horn_Shadow', '#D4C29C', 0, .42)
NAVY = mat('Treasure_Navy', '#233A70', .1, .4)
NAVY_L = mat('Treasure_NavyFacet', '#2B437C', .08, .38)
NAVY_D = mat('Treasure_Deep', '#1F3566', .06, .42)
GEM = mat('AquaGem', '#23D9E6', .16, .22, .38)
GEM_L = mat('AquaGemLight', '#9AF7F5', .12, .2, .4)
GEM_D = mat('AquaGemDeep', '#00A7C6', .18, .27, .2)
SHELL = mat('Barnacle_Ivory', '#C9BDAA', 0, .64)
SHELL_L = mat('Barnacle_Edge', '#EEE3CE', 0, .57)
SHELL_D = mat('Barnacle_Inside', '#7E7167', 0, .8)
INDIGO = mat('Abyss_Indigo', '#231B56', .12, .4)
INDIGO_L = mat('Abyss_Armor', '#3A2879', .15, .34)
INDIGO_D = mat('Abyss_Deep', '#151737', .1, .43)
INDIGO_EDGE = mat('Abyss_Ridge', '#58489B', .15, .34)
CYAN = mat('CyanLight', '#04D1FF', .08, .25, 1.2)
CYAN_SOFT = mat('CyanEdge', '#28A3DA', .12, .3, .45)
JELLY = mat('Jelly_TranslucentLilac', '#AB63EB', 0, .23, .03, .79, .23)
JELLY_L = mat('Jelly_TranslucentFacet', '#BB7BF3', 0, .24, .03, .75, .26)
JELLY_D = mat('Jelly_TranslucentViolet', '#9753D3', 0, .25, .03, .81, .20)
JELLY_CORE = mat('Jelly_InnerPearl', '#D5AEFA', .02, .3, .45)
JELLY_TIP = mat('Jelly_TendrilTips', '#B0E9FF', 0, .24, .25, .8, .24)

def mesh(name, verts, faces, mats, ids=None, parent=None, collection=None):
    me = bpy.data.meshes.new(name + '_Mesh')
    me.from_pydata(verts, [], faces)
    me.update()
    bm = bmesh.new(); bm.from_mesh(me)
    bmesh.ops.recalc_face_normals(bm, faces=list(bm.faces))
    bm.to_mesh(me); bm.free()
    ob = bpy.data.objects.new(name, me)
    (collection or ASSET).objects.link(ob)
    for m in mats: me.materials.append(m)
    if ids:
        for p, i in zip(me.polygons, ids): p.material_index = i % len(mats)
    if parent:
        ob.parent = parent
        PARTS[parent.name].append(ob)
    return ob

PROFILE = [(0,.43),(.12,.77),(.4,1.14),(.8,1.44),(1.3,1.64),(1.85,1.72),(2.4,1.68),(2.95,1.53),(3.45,1.29),(3.9,.99),(4.25,.63),(4.5,.27),(4.63,0)]
def radius(z):
    z = max(0,min(4.63,z))
    for (a,r),(b,s) in zip(PROFILE, PROFILE[1:]):
        if a <= z <= b: return r + (s-r)*(z-a)/(b-a)
    return 0

def point(z, theta, offset=0):
    r = radius(z) + offset
    return Vector((r*math.cos(theta),r*math.sin(theta),z))

def newroot(name, x, tier, ref, symmetry):
    r = bpy.data.objects.new(name, None)
    ASSET.objects.link(r)
    r.location = (x,0,0)
    r.empty_display_size = .35
    r['rarity'] = tier; r['reference_number'] = ref
    r['rotational_symmetry'] = symmetry
    r['front'] = '-Y'; r['pivot'] = 'base_center'; r['authoring_height'] = 4.63
    ROOTS.append(r); PARTS[r.name] = []
    return r

def core(root, mats, n=36, profile=PROFILE):
    rings = profile[:-1]
    v = [(r*math.cos(TAU*j/n),r*math.sin(TAU*j/n),z) for z,r in rings for j in range(n)]
    f=[]; ids=[]
    for k in range(len(rings)-1):
        for j in range(n):
            a=k*n+j; b=k*n+(j+1)%n; c=(k+1)*n+(j+1)%n; d=(k+1)*n+j
            f += [(a,b,c),(a,c,d)]
            color = 1 if j%3==1 and k%3==1 else 2 if len(mats)>2 and j%3==2 and k%3==2 else 0
            ids += [color % len(mats), color % len(mats)]
    f.append(tuple(reversed(range(n)))); ids.append(0)
    tip=len(v);v.append((0,0,profile[-1][0]))
    for j in range(n):
        f.append(((len(rings)-1)*n+j,(len(rings)-1)*n+(j+1)%n,tip));ids.append(j%len(mats))
    return mesh(root.name+'_Shell',v,f,mats,ids,root)

def tube(name, points, radii, mats, root, sides=6):
    points=[Vector(p) for p in points]; v=[]; f=[]; ids=[]
    for k,p in enumerate(points):
        d=points[min(k+1,len(points)-1)]-points[max(0,k-1)]
        d.normalize()
        helper=Vector((0,0,1)) if abs(d.z)<.9 else Vector((-p.y,p.x,0)).normalized()
        u=d.cross(helper).normalized(); w=d.cross(u).normalized()
        for j in range(sides):
            v.append(p+radii[k]*(u*math.cos(TAU*j/sides)+w*math.sin(TAU*j/sides)))
    for k in range(len(points)-1):
        for j in range(sides):
            f.append((k*sides+j,k*sides+(j+1)%sides,(k+1)*sides+(j+1)%sides,(k+1)*sides+j));ids.append(j%len(mats))
    f.append(tuple(reversed(range(sides))));ids.append(0)
    f.append(tuple((len(points)-1)*sides+j for j in range(sides)));ids.append(0)
    return mesh(name,v,f,mats,ids,root)

def ribbon(name, pts, widths, mats, root, depth=.055):
    pts=[Vector(p) for p in pts]; v=[]; f=[]; ids=[]
    for k,p in enumerate(pts):
        t=(pts[min(k+1,len(pts)-1)]-pts[max(k-1,0)]).normalized()
        n=Vector((p.x,p.y,0)).normalized(); side=t.cross(n).normalized()
        for s,h in [(-1,0),(0,depth),(1,0),(1,-depth),(-1,-depth)]:
            v.append(p+side*s*widths[k]/2+n*h)
    for k in range(len(pts)-1):
        for j in range(5):
            f.append((k*5+j,k*5+(j+1)%5,(k+1)*5+(j+1)%5,(k+1)*5+j));ids.append(1 if j==1 and len(mats)>1 else 0)
    f.extend([tuple(reversed(range(5))),tuple((len(pts)-1)*5+j for j in range(5))]);ids += [0,0]
    return mesh(name,v,f,mats,ids,root)

def patch(name, coords, theta, z, half_angle, half_height, offset, ridge, mats, root):
    # Closed, raised faceted plate following the egg instead of a flat floating badge.
    ring=[point(z+y*half_height,theta+x*half_angle,offset) for x,y in coords]
    v=ring+[point(z,theta,offset+ridge)]+[point(z+y*half_height,theta+x*half_angle,offset-.065) for x,y in coords]
    n=len(ring);f=[];ids=[]
    for j in range(n):
        f.append((j,(j+1)%n,n));ids.append(1 if len(mats)>1 and j in (1,2,3) else 0)
        f.append((j,n+1+j,n+1+(j+1)%n,(j+1)%n));ids.append(len(mats)-1)
    f.append(tuple(reversed([n+1+j for j in range(n)])));ids.append(0)
    return mesh(name,v,f,mats,ids,root)

SCALE=[(-.68,.7),(0,1),(.68,.7),(1,.12),(.65,-.45),(0,-1),(-.65,-.45),(-1,.12)]
DIAMOND=[(0,1),(1,0),(0,-1),(-1,0)]
HEX=[(-.55,1),(.55,1),(1,.3),(1,-.3),(.55,-1),(-.55,-1),(-1,-.3),(-1,.3)]

# 01 / Common / reference 3 -- three symmetric spiralling fronds.
kelp=newroot('01_Common_Kelp',-11.6,'Common',3,3)
core(kelp,[TEAL,TEAL_L,TEAL_D])
for k in range(3):
    a=TAU*k/3
    pts=[point(.22+4.13*j/42,a+1.75*j/42,.035) for j in range(43)]
    ribbon('Kelp_Stem_%02d'%k,pts,[.20+.18*math.sin(math.pi*j/42) for j in range(43)],[OLIVE,OLIVE_L],kelp,.055)
    for j in range(4):
        z=.48+j*.88; theta=a+1.75*(z-.22)/4.13
        # Broad, long folded kelp blades sweep around the egg with the current.
        pts=[point(z+1.02*t,theta+.59*t+.12*math.sin(math.pi*t),.10+.06*math.sin(math.pi*t)) for t in [i/10 for i in range(11)]]
        widths=[.025+.70*math.sin(math.pi*i/10)**.65 for i in range(11)]
        ribbon('Kelp_BroadBlade_%d_%d'%(k,j),pts,widths,[LEAF,LEAF_L],kelp,.075)
for j in range(3):
    zs=[.04,.11,.22,.34,.43]
    a=TAU*j/3
    patch('Kelp_SandCuff_%d'%j,[(-1,-1),(1,-1),(1,.65),(.4,1.25),(-.5,.85),(-1,.4)],a,.19,math.pi/3,.18,.035,.055,[SAND,SAND_L],kelp)

# 02 / Uncommon / reference 10 -- overlapping scales, six crown horns, six core gems.
lev=newroot('02_Uncommon_Leviathan',-5.8,'Uncommon',10,6)
core(lev,[ARMOR,ARMOR_D,ARMOR_L])
for row,z in enumerate((.88,1.8,2.7,3.5)):
    for j in range(6):
        a=TAU*j/6+(math.pi/6 if row%2 else 0)
        patch('Leviathan_Scale_%d_%d'%(row,j),SCALE,a,z,.41,.56,.055,.18,[GOLD,GOLD_L,GOLD_D] if row in (1,3) else [ARMOR,ARMOR_L,GOLD_D],lev)
for j in range(6):
    a=TAU*j/6
    patch('Leviathan_GemFrame_%d'%j,DIAMOND,a,2.65,.20,.61,.27,.055,[GOLD,GOLD_L],lev)
    patch('Leviathan_Gem_%d'%j,DIAMOND,a,2.65,.145,.49,.34,.14,[GEM,GEM_L,GEM_D],lev)
    points=[]
    for r,z in ((.8,3.93),(1.10,4.10),(1.28,4.34),(1.27,4.65),(1.13,4.98)):
        points.append((r*math.cos(a),r*math.sin(a),z))
    tube('Leviathan_IvoryHorn_%d'%j,points,[.22,.23,.18,.10,.009],[IVORY,IVORY_D],lev,5)
    tube('Leviathan_HornSocket_%d'%j,points[:2],[.26,.25],[GOLD,GOLD_L],lev,6)

# 03 / Rare / reference 4 -- gold cage, closed rivets, faceted gems and hollow barnacles.
treasure=newroot('03_Rare_Treasure',0,'Rare',4,6)
core(treasure,[NAVY,NAVY_L,NAVY_D])
for j in range(6):
    a=TAU*j/6
    zs=[.12+4.38*k/34 for k in range(35)]
    ribbon('Treasure_GoldMeridian_%d'%j,[point(z,a,.045) for z in zs],[.16 for z in zs],[GOLD,GOLD_L],treasure,.09)
for i,z in enumerate((.68,2.28,3.75)):
    pts=[point(z,TAU*j/96,.055) for j in range(97)]
    ribbon('Treasure_GoldHoop_%d'%i,pts,[.17 for p in pts],[GOLD,GOLD_L],treasure,.09)
for j in range(6):
    a=TAU*j/6
    patch('Treasure_GemBezel_%d'%j,HEX,a,2.28,.29,.45,.15,.06,[GOLD,GOLD_L,GOLD_D],treasure)
    patch('Treasure_AquaGem_%d'%j,HEX,a,2.28,.215,.335,.24,.16,[GEM,GEM_L,GEM_D],treasure)
    for i,z in enumerate((.68,1.30,3.12,3.75)):
        p=point(z,a,.17); n=Vector((math.cos(a),math.sin(a),.2)).normalized()
        tube('Treasure_Rivet_%d_%d'%(j,i),[p-n*.015,p+n*.055],[.057,.052],[GOLD_L,GOLD],treasure,8)

def barnacle(name,z,a,size):
    p=point(z,a,.025); n=Vector((math.cos(a),math.sin(a),.25)).normalized()
    u=Vector((-math.sin(a),math.cos(a),0));v=n.cross(u)
    verts=[]
    # outer base -> outer lip -> inner lip -> dark inner bowl; closed bottom.
    for r,d in ((size,0),(size*.84,size*.64),(size*.5,size*.65),(size*.45,size*.13)):
        for j in range(7):
            verts.append(p+n*d+u*r*math.cos(TAU*j/7)+v*r*math.sin(TAU*j/7))
    f=[];ids=[]
    for row in range(3):
        for j in range(7):f.append((row*7+j,row*7+(j+1)%7,(row+1)*7+(j+1)%7,(row+1)*7+j));ids.append((0,1,2)[row])
    f += [tuple(reversed(range(7))),tuple(21+j for j in range(7))];ids += [0,2]
    mesh(name,verts,f,[SHELL,SHELL_L,SHELL_D],ids,treasure)
for j in range(6):
    a=TAU*(j+.5)/6
    for i,(z,da,s) in enumerate(((3.20,0,.24),(3.47,.11,.19),(3.03,.15,.15))):
        barnacle('Treasure_Barnacle_%d_%d'%(j,i),z,a+da,s)

# 04 / Epic / reference 8 -- six repeated armored sectors and cyan cuts.
abyss=newroot('04_Epic_Abyss',5.8,'Epic',8,6)
core(abyss,[INDIGO,INDIGO_D,INDIGO_L])
for j in range(6):
    a=TAU*j/6
    for row,z in enumerate((1.0,2.18,3.38)):
        patch('Abyss_CyanInset_%d_%d'%(j,row),SCALE,a,z,.405,.72,.035,.045,[CYAN,CYAN_SOFT],abyss)
        patch('Abyss_ArmoredPlate_%d_%d'%(j,row),SCALE,a,z+.065,.35,.65,.11,.22,[INDIGO_L,INDIGO,INDIGO_EDGE,INDIGO_D],abyss)
    # An elongated diamond in the central armor field, repeated on the back.
    patch('Abyss_GemFrame_%d'%j,DIAMOND,a,2.42,.15,.45,.34,.05,[INDIGO_D,INDIGO_EDGE],abyss)
    patch('Abyss_CoreDiamond_%d'%j,DIAMOND,a,2.42,.095,.31,.40,.16,[CYAN,GEM_L,GEM_D],abyss)
    for row,z in enumerate((1.05,2.38,3.58)):
        b=a+math.pi/6
        coords=[(-.11,-.25),(.02,1),(.13,.17)]
        patch('Abyss_Fin_%d_%d'%(j,row),coords,b,z,.65,.57,.03,.42,[INDIGO_L,CYAN_SOFT,INDIGO],abyss)

# 05 / Legendary / reference 6 -- translucent complete egg, 12 flowing ribbons.
jelly=newroot('05_Legendary_Jelly',11.6,'Legendary',6,6)
core(jelly,[JELLY,JELLY_L,JELLY_D],36)
inner_profile=[(1.0,.12),(1.13,.5),(1.5,.85),(2.05,1.0),(2.55,.85),(3.0,.55),(3.25,0)]
core_ob=core(jelly,[JELLY_CORE,JELLY_L],36,inner_profile)
core_ob.name='Jelly_InnerLuminousPearl'
for row,z0 in enumerate((1.25,2.25,3.18)):
    points=[]
    for j in range(97):
        a=TAU*j/96; z=z0+.11*math.cos(6*a)
        points.append(point(z,a,.045))
    ribbon('Jelly_CyanWave_%d'%row,points,[.13 if row<2 else .11 for p in points],[CYAN,GEM_L],jelly,.045)
for j in range(12):
    a=TAU*j/12;pts=[]
    for k in range(21):
        t=k/20
        r=1.57+.40*math.sin(math.pi*t)+.08*math.sin(TAU*t)
        theta=a+.13*math.sin(math.pi*t)
        z=1.55-1.47*t+.16*math.sin(TAU*t)
        pts.append(Vector((r*math.cos(theta),r*math.sin(theta),z)))
    widths=[.32*(1-.68*(k/20)**2) for k in range(21)]
    ribbon('Jelly_TranslucentTendril_%02d'%j,pts,widths,[JELLY_L,JELLY_TIP],jelly,.045)
    if j%2==0:
        tube('Jelly_TendrilLight_%02d'%j,[p+Vector((math.cos(a),math.sin(a),0))*.05 for p in pts],[.018*(1-.65*k/20) for k in range(21)],[CYAN_SOFT],jelly,5)

# Underside construction seals are actual concentric geometry on every egg.
for root,mats in ((lev,[GOLD,GOLD_L,GOLD_D]),(abyss,[INDIGO_L,INDIGO_EDGE,CYAN_SOFT])):
    for j in range(6):
        a=TAU*j/6
        if root==abyss:
            patch('Abyss_LowerLight_%d'%j,SCALE,a,.42,.43,.40,.04,.04,[CYAN,CYAN_SOFT],root)
        patch(root.name+'_LowerScale_%d'%j,SCALE,a,.46,.36,.40,.10,.10,mats,root)
        # Radial spokes climb from the base seal into the lower armor row.
        zs=[.035+.46*k/8 for k in range(9)]
        ribbon(root.name+'_BasalRib_%d'%j,[point(z,a,.03) for z in zs],[.11 for z in zs],[GOLD,GOLD_L] if root==lev else [CYAN,CYAN_SOFT],root,.035)
for root in ROOTS:
    mats=[TEAL_D,SAND] if root==kelp else [ARMOR_D,GOLD] if root==lev else [NAVY_D,GOLD] if root==treasure else [INDIGO_D,CYAN_SOFT] if root==abyss else [JELLY_D,JELLY_TIP]
    for i in range(2):
        r=.24+i*.14
        tube(root.name+'_UndersideRing_%d'%i,[(r*math.cos(TAU*j/36),r*math.sin(TAU*j/36),.018) for j in range(37)],[.025]*37,[mats[i]],root,5)

# Inspection scene is deliberately separate from the exported assets.
floor=mesh('Preview_Ground',[(-80,-80,-.06),(80,-80,-.06),(80,80,-.06),(-80,80,-.06)],[(0,1,2,3)],[mat('PreviewGround','#CDD7E5',0,.85)],collection=STAGE)
def aim(ob,target):
    ob.rotation_euler=(Vector(target)-ob.location).to_track_quat('-Z','Y').to_euler()
camdata=bpy.data.cameras.new('PreviewCamera');cam=bpy.data.objects.new('PreviewCamera',camdata);STAGE.objects.link(cam)
cam.location=(1,-38,13.0);aim(cam,(0,0,2.4));camdata.type='ORTHO';camdata.ortho_scale=30.4;SCENE.camera=cam
for name,pos,power,size,color in [('Key',(-9,-12,17),2500,12,(.84,.91,1)),('Fill',(12,-6,10),1800,10,(.82,1,1)),('Rim',(0,7,13),3400,12,(1,.85,.72))]:
    d=bpy.data.lights.new('Preview_'+name,'AREA');d.energy=power;d.shape='DISK';d.size=size;d.color=color
    o=bpy.data.objects.new('Preview_'+name,d);STAGE.objects.link(o);o.location=pos;aim(o,(0,0,2))
world=bpy.data.worlds.new('OceanEggs_StudioWorld');world.use_nodes=True
world.node_tree.nodes['Background'].inputs['Color'].default_value=(.32,.39,.52,1)
world.node_tree.nodes['Background'].inputs['Strength'].default_value=.55;SCENE.world=world
SCENE.render.engine='CYCLES';SCENE.cycles.samples=32;SCENE.cycles.use_denoising=True
SCENE.render.resolution_x=2000;SCENE.render.resolution_y=650;SCENE.render.resolution_percentage=100
SCENE.render.image_settings.file_format='PNG';SCENE.render.film_transparent=False
SCENE.view_settings.view_transform='AgX'
SCENE.render.filepath=str(WORK/'lineup-front.png')
SCENE['order']='3 Kelp / 10 Leviathan / 4 Treasure / 8 Abyss / 6 Jelly'
SCENE['review_status']='Awaiting user visual review; Blender only'
for area in bpy.context.screen.areas if bpy.context.screen else []:
    if area.type=='VIEW_3D':
        space=area.spaces.active
        space.shading.type='MATERIAL'
        space.overlay.show_overlays=False
        space.region_3d.view_perspective='CAMERA'
        space.region_3d.view_camera_zoom=23
for ob in bpy.context.selected_objects:ob.select_set(False)
bpy.context.view_layer.objects.active=None
bpy.context.view_layer.update()
stats={}
for root in ROOTS:
    items=PARTS[root.name];tris=0;deg=0;nonman=0
    for ob in items:
        ob.data.calc_loop_triangles();tris+=len(ob.data.loop_triangles)
        deg+=sum(p.area<1e-9 for p in ob.data.polygons)
        bm=bmesh.new();bm.from_mesh(ob.data);nonman+=sum(not e.is_manifold for e in bm.edges);bm.free()
    coords=[ob.matrix_world@v.co for ob in items for v in ob.data.vertices]
    dims=[max(v[k] for v in coords)-min(v[k] for v in coords) for k in range(3)]
    stats[root.name]={'parts':len(items),'triangles':tris,'degenerate_faces':deg,'nonmanifold_edges':nonman,'dimensions':dims,'symmetry':root['rotational_symmetry']}
(WORK/'validation.json').write_text(json.dumps(stats,indent=2),encoding='utf-8')
bpy.ops.wm.save_as_mainfile(filepath=str(WORK/'ocean-eggs-presentation.blend'))
result={'scene':SCENE.name,'stats':stats,'file':str(WORK/'ocean-eggs-presentation.blend')}
