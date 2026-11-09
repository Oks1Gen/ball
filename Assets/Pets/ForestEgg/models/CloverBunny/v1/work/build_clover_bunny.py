"""Non-destructive Clover Bunny authoring in the connected Blender session."""
import bpy, math, json, os, struct, zlib, hashlib
from pathlib import Path
from mathutils import Vector

BASE = Path('C:/Users/dakem/Documents/RobloxGames/ball/Assets/Pets/ForestEgg/models/CloverBunny/v1')
MODEL = BASE / 'model'
WORK = BASE / 'work'
for p in (MODEL, WORK, WORK / 'textures'):
    p.mkdir(parents=True, exist_ok=True)
assert not bpy.data.collections.get('CloverBunny_Asset'), 'Asset already exists: inspect rather than duplicate.'
assert bpy.context.mode == 'OBJECT', 'Authoring requires Object mode.'
original = bpy.context.scene
original_state = {o.name: {'type': o.type, 'matrix': [list(r) for r in o.matrix_world]} for o in original.objects}
(WORK / 'original-scene.json').write_text(json.dumps(original_state, indent=2), encoding='utf-8')
bpy.ops.wm.save_as_mainfile(filepath=str(WORK / 'blender-before-clover.blend'), copy=True)

scene = bpy.data.scenes.new('CloverBunny')
scene.unit_settings.system = 'NONE'
scene['AssetBrief'] = 'Forest Egg Clover Bunny; front -Y, +Z up, root at ground; static segmented pet.'
asset = bpy.data.collections.new('CloverBunny_Asset')
scene.collection.children.link(asset)
original.collection.children.link(asset)
bpy.context.window.scene = scene
bpy.context.view_layer.active_layer_collection = bpy.context.view_layer.layer_collection.children[asset.name]
root = bpy.data.objects.new('CloverBunny', None)
asset.objects.link(root)
root.empty_display_type = 'PLAIN_AXES'
root.empty_display_size = .35
root['PetName'] = 'Clover Bunny'
root['EggTheme'] = 'Forest'
root['Reference'] = 'Assets/Pets/ForestEgg/concepts-v4/forest-egg-five-pets-v4.png'
root['FrontAxis'] = '-Y'
root['ScaleBrief'] = '2-unit cube body; actual Studio size to be verified on import.'

def lin(v):
    return v / 12.92 if v <= .04045 else ((v + .055) / 1.055) ** 2.4

def rgba(h):
    h = h.lstrip('#')
    return tuple(lin(int(h[i:i+2],16)/255) for i in (0,2,4)) + (1,)

palette = {'Cream':'F5DDBB','Pink':'F18DA2','Nose':'EF8D9D','Mouth':'754D35',
           'Clover':'72B62E','CloverStem':'4E922A','EyeWhite':'FFFCED','Glint':'FFFFFF'}
materials = {}
for name, color in palette.items():
    m = bpy.data.materials.new('CB_' + name)
    m.use_nodes = True
    p = next(n for n in m.node_tree.nodes if n.type == 'BSDF_PRINCIPLED')
    p.inputs['Base Color'].default_value = rgba(color)
    p.inputs['Roughness'].default_value = .38 if name not in ('Glint','EyeWhite') else .22
    p.inputs['Metallic'].default_value = 0
    p.inputs['Coat Weight'].default_value = .12
    m.diffuse_color = rgba(color)
    m['SourceSRGB'] = '#' + color
    materials[name] = m

def own(obj, name, mat=None):
    obj.name = 'CB_' + name
    for c in list(obj.users_collection):
        if c != asset:
            c.objects.unlink(obj)
    if asset not in obj.users_collection:
        asset.objects.link(obj)
    obj.parent = root
    if mat:
        obj.data.materials.append(materials[mat] if isinstance(mat,str) else mat)
    if obj.type == 'MESH':
        for poly in obj.data.polygons:
            poly.use_smooth = True
    return obj

def rounded_box(name, loc, dims, radius, mat='Cream', segments=5):
    bpy.ops.mesh.primitive_cube_add(size=1, location=loc)
    obj = own(bpy.context.object, name, mat)
    obj.dimensions = dims
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    bevel = obj.modifiers.new('Soft editable corners', 'BEVEL')
    bevel.width = radius
    bevel.segments = segments
    bevel.affect = 'EDGES'
    bevel.harden_normals = True
    normals = obj.modifiers.new('Broad flat face normals', 'WEIGHTED_NORMAL')
    normals.keep_sharp = True
    normals.weight = 50
    return obj

def ellipsoid(name, loc, scale, mat='Cream', segments=24, rings=12):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=segments, ring_count=rings, radius=1, location=loc)
    obj = own(bpy.context.object, name, mat)
    obj.scale = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    return obj

body = rounded_box('Body', (0,0,1.24), (2,2,2), .205, segments=6)
body['PartRole'] = 'Single square combined head/body; flat planes, rounded corners.'
for x, side in ((-.61,'L'),(.61,'R')):
    for y, end in ((-.58,'Front'),(.58,'Rear')):
        rounded_box('Foot_' + side + '_' + end, (x,y,.17), (.48,.53,.34), .145, segments=4)
ellipsoid('Tail', (0,1.065,.81), (.30,.28,.30), segments=24, rings=12)
ellipsoid('Tail_Lobe_L', (-.17,1.12,.82), (.15,.19,.18), segments=16, rings=8)
ellipsoid('Tail_Lobe_R', (.15,1.12,.88), (.16,.18,.18), segments=16, rings=8)

def catmull(points, t):
    n = len(points)-1
    u = min(t*n, n-.000001)
    k = int(u)
    f = u-k
    a,b,c,d = [Vector(points[max(0,min(len(points)-1,j))]) for j in (k-1,k,k+1,k+2)]
    return .5*((2*b)+(-a+c)*f+(2*a-5*b+4*c-d)*f*f+(-a+3*b-3*c+d)*f*f*f)

def ear_frame(points, t):
    c = catmull(points,t)
    tangent = (catmull(points,min(.999999,t+.002))-catmull(points,max(0,t-.002))).normalized()
    side = tangent.cross(Vector((0,-1,0))).normalized()
    front = side.cross(tangent).normalized()
    return c, side, front

def ear(name, points, width):
    steps, radial = 28, 16
    verts, faces = [], []
    for i in range(steps+1):
        t = i/steps
        c,s,f = ear_frame(points,t)
        shape = max(.035, math.sin(math.pi*t)**.43)
        for j in range(radial):
            a = 2*math.pi*j/radial
            verts.append(c+s*(width*shape*math.cos(a))+f*(.128*shape*math.sin(a)))
    for i in range(steps):
        for j in range(radial):
            a=i*radial+j; b=i*radial+(j+1)%radial
            faces.append((a,a+radial,b+radial,b))
    faces.extend([tuple(range(radial)), tuple(reversed([steps*radial+j for j in range(radial)]))])
    mesh=bpy.data.meshes.new('CB_'+name+'_Mesh'); mesh.from_pydata(verts,[],faces); mesh.update()
    obj=bpy.data.objects.new('CB_'+name,mesh); asset.objects.link(obj); own(obj,name,'Cream')
    # A shallow, continuous pink inlay follows the actual bent ear surface.
    pv,pf=[],[]
    long_n, across=22,8
    for i in range(long_n+1):
        v=i/long_n; t=.135+.735*v
        c,s,f=ear_frame(points,t)
        outer=max(.035,math.sin(math.pi*t)**.43)
        inner=width*outer*.67*max(.035,math.sin(math.pi*v)**.40)
        for j in range(across+1):
            u=(j/across*2-1)*inner
            depth=.128*outer*math.sqrt(max(.01,1-(u/(width*outer))**2))+.003
            pv.append(c+s*u+f*depth)
    for i in range(long_n):
        for j in range(across):
            a=i*(across+1)+j
            pf.append((a,a+1,a+across+2,a+across+1))
    pm=bpy.data.meshes.new('CB_'+name+'_PinkMesh');pm.from_pydata(pv,[],pf);pm.update()
    po=bpy.data.objects.new('CB_'+name+'_Pink',pm);asset.objects.link(po);own(po,name+'_Pink','Pink')
    thick=po.modifiers.new('Thin pink inlay', 'SOLIDIFY');thick.thickness=.004
    return obj

ear('Ear_Upright', [(-.51,.04,2.16),(-.60,.035,2.53),(-.77,.025,3.02),(-.88,.01,3.48),(-.85,0,3.66)], .268)
ear('Ear_Folded',[(.42,.07,2.15),(.53,.065,2.50),(.66,.015,2.88),(.82,-.09,3.16),(1.08,-.28,3.21),(1.22,-.40,3.08)], .29)

def png_rgba(path, size, pixel):
    rows=[]
    for y in range(size):
        row=bytearray([0])
        for x in range(size):
            row.extend(pixel((x+.5)/size,1-(y+.5)/size))
        rows.append(bytes(row))
    def chunk(k,data):
        return struct.pack('>I',len(data))+k+data+struct.pack('>I',zlib.crc32(k+data)&0xffffffff)
    path.write_bytes(b'\x89PNG\r\n\x1a\n'+chunk(b'IHDR',struct.pack('>IIBBBBB',size,size,8,6,0,0,0))+chunk(b'IDAT',zlib.compress(b''.join(rows),9))+chunk(b'IEND',b''))

def iris_pixel(u,v):
    x,y=(u-.5)*2,(v-.5)*2
    rr=math.sqrt(x*x+y*y)
    t=max(0,min(1,(y+1)/2))
    low=(153,217,62); high=(20,80,25)
    color=[low[k]*(1-t)+high[k]*t for k in range(3)]
    radial=.91+.09*math.cos(math.atan2(y,x)*17)*(min(1,rr)**.5)
    edge=1-.48*max(0,min(1,(rr-.82)/.18))
    color=[c*radial*edge for c in color]
    pupil=((x+.035)/.64)**2+((y-.105)/.72)**2
    a=max(0,min(1,(1.03-pupil)/.075))
    dark=(6,28,13)
    return tuple(int(max(0,min(255,color[k]*(1-a)+dark[k]*a))) for k in range(3))+(255,)

def blush_pixel(u,v):
    r=((u-.5)*2)**2+((v-.5)*2)**2
    return (245,122,144,int(135*max(0,1-r)**2))

png_rgba(WORK/'textures/iris-green.png',256,iris_pixel)
png_rgba(WORK/'textures/blush.png',128,blush_pixel)

def image_mat(name,path,roughness,alpha=False):
    image=bpy.data.images.load(str(path),check_existing=False)
    image.colorspace_settings.name='sRGB';image.pack()
    mat=bpy.data.materials.new('CB_'+name);mat.use_nodes=True
    nt=mat.node_tree;bs=next(n for n in nt.nodes if n.type=='BSDF_PRINCIPLED')
    tex=nt.nodes.new('ShaderNodeTexImage');tex.image=image
    nt.links.new(tex.outputs['Color'],bs.inputs['Base Color'])
    bs.inputs['Roughness'].default_value=roughness
    bs.inputs['Coat Weight'].default_value=.25 if not alpha else 0
    if alpha:
        nt.links.new(tex.outputs['Alpha'],bs.inputs['Alpha'])
        mat.surface_render_method='DITHERED'
    return mat

iris_mat=image_mat('Iris_Green',WORK/'textures/iris-green.png',.22)
blush_mat=image_mat('Blush_Soft',WORK/'textures/blush.png',.7,True)

def face_disc(name,cx,cz,rx,rz,mat,base_y,bulge=0,rings=5,segments=40):
    verts=[(cx,base_y-bulge,cz)];uvs=[(.5,.5)]
    for i in range(1,rings+1):
        r=i/rings
        for j in range(segments):
            a=2*math.pi*j/segments;x=r*math.cos(a);z=r*math.sin(a)
            verts.append((cx+rx*x,base_y-bulge*math.sqrt(max(0,1-r*r)),cz+rz*z));uvs.append((x*.5+.5,z*.5+.5))
    faces=[]
    for j in range(segments):faces.append((0,1+j,1+(j+1)%segments))
    for i in range(1,rings):
        a=1+(i-1)*segments;b=1+i*segments
        for j in range(segments):faces.append((a+j,b+j,b+(j+1)%segments,a+(j+1)%segments))
    mesh=bpy.data.meshes.new('CB_'+name+'_Mesh');mesh.from_pydata(verts,[],faces);mesh.update()
    uv=mesh.uv_layers.new(name='UVMap')
    for poly in mesh.polygons:
        for li in poly.loop_indices:uv.data[li].uv=uvs[mesh.loops[li].vertex_index]
    obj=bpy.data.objects.new('CB_'+name,mesh);asset.objects.link(obj);own(obj,name,mat)
    return obj

for x,side in ((-.44,'L'),(.44,'R')):
    ellipsoid('EyeWhite_'+side,(x,-1.019,1.13),(.302,.057,.348),'EyeWhite',32,16)
    face_disc('Iris_'+side,x+.008,1.105,.258,.297,iris_mat,-1.067,.025)
    ellipsoid('Catchlight_Main_'+side,(x-.089,-1.102,1.281),(.071,.017,.080),'Glint',16,8)
    ellipsoid('Catchlight_Small_'+side,(x+.104,-1.100,1.014),(.028,.011,.032),'Glint',12,6)
for x,side in ((-.68,'L'),(.68,'R')):
    face_disc('Blush_'+side,x,.79,.173,.128,blush_mat,-1.004,.001,3,32)

nose=ellipsoid('Nose',(0,-1.038,.842),(.103,.044,.063),'Nose',24,12)
def line(name,coords,width,mat):
    curve=bpy.data.curves.new('CB_'+name+'_Curve','CURVE');curve.dimensions='3D'
    curve.resolution_u=8;curve.bevel_depth=width;curve.bevel_resolution=3;curve.use_fill_caps=True
    spl=curve.splines.new('BEZIER');spl.bezier_points.add(len(coords)-1)
    for p,co in zip(spl.bezier_points,coords):p.co=co;p.handle_left_type='AUTO';p.handle_right_type='AUTO'
    ob=bpy.data.objects.new('CB_'+name,curve);asset.objects.link(ob);own(ob,name,mat)
    return ob
line('Mouth_Center',[(0,-1.013,.793),(0,-1.014,.747)],.014,'Mouth')
line('Smile_Left',[(0,-1.014,.752),(-.054,-1.015,.699),(-.119,-1.014,.706),(-.153,-1.012,.753)],.014,'Mouth')
line('Smile_Right',[(0,-1.014,.752),(.054,-1.015,.699),(.119,-1.014,.706),(.153,-1.012,.753)],.014,'Mouth')

# A small clover tuft, the only accessory retained in the approved reference.
line('Clover_Stem',[(-.03,-.51,2.247),(-.025,-.565,2.318)],.022,'CloverStem')
for name,loc,scale in [
    ('Top',(-.03,-.57,2.407),(.083,.040,.103)),
    ('Left',(-.119,-.585,2.341),(.097,.043,.077)),
    ('Right',(.055,-.585,2.341),(.097,.043,.077)),
    ('Bottom',(-.03,-.601,2.282),(.078,.039,.087))]:
    ellipsoid('Clover_'+name,loc,scale,'Clover',16,8)

bpy.context.view_layer.update()
for obj in asset.objects:
    if obj.type in ('MESH','CURVE'):
        obj['AssetOwner']='CloverBunny'
        obj['Purpose']=obj.name.removeprefix('CB_')

preview=bpy.data.scenes.new('CB_Preview')
preview.collection.children.link(asset)
helpers=bpy.data.collections.new('CB_PreviewOnly');preview.collection.children.link(helpers)
bpy.context.window.scene=preview
bpy.context.view_layer.active_layer_collection=bpy.context.view_layer.layer_collection.children[helpers.name]
world=bpy.data.worlds.new('CB_Preview_World');world.use_nodes=True
world.node_tree.nodes.get('Background').inputs['Color'].default_value=(.78,.84,.89,1)
world.node_tree.nodes.get('Background').inputs['Strength'].default_value=.32
preview.world=world
preview.render.engine='CYCLES';preview.cycles.samples=32
preview.cycles.use_denoising=True
preview.render.resolution_x=800;preview.render.resolution_y=800;preview.render.resolution_percentage=100
preview.render.image_settings.file_format='PNG'
preview.view_settings.view_transform='Standard'
preview.view_settings.look='None';preview.view_settings.exposure=0;preview.view_settings.gamma=1
floor_mat=bpy.data.materials.new('CB_Preview_Floor');floor_mat.diffuse_color=rgba('E7E9D8')
floor_mat.use_nodes=True
next(n for n in floor_mat.node_tree.nodes if n.type=='BSDF_PRINCIPLED').inputs['Base Color'].default_value=rgba('E7E9D8')
bpy.ops.mesh.primitive_plane_add(size=200,location=(0,0,-.005));floor=bpy.context.object;floor.name='CB_Preview_Ground';floor.data.materials.append(floor_mat)

def aim(obj,target):
    obj.rotation_euler=(Vector(target)-obj.location).to_track_quat('-Z','Y').to_euler()
for name,loc,power,size in [('Key',(-3.5,-4.5,7),650,5),('Fill',(4,-3,4.5),400,4),('Rim',(1,4,6),550,3.5)]:
    data=bpy.data.lights.new('CB_Preview_'+name,'AREA');data.energy=power;data.shape='DISK';data.size=size
    ob=bpy.data.objects.new('CB_Preview_'+name,data);helpers.objects.link(ob);ob.location=loc;aim(ob,(0,0,1.7))
cam_data=bpy.data.cameras.new('CB_Preview_Camera');cam=bpy.data.objects.new('CB_Preview_Camera',cam_data);helpers.objects.link(cam)
cam_data.type='ORTHO';cam_data.ortho_scale=4.8
cam.location=(5,-8,5.0);aim(cam,(0,0,1.78));preview.camera=cam
scene.world=world
scene.view_settings.view_transform='Standard';scene.view_settings.look='None'
bpy.context.window.scene=scene
for area in bpy.context.screen.areas:
    if area.type=='VIEW_3D':
        s=area.spaces.active;s.shading.type='MATERIAL'
        s.shading.studiolight_rotate_z=.35
        s.overlay.show_floor=False;s.overlay.show_axis_x=False;s.overlay.show_axis_y=False
        s.region_3d.view_distance=6.3
        s.region_3d.view_location=(0,0,1.8)
        s.region_3d.view_rotation=cam.rotation_euler.to_quaternion()
        s.region_3d.view_perspective='ORTHO'
bpy.ops.object.select_all(action='DESELECT')
body.select_set(True);bpy.context.view_layer.objects.active=body

stats={'scene':scene.name,'asset_collection':asset.name,'parts':len(asset.objects),'meshes':len([o for o in asset.objects if o.type=='MESH']), 'palette_srgb':palette,'reference':root['Reference'],'original_scene':original.name,'original_objects_preserved':all(o.name in original.objects for o in [bpy.data.objects[n] for n in original_state])}
(WORK/'build-summary.json').write_text(json.dumps(stats,indent=2),encoding='utf-8')
result=stats
