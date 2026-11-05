"""Selected concept 5: thick nautilus basin, paired volutes, continuous underside.
Run in the connected Blender. Creates an isolated scene; does not clear user data.
"""
import bpy, bmesh, math, json
from pathlib import Path
from mathutils import Vector

BASE = Path(__file__).resolve().parent.parent
WORK = BASE / 'work'
OUT = BASE / 'model'
WORK.mkdir(parents=True, exist_ok=True)
OUT.mkdir(parents=True, exist_ok=True)
SCENE = 'Nautilus Shell • Option 5'
assert SCENE not in bpy.data.scenes, 'Existing shell scene: inspect before rebuilding'
original = bpy.context.scene
original_objects = {o.name: [list(row) for row in o.matrix_world] for o in original.objects}
scene = bpy.data.scenes.new(SCENE)
bpy.context.window.scene = scene
scene.unit_settings.system = 'METRIC'
asset = bpy.data.collections.new('NautilusShell_Asset')
scene.collection.children.link(asset)
stage = bpy.data.collections.new('Presentation_NotExported')
scene.collection.children.link(stage)
root = bpy.data.objects.new('NautilusShell', None)
asset.objects.link(root)
root['concept'] = 5
root['purpose'] = 'Ocean Depths egg shell cradle'
root['symmetry'] = 'Mirrored side volutes; evenly spaced spiral bowl flutes'
root['asset_revision'] = 1
root['front'] = '-Y'

def linear(c):
    return c / 12.92 if c <= .04045 else ((c + .055) / 1.055) ** 2.4

def material(name, hexcode, roughness=.3, metallic=0):
    m = bpy.data.materials.new('Nautilus_' + name)
    rgb = tuple(linear(int(hexcode[i:i+2], 16)/255) for i in (0, 2, 4))
    m.diffuse_color = (*rgb, 1)
    m.use_nodes = True
    p = next(n for n in m.node_tree.nodes if n.type == 'BSDF_PRINCIPLED')
    p.inputs['Base Color'].default_value = (*rgb, 1)
    p.inputs['Roughness'].default_value = roughness
    p.inputs['Metallic'].default_value = metallic
    p.inputs['Coat Weight'].default_value = .24 if not metallic else .1
    p.inputs['Coat Roughness'].default_value = .2
    p.inputs['IOR'].default_value = 1.46
    return m

ivory = material('WarmIvory', 'FFF1DB')
pearl = material('PearlBlush', 'F2D9D4', .26)
cream = material('CreamFlutes', 'EBD2B7', .34)
mint = material('AquaInlay', '89DBD5', .25)
teal = material('TurquoiseTrim', '3DA7AF', .3, .12)
navy = material('BlueLimestone', '345679', .46)
blue = material('BlueFacet', '527B9C', .42)
dark = material('UndersideBlue', '29445F', .48)

def mesh(name, vertices, faces, mats, indices=None, smooth=False):
    me = bpy.data.meshes.new(name + '_Mesh')
    me.from_pydata(vertices, [], faces)
    me.update()
    bm = bmesh.new(); bm.from_mesh(me)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(me); bm.free()
    ob = bpy.data.objects.new(name, me)
    asset.objects.link(ob); ob.parent = root
    for m in mats: me.materials.append(m)
    for i, p in enumerate(me.polygons):
        p.material_index = indices[i] if indices else 0
        p.use_smooth = smooth
    return ob

# The inner and outer skins are joined around the lip, with closed bottom poles.
# Ribs are built into the shell, not floating independent decoration.
N = 96
RADII = [.075, .16, .28, .41, .54, .67, .79, .89, .96, 1.0]

def surface(u, a, outer=False):
    twist = 1.25 * (1-u)**1.15
    phase = 12 * (a - twist)
    scallop = 1 + .035 * math.cos(12*a)
    x = 2.92*u*math.cos(a)*scallop
    y = 2.20*u*math.sin(a)*scallop
    flute = .038 * u**.75 * math.cos(phase)
    z = .64 + 1.03*u*u + .19*u*u*math.sin(a) + flute
    if outer:
        z -= .19 + .03*u
    return (x, y, z)

verts=[]; faces=[]; ids=[]
for outer in (False, True):
    for u in RADII:
        verts.extend(surface(u, math.tau*j/N, outer) for j in range(N))
L=len(RADII)*N
for layer in range(2):
    for ring in range(len(RADII)-1):
        for j in range(N):
            a=layer*L+ring*N+j; b=layer*L+ring*N+(j+1)%N
            faces.append((a,b,b+N,a+N))
            if layer == 0:
                # Wide ivory nacre segments with blush in the flute valleys.
                ids.append(1)
            else:
                ids.append(0 if (j//4)%2 == 0 else 2)
for j in range(N):
    a=(len(RADII)-1)*N+j; b=(len(RADII)-1)*N+(j+1)%N
    faces.append((a,b,b+L,a+L)); ids.append(0)
for layer in range(2):
    center=len(verts); verts.append((0,0,.64-(.19 if layer else 0)))
    for j in range(N):
        faces.append((center,layer*L+j,layer*L+(j+1)%N)); ids.append(layer)
body=mesh('Shell_ContinuousThickBasin',verts,faces,[ivory,pearl,cream],ids,True)

def tube(name, points, radii, mat, sides=6, axis=(0,0,1), depth=1):
    points=[Vector(p) for p in points]
    closed=(points[0]-points[-1]).length<1e-5
    if closed: points=points[:-1];radii=radii[:-1]
    verts=[]; faces=[]
    guide=Vector(axis)
    for i,p in enumerate(points):
        tangent=(points[(i+1)%len(points)]-points[(i-1)%len(points)]).normalized() if closed else (points[min(i+1,len(points)-1)]-points[max(i-1,0)]).normalized()
        side=tangent.cross(guide).normalized()
        normal=side.cross(tangent).normalized()
        for k in range(sides):
            a=math.tau*k/sides
            v=p+radii[i]*(side*math.cos(a)+normal*math.sin(a)*depth)
            verts.append(tuple(v))
    for i in range(len(points) if closed else len(points)-1):
        for k in range(sides):
            faces.append((i*sides+k,i*sides+(k+1)%sides,((i+1)%len(points))*sides+(k+1)%sides,((i+1)%len(points))*sides+k))
    if not closed: faces.extend([tuple(reversed(range(sides))), tuple((len(points)-1)*sides+k for k in range(sides))])
    return mesh(name,verts,faces,[mat],smooth=True)

# One uninterrupted rolled shell lip, with a fine turquoise seam below it.
lip=[]
for j in range(N+1):
    x,y,z=surface(1,math.tau*j/N)
    lip.append((x,y,z+.015))
tube('Shell_RolledIvoryLip',lip,[.092]*len(lip),ivory,6)
seam=[(x*.999,y*.999,z-.082) for x,y,z in lip]
tube('Shell_ContinuousAquaLipSeam',seam,[.034]*len(seam),mint,4)

# The twelve ribs sweep into the same central spiral, repeated evenly all around.
for k in range(12):
    pts=[]; radii=[]
    for j in range(16):
        u=.13+.805*j/15
        a=math.tau*k/12+1.25*(1-u)**1.15
        x,y,z=surface(u,a)
        pts.append((x,y,z+.035))
        radii.append(.021+.025*math.sin(math.pi*j/15)**.65)
    tube(f'InnerSpiralRib_{k+1:02}',pts,radii,mint,4,depth=.4)
pts=[]; radii=[]
for j in range(48):
    t=j/47; r=.025+.43*t; a=math.tau*1.45*t
    pts.append((r*math.cos(a),r*.77*math.sin(a),.688+.045*t*t))
    radii.append(.016+.022*t)
tube('InnerNautilusHeart',pts,radii,mint,6,depth=.55)

# Mirrored solid volutes: large, readable curls, including front recessed inlays.
for sign,label in [(-1,'Left'),(1,'Right')]:
    path=[]; rad=[]
    for j in range(57):
        t=j/56; a=math.pi+math.tau*t; r=.85*(1-t)+.15*t
        path.append((sign*(2.75+r*math.cos(a)),-1.30-.025*math.sin(a),1.15+r*math.sin(a)))
        rad.append(.205-.085*t)
    tube('Volute_'+label+'_IvoryScroll',path,rad,ivory,10,axis=(0,1,0),depth=1.16)
    inset=[]
    for p,r in zip(path,rad): inset.append((p[0],p[1]-r*1.10,p[2]))
    tube('Volute_'+label+'_AquaInlay',inset,[r*.32 for r in rad],mint,6,axis=(0,1,0),depth=.4)

def plinth(name,rx,ry,z0,z1,matlist):
    # Bevelled octagonal footprint, a flat sole and full top; no unsupported corners.
    xy=[(-rx*.64,-ry), (rx*.64,-ry), (rx,-ry*.60), (rx,ry*.60),
        (rx*.64,ry),(-rx*.64,ry),(-rx,ry*.60),(-rx,-ry*.60)]
    verts=[]
    for z,s in [(z0,.94),(z0+.045,1),(z1-.04,1),(z1,.95)]:
        verts.extend((x*s,y*s,z) for x,y in xy)
    faces=[tuple(reversed(range(8)))]; idx=[0]
    for ring in range(3):
        for j in range(8):
            faces.append((ring*8+j,ring*8+(j+1)%8,(ring+1)*8+(j+1)%8,(ring+1)*8+j))
            idx.append(j%len(matlist) if ring==1 else 0)
    faces.append(tuple(24+j for j in range(8))); idx.append(0)
    return mesh(name,verts,faces,matlist,idx)
plinth('Base_OctagonalBlueStone',1.84,1.25,0,.28,[navy,blue])
plinth('Base_TurquoiseInsetBand',1.71,1.14,.275,.385,[teal,mint])
plinth('Base_UpperBlueCollar',1.58,1.03,.38,.46,[navy,blue])
# An underside inset and evenly repeated ribs keep the lower side finished.
plinth('Base_SoleInset',1.36,.88,.005,.07,[dark])

bpy.context.view_layer.update()
triangles=0
for ob in asset.objects:
    if ob.type=='MESH':
        ob.data.calc_loop_triangles(); triangles+=len(ob.data.loop_triangles)
        assert all(p.area>1e-10 for p in ob.data.polygons), ob.name
assert triangles<16000,triangles
root['triangles']=triangles

# Lighting is isolated from the asset and will never be included in exports.
world=bpy.data.worlds.new('Nautilus_StudioWorld'); scene.world=world; world.use_nodes=True
world.node_tree.nodes.get('Background').inputs[0].default_value=(.14,.20,.28,1)
world.node_tree.nodes.get('Background').inputs[1].default_value=.45
def stage_link(ob):
    for c in list(ob.users_collection):c.objects.unlink(ob)
    stage.objects.link(ob)
def light(name,pos,energy,size,color):
    d=bpy.data.lights.new(name,'AREA'); d.energy=energy; d.shape='DISK'; d.size=size; d.color=color
    ob=bpy.data.objects.new(name,d); stage.objects.link(ob); ob.location=pos
    ob.rotation_euler=(Vector((0,0,1))-ob.location).to_track_quat('-Z','Y').to_euler()
light('Shell_Key',(-4,-6,9),1050,6,(1,.88,.77))
light('Shell_Fill',(6,-2,5),650,5,(.72,.9,1))
light('Shell_Rim',(1,5,7),1100,5,(.83,.94,1))
bpy.ops.mesh.primitive_plane_add(size=200,location=(0,0,-.025))
floor=bpy.context.object; floor.name='Preview_Ground'; stage_link(floor)
ground=material('PreviewGround','A6BCCB',.65); floor.data.materials.append(ground)
camdata=bpy.data.cameras.new('Shell_ReviewCamera')
cam=bpy.data.objects.new('Shell_ReviewCamera',camdata); stage.objects.link(cam)
scene.camera=cam; cam.location=(8,-12,9)
cam.rotation_euler=(Vector((0,0,1))-cam.location).to_track_quat('-Z','Y').to_euler()
camdata.type='ORTHO'; camdata.ortho_scale=8.7; camdata.lens=50
scene.render.engine='CYCLES'; scene.cycles.samples=32
scene.render.resolution_x=1400; scene.render.resolution_y=1100;scene.render.resolution_percentage=100
scene.render.image_settings.file_format='PNG'
scene.view_settings.view_transform='AgX'
scene.render.filepath=str(WORK/'shell-front.png')
for ob in scene.objects:ob.select_set(False)
body.select_set(True);bpy.context.view_layer.objects.active=body
for area in bpy.context.screen.areas:
    if area.type=='VIEW_3D':
        sp=area.spaces.active
        sp.shading.type='MATERIAL';sp.overlay.show_overlays=False
        sp.region_3d.view_distance=10
        sp.region_3d.view_location=Vector((0,0,1))
        sp.region_3d.view_rotation=cam.rotation_euler.to_quaternion()
        sp.region_3d.view_perspective='PERSP'
assert all([[list(row) for row in original.objects[name].matrix_world]==matrix for name,matrix in original_objects.items()])
(WORK/'source-preservation.json').write_text(json.dumps({'source_scene':original.name,'objects_unchanged':len(original_objects),'triangles':triangles},indent=2),encoding='utf-8')
bpy.ops.wm.save_as_mainfile(filepath=str(WORK/'shell-authoring.blend'))
result={'scene':scene.name,'triangles':triangles,'meshes':sum(o.type=='MESH' for o in asset.objects),'source_objects_unchanged':len(original_objects)}
