"""Build, render and verify Acorn Squirrel with Blender --background."""
import bpy
import bmesh
import math
import json
import shutil
import struct
import zlib
from pathlib import Path
from mathutils import Vector

BASE = Path(__file__).resolve().parent.parent
WORK = BASE / 'work'
MODEL = BASE / 'model'
MODEL.mkdir(exist_ok=True)
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.context.preferences.filepaths.save_version = 0
scene = bpy.context.scene
scene.name = 'AcornSquirrel'
asset = bpy.data.collections.new('AcornSquirrel_Asset')
scene.collection.children.link(asset)
bpy.context.view_layer.active_layer_collection = bpy.context.view_layer.layer_collection.children[asset.name]
root = bpy.data.objects.new('AcornSquirrel', None)
asset.objects.link(root)
root['Front'] = '-Y'
root['Reference'] = 'Forest Egg v4 / Acorn Squirrel'

def rgb(hex_color):
    return tuple(int(hex_color[i:i+2], 16) for i in (0, 2, 4))

def linear(v):
    v /= 255
    return v / 12.92 if v <= .04045 else ((v + .055) / 1.055) ** 2.4

def material(name, hex_color, rough=.39):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    bsdf = m.node_tree.nodes.get('Principled BSDF')
    color = (*map(linear, rgb(hex_color)), 1)
    bsdf.inputs['Base Color'].default_value = color
    bsdf.inputs['Roughness'].default_value = rough
    m.diffuse_color = color
    m['sRGB'] = '#' + hex_color
    return m

def own(obj, name, mat):
    obj.name = name
    obj.parent = root
    obj.data.materials.append(mat)
    for f in obj.data.polygons:
        f.use_smooth = True
    return obj

def sphere(name, loc, scale, mat, segments=24, rings=12):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=segments, ring_count=rings, location=loc)
    o = own(bpy.context.object, name, mat)
    o.scale = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    return o

def box(name, loc, scale, radius, mat, segments=6, apply_bevel=False):
    bpy.ops.mesh.primitive_cube_add(size=1, location=loc)
    o = own(bpy.context.object, name, mat)
    o.scale = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    bevel = o.modifiers.new('Soft corners', 'BEVEL')
    bevel.width = radius
    bevel.segments = segments
    if apply_bevel:
        bpy.ops.object.modifier_apply(modifier=bevel.name)
    normal = o.modifiers.new('Flat face normals', 'WEIGHTED_NORMAL')
    normal.keep_sharp = True
    return o

def mesh_object(name, verts, faces, mat, uvs=None):
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata(verts, [], faces)
    mesh.update()
    if uvs:
        uv = mesh.uv_layers.new(name='UVMap')
        for loop in mesh.loops:
            uv.data[loop.index].uv = uvs[loop.vertex_index]
    obj = bpy.data.objects.new(name, mesh)
    asset.objects.link(obj)
    return own(obj, name, mat)

def texture(name, size, pixel, mat):
    rows = []
    for y in range(size):
        row = bytearray([0])
        for x in range(size):
            row.extend(pixel((x+.5)/size, 1-(y+.5)/size))
        rows.append(bytes(row))
    def chunk(tag, data):
        return struct.pack('>I',len(data)) + tag + data + struct.pack('>I',zlib.crc32(tag+data)&0xffffffff)
    path = WORK / (name + '.png')
    path.write_bytes(b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR',struct.pack('>IIBBBBB',size,size,8,2,0,0,0)) + chunk(b'IDAT',zlib.compress(b''.join(rows),9)) + chunk(b'IEND',b''))
    im = bpy.data.images.load(str(path))
    im.pack()
    tex = mat.node_tree.nodes.new('ShaderNodeTexImage')
    tex.image = im
    tex.extension = 'EXTEND'
    mat.node_tree.links.new(tex.outputs['Color'], mat.node_tree.nodes.get('Principled BSDF').inputs['Base Color'])

def smooth(t):
    t = max(0, min(1,t))
    return t*t*(3-2*t)

def mix(a,b,t):
    return tuple(int(a[i]+(b[i]-a[i])*t) for i in range(3))

caramel = material('Caramel', 'C77D43')
front = material('Caramel and cream face', 'C77D43')
tail = material('Acorn amber', 'BC7136')
cap = material('Acorn cocoa cap', '784530')
paws = material('Toasted paws', '9C572E')
cream = material('Warm ear cream', 'F6C794')
dark = material('Nose and smile', '62351E')
white = material('Eye white', 'FFF6E7', .30)
glint = material('Eye catchlight', 'FFFFFF', .24)
iris = material('Amber iris', 'BA6816', .28)

def face_pixel(u,v):
    x, z = 2*u-1, 2*v+.24
    # Broad, low cream muzzle with a shallow dip below the nose.
    top = 1.11 + .12 * math.exp(-((abs(x)-.46)/.29)**2)
    mid, ry = (top+.43)/2, (top-.43)/2
    edge = 1 - ((abs(x)/.88)**3.35 + (abs(z-mid)/ry)**2.25)
    c = mix(rgb('C77D43'), rgb('FFD5A9'), smooth((edge+.018)/.036))
    r = ((abs(x)-.56)/.16)**2 + ((z-.84)/.12)**2
    return mix(c, rgb('EF8D81'), .53 * math.exp(-r*2.4))

def side_pixel(u,v):
    y,z = 2*u-1,2*v+.24
    # Three broad points suggest the cheek tuft without a protruding muzzle.
    outline = [(-.49,1.06),(-.30,1.20),(.23,1.43),(.43,1.47),
               (.42,1.33),(.26,1.16),(.40,1.18),(.36,1.04),
               (.19,.91),(.27,.91),(.16,.79),(-.07,.76),(-.32,.85)]
    inside=False
    dist=5
    for (ay,az),(by,bz) in zip(outline,outline[1:]+outline[:1]):
        dy,dz=by-ay,bz-az
        t=max(0,min(1,((y-ay)*dy+(z-az)*dz)/(dy*dy+dz*dz)))
        dist=min(dist,math.hypot(y-ay-t*dy,z-az-t*dz))
        if (az>z)!=(bz>z) and y<ay+(z-az)*dy/dz:
            inside=not inside
    return mix(rgb('C77D43'),rgb('D68D4F'),smooth(.5+(dist if inside else -dist)/.038))

def body_pixel(u,v):
    return face_pixel(2*u,v) if u<.5 else side_pixel(2*u-1,v)

texture('body-albedo', 512, body_pixel, front)
body = box('Square caramel body', (0,0,1.24), (2,2,2), .24, front, apply_bevel=True)
for old_uv in list(body.data.uv_layers):
    body.data.uv_layers.remove(old_uv)
uv = body.data.uv_layers.new(name='Face projection')
body.data.uv_layers.active = uv
uv.active_render = True
for p in body.data.polygons:
    is_front = p.normal.y < -.12
    is_side = abs(p.normal.x) > .65 and not is_front
    for li in p.loop_indices:
        co = body.data.vertices[body.data.loops[li].vertex_index].co
        u = .503+.244*(co.y+1) if is_side else .003+.244*(co.x+1)
        uv.data[li].uv = (u, (co.z+1)*.5) if is_front or is_side else (.05,.98)

for x, side in ((-.62,'L'),(.62,'R')):
    for y, end in ((-.62,'front'),(.61,'back')):
        box(f'Paw {side} {end}', (x,y,.155), (.44,.48,.31), .13, paws, 3)

for side in (-1,1):
    x = side*.53
    ear = sphere(f'Ear {side}', (x,-.33,2.285), (.275,.17,.47), caramel,20,10)
    ear.rotation_euler.y = side*.17
    inset = sphere(f'Ear cream {side}', (x+side*.023,-.459,2.337), (.163,.062,.312), cream,20,10)
    inset.rotation_euler.y = side*.17

def iris_pixel(u,v):
    x,z = (u-.5)*2,(v-.5)*2
    r = math.hypot(x,z)
    color = mix((255,202,56),(91,39,6),smooth((z+1)/2))
    edge = 1-.32*smooth((r-.86)/.14)
    color = tuple(int(c*edge) for c in color)
    pupil = ((x+.012)/.69)**2 + ((z-.09)/.76)**2
    return mix(color,(43,18,4),smooth((1.05-pupil)/.14))

texture('amber-iris', 256, iris_pixel, iris)

def eye_disc(x,z,side):
    rings, steps = 5,32
    verts = [(x,-1.089,z)]
    uv = [(.5,.5)]
    for i in range(1,rings+1):
        r=i/rings
        for j in range(steps):
            a=2*math.pi*j/steps
            u,w = r*math.cos(a),r*math.sin(a)
            verts.append((x+.235*u,-1.041-.048*math.sqrt(max(0,1-r*r)),z+.287*w))
            uv.append((.5+.5*u,.5+.5*w))
    faces=[(0,1+j,1+(j+1)%steps) for j in range(steps)]
    for i in range(rings-1):
        a,b=1+i*steps,1+(i+1)*steps
        faces.extend((a+j,b+j,b+(j+1)%steps,a+(j+1)%steps) for j in range(steps))
    mesh_object(f'Illustrated amber iris {side}', verts, faces, iris, uv)

for x, side in ((-.423,'L'),(.423,'R')):
    sphere(f'Eye white {side}',(x,-1.006,1.166),(.283,.052,.336),white,28,12)
    eye_disc(x+.007,1.135,side)
    sphere(f'Eye glint {side}',(x-.071,-1.088,1.292),(.061,.015,.068),glint,12,8)
    sphere(f'Eye glint small {side}',(x+.093,-1.086,1.05),(.024,.012,.026),glint,12,6)
sphere('Chocolate nose',(0,-1.032,.965),(.089,.048,.048),dark,16,10)

def smile_curve(name, points):
    data=bpy.data.curves.new(name,'CURVE')
    data.dimensions='3D'
    data.resolution_u=7
    data.bevel_resolution=2
    data.bevel_depth=.013
    data.use_fill_caps=True
    spline=data.splines.new('BEZIER')
    spline.bezier_points.add(len(points)-1)
    for point,co in zip(spline.bezier_points,points):
        point.co=co
        point.handle_left_type=point.handle_right_type='AUTO'
    obj=bpy.data.objects.new(name,data)
    asset.objects.link(obj)
    obj.parent=root
    data.materials.append(dark)

smile_curve('Smile', [(-.142,-1.012,.885),(-.087,-1.015,.84),(0,-1.015,.914),(.087,-1.015,.84),(.142,-1.012,.885)])

# Model the tail as a solid acorn silhouette. The shallow curl is sculpted into
# both sides of the surface so it reads from either three-quarter angle.
spiral = []
for i in range(120):
    a = -.9 + i/119*6.1
    r = .035+.35*(i/119)
    spiral.append((1.77+r*math.cos(a),1.74+r*math.sin(a)))

def tail_point(theta, phi, cap_offset=0):
    s,c=math.sin(theta),math.cos(theta)
    x=.84*s*math.cos(phi)
    y=1.48+.85*s*math.sin(phi)+.34*c
    z=1.81+1.11*c
    if abs(math.cos(phi))>.58 and not cap_offset:
        d2=min((y-a)**2+(z-b)**2 for a,b in spiral)
        roll=.064*math.exp(-((y-1.77)**2+(z-1.74)**2)/.10)
        groove=.10*math.exp(-d2/.010)
        x += math.copysign(1,x)*(roll-groove)*smooth((abs(math.cos(phi))-.58)/.38)
    if cap_offset:
        cap_offset+=.038*math.cos(5*phi+.6)*smooth(s/.65)
        x += cap_offset*s*math.cos(phi)
        y += cap_offset*s*math.sin(phi)
        z += cap_offset*c
    # Present the broad curl to the same three-quarter angle as the concept.
    angle=math.radians(-33)
    d=y-1.05
    side_shift=.20*smooth((z-.78)/.95)
    return (x*math.cos(angle)-d*math.sin(angle)+side_shift,1.05+x*math.sin(angle)+d*math.cos(angle),z)

def shell(name, mat, rings, steps, end_theta, offset=0, closed_bottom=False):
    verts=[tail_point(0,0,offset)]
    num_rings=rings if closed_bottom else rings-1
    for i in range(1,num_rings+1):
        for j in range(steps):
            phi=2*math.pi*j/steps
            verts.append(tail_point(end_theta(phi)*i/rings,phi,offset))
    faces=[(0,1+j,1+(j+1)%steps) for j in range(steps)]
    for i in range(num_rings-1):
        a,b=1+i*steps,1+(i+1)*steps
        faces.extend((a+j,b+j,b+(j+1)%steps,a+(j+1)%steps) for j in range(steps))
    last=1+(num_rings-1)*steps
    if closed_bottom:
        inner=len(verts)
        for j in range(steps):
            x,y,z=verts[last+j]
            verts.append((.50+(x-.50)*.87,1.7+(y-1.7)*.87,z+.015))
        faces.extend((last+j,inner+j,inner+(j+1)%steps,last+(j+1)%steps) for j in range(steps))
        faces.append(tuple(inner+j for j in reversed(range(steps))))
    else:
        end=len(verts)
        verts.append(tail_point(math.pi,0,offset))
        faces.extend((last+j,end,last+(j+1)%steps) for j in range(steps))
    obj=mesh_object(name,verts,faces,mat)
    bm=bmesh.new()
    bm.from_mesh(obj.data)
    bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces))
    bm.to_mesh(obj.data)
    bm.free()
    return obj

def curl_pixel(u,v):
    y,z=1.15+1.40*u,.88+1.62*v
    dist=min(math.hypot(y-a,z-b) for a,b in spiral)
    return mix(rgb('BC7136'),rgb('925024'),.49*math.exp(-(dist/.055)**2))

texture('tail-curl',256,curl_pixel,tail)
tail_body=shell('Curled acorn tail',tail,32,44,lambda _:math.pi)
tail_uv=tail_body.data.uv_layers.new(name='Curl projection')
angle=math.radians(-33)
for loop in tail_body.data.loops:
    x,y,z=tail_body.data.vertices[loop.vertex_index].co
    x-=.20*smooth((z-.78)/.95)
    base_y=1.05-x*math.sin(angle)+(y-1.05)*math.cos(angle)
    base_x=x*math.cos(angle)+(y-1.05)*math.sin(angle)
    tail_uv.data[loop.index].uv=((base_y-1.15)/1.40,(z-.88)/1.62) if abs(base_x)>.46 else (.98,.98)
shell('Scalloped cocoa acorn cap',cap,12,40,lambda p:1.07+.065*math.cos(5*p+.6),.085,True)

def export():
    bpy.context.view_layer.update()
    dg=bpy.context.evaluated_depsgraph_get()
    triangles={}
    for o in asset.objects:
        if o.type in {'MESH','CURVE'}:
            evaluated=o.evaluated_get(dg)
            m=evaluated.to_mesh()
            m.calc_loop_triangles()
            assert all(t.area>1e-12 for t in m.loop_triangles),o.name
            triangles[o.name]=len(m.loop_triangles)
            evaluated.to_mesh_clear()
    assert sum(triangles.values()) < 10000, triangles
    bpy.ops.object.select_all(action='SELECT')
    bpy.context.view_layer.objects.active=body
    bpy.ops.wm.save_as_mainfile(filepath=str(MODEL/'AcornSquirrel.blend'))
    bpy.ops.export_scene.gltf(filepath=str(MODEL/'AcornSquirrel.glb'),export_format='GLB',use_selection=True,export_apply=True,export_animations=False,export_cameras=False,export_lights=False)
    smile=asset.objects['Smile']
    dg=bpy.context.evaluated_depsgraph_get()
    mesh=bpy.data.meshes.new_from_object(smile.evaluated_get(dg),depsgraph=dg)
    baked=bpy.data.objects.new('Smile mesh',mesh)
    asset.objects.link(baked)
    baked.parent=root
    baked.matrix_world=smile.matrix_world
    smile.select_set(False)
    baked.select_set(True)
    bpy.ops.export_scene.fbx(filepath=str(MODEL/'AcornSquirrel.fbx'),use_selection=True,global_scale=1,apply_scale_options='FBX_SCALE_UNITS',axis_forward='Z',axis_up='Y',object_types={'MESH','EMPTY'},use_triangles=True,bake_anim=False,path_mode='COPY',embed_textures=True)
    bpy.data.objects.remove(baked,do_unlink=True)
    return triangles

def bounds(objs):
    pts=[o.matrix_world@Vector(c) for o in objs if o.type in {'MESH','CURVE'} for c in o.bound_box]
    return [[min(p[i] for p in pts) for i in range(3)], [max(p[i] for p in pts) for i in range(3)]]

triangles=export()
expected=bounds(asset.objects)
binary=(MODEL/'AcornSquirrel.glb').read_bytes()
length=struct.unpack_from('<I',binary,12)[0]
glb=json.loads(binary[20:20+length])
assert not any(item.get('uri') for group in ('buffers','images') for item in glb.get(group,[]))
imports={}
validation_scenes={}
roundtrip = WORK / 'roundtrip'
roundtrip.mkdir(exist_ok=True)
for ext in ('blend','glb','fbx'):
    p=roundtrip/('AcornSquirrel.'+ext)
    shutil.copyfile(MODEL/p.name,p)
    check=bpy.data.scenes.new('Validation '+ext)
    bpy.context.window.scene=check
    if ext=='blend':
        with bpy.data.libraries.load(str(p),link=False) as (source,dest):
            assert source.scenes==['AcornSquirrel']
            dest.collections=['AcornSquirrel_Asset']
        check.collection.children.link(dest.collections[0])
    elif ext=='glb':
        bpy.ops.import_scene.gltf(filepath=str(p),import_pack_images=True)
    else:
        bpy.ops.import_scene.fbx(filepath=str(p))
    bpy.context.view_layer.update()
    actual=bounds(check.objects)
    delta=max(abs(a-b) for u,v in zip(actual,expected) for a,b in zip(u,v))
    assert delta<.007,(ext,delta,actual,expected)
    assert not any(o.type in {'CAMERA','LIGHT'} for o in check.objects)
    mats={m for o in check.objects if o.type in {'MESH','CURVE'} for m in o.data.materials if m}
    images={n.image for m in mats if m.use_nodes for n in m.node_tree.nodes if n.type=='TEX_IMAGE' and n.image}
    assert len(images)>=3 and all(im.packed_file for im in images), (ext, [im.name for im in images])
    assert any('Scalloped cocoa' in o.name for o in check.objects)
    assert any(o.name.startswith('Smile') for o in check.objects)
    assert all(o.matrix_world.translation.y < -.98 for o in check.objects if o.name.startswith('Eye white'))
    imports[ext]={'bounds_error':delta,'embedded_images':len(images),'meshes':sum(o.type=='MESH' for o in check.objects)}
    validation_scenes[ext]=check
    bpy.context.window.scene=scene

report={'triangles':sum(triangles.values()),'max_part_triangles':max(triangles.values()),'parts':triangles,'bounds':expected,'imports':imports,'front':'-Y'}
(WORK/'verification.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')

preview=bpy.data.scenes.new('Preview')
preview.collection.children.link(asset)
bpy.context.window.scene=preview
world=bpy.data.worlds.new('Soft neutral fill')
world.use_nodes=True
world.node_tree.nodes['Background'].inputs[0].default_value=(.9,.94,1,1)
world.node_tree.nodes['Background'].inputs[1].default_value=.32
preview.world=world
preview.render.engine='CYCLES'
preview.cycles.samples=32
preview.cycles.use_denoising=True
preview.render.resolution_x=760
preview.render.resolution_y=760
preview.render.resolution_percentage=100
preview.render.image_settings.file_format='PNG'
preview.view_settings.view_transform='Standard'
preview.view_settings.look='None'
bpy.ops.mesh.primitive_plane_add(size=200, location=(0,0,-.006))
bpy.context.object.data.materials.append(material('Sage backdrop','D8E0C5',.8))

def aim(obj,target):
    obj.rotation_euler=(Vector(target)-obj.location).to_track_quat('-Z','Y').to_euler()

for name,loc,power,size in [('Key',(-3.5,-4.5,6),440,5),('Fill',(4,-4,4),240,4),('Rim',(2,4,5),290,4)]:
    data=bpy.data.lights.new(name,'AREA')
    data.energy,data.size=power,size
    o=bpy.data.objects.new(name,data)
    preview.collection.objects.link(o)
    o.location=loc
    aim(o,(0,.5,1.5))
camera=bpy.data.objects.new('Review camera',bpy.data.cameras.new('Review camera'))
preview.collection.objects.link(camera)
preview.camera=camera
camera.data.type='ORTHO'
camera.data.ortho_scale=4.7
for label,loc in [('front-three-quarter',(6.6,-8.0,3.9)),('rear-three-quarter',(6.2,8.4,4.7))]:
    camera.location=loc
    aim(camera,(0,.60,1.61))
    preview.render.filepath=str(WORK/(label+'.png'))
    bpy.ops.render.render(write_still=True,scene=preview.name)

camera.location=(6.6,-8.0,3.9)
aim(camera,(0,.60,1.61))
for ext, check in validation_scenes.items():
    for o in preview.objects:
        if o not in asset.objects.values():
            check.collection.objects.link(o)
    check.camera=camera
    check.world=world
    check.render.engine='CYCLES'
    check.cycles.samples=16
    check.cycles.use_denoising=True
    check.view_settings.view_transform='Standard'
    check.view_settings.look='None'
    check.render.resolution_x=480
    check.render.resolution_y=480
    check.render.resolution_percentage=100
    check.render.filepath=str(WORK/f'roundtrip-{ext}.png')
    bpy.ops.render.render(write_still=True,scene=check.name)
print('ACORN_SQUIRREL_VERIFIED', json.dumps(report))
