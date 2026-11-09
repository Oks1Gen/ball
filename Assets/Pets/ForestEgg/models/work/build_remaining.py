"""Build the last three Forest Egg pets in a separate Blender process."""

import json
import math
import shutil
import struct
import sys
import tempfile
import zlib
from pathlib import Path

import bmesh
import bpy
import numpy as np
from mathutils import Vector


MODELS = Path(__file__).resolve().parents[1]
PETS = {
    'BloomFox': ('Bloom Fox', 'F27951', 'FFDCB8', 'EF887C', 'EA7246'),
    'MoonOwl': ('Moon Owl', 'C496CA', 'FFE6C8', 'D89AAA', 'F3AC41'),
    'GroveGuardian': ('Grove Guardian', 'C1BE87', 'FFE2BF', 'F08A82', '8A4C26'),
}
NAME, *FLAGS = sys.argv[sys.argv.index('--')+1:]
DRAFT = '--draft' in FLAGS
LABEL, COAT, CREAM, BLUSH, PAW = PETS[NAME]
WORK = MODELS / NAME / 'v1' / 'work'
MODEL = WORK.parent / 'model'
WORK.mkdir(parents=True, exist_ok=True)
MODEL.mkdir(exist_ok=True)

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.context.preferences.filepaths.save_version = 0
scene = bpy.context.scene
scene.name = NAME
asset = bpy.data.collections.new(NAME + '_Asset')
scene.collection.children.link(asset)
bpy.context.view_layer.active_layer_collection = bpy.context.view_layer.layer_collection.children[asset.name]
root = bpy.data.objects.new(NAME, None)
asset.objects.link(root)
root['Front'] = '-Y'
root['Reference'] = 'Forest Egg v4 / ' + LABEL


def color(code):
    return tuple(int(code[i:i+2], 16) for i in (0, 2, 4))


def linear(value):
    value /= 255
    return value / 12.92 if value < .04045 else ((value + .055) / 1.055)**2.4


def material(name, code, roughness=.39, emission=0):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    rgba = (*map(linear, color(code)), 1)
    shader = mat.node_tree.nodes.get('Principled BSDF')
    shader.inputs['Base Color'].default_value = rgba
    shader.inputs['Roughness'].default_value = roughness
    shader.inputs['Emission Color'].default_value = rgba
    shader.inputs['Emission Strength'].default_value = emission
    mat.diffuse_color = rgba
    mat['sRGB'] = '#' + code
    return mat


def smooth(t):
    t = np.clip(t, 0, 1)
    return t*t*(3-2*t)


def mix(a, b, amount):
    return np.asarray(a) + (np.asarray(b)-a) * np.asarray(amount)[..., None]


def paint(mat, name, painter, size=512):
    u, v = np.meshgrid((np.arange(size)+.5)/size, 1-(np.arange(size)+.5)/size)
    pixels = np.rint(painter(u, v)).clip(0, 255).astype('uint8')
    raw = b''.join(b'\0' + row.tobytes() for row in pixels)

    def chunk(tag, data):
        return struct.pack('>I', len(data)) + tag + data + struct.pack('>I', zlib.crc32(tag+data))

    path = WORK / (name + '.png')
    path.write_bytes(
        b'\x89PNG\r\n\x1a\n'
        + chunk(b'IHDR', struct.pack('>IIBBBBB', size, size, 8, 2, 0, 0, 0))
        + chunk(b'IDAT', zlib.compress(raw, 8))
        + chunk(b'IEND', b'')
    )
    image = bpy.data.images.load(str(path))
    image.pack()
    tex = mat.node_tree.nodes.new('ShaderNodeTexImage')
    tex.image = image
    tex.extension = 'EXTEND'
    mat.node_tree.links.new(tex.outputs['Color'], mat.node_tree.nodes.get('Principled BSDF').inputs['Base Color'])


def attach(obj, name, mat):
    obj.name = name
    obj.parent = root
    obj.data.materials.append(mat)
    for face in obj.data.polygons:
        face.use_smooth = True
    return obj


def mesh(name, vertices, faces, mat):
    data = bpy.data.meshes.new(name)
    data.from_pydata(vertices, [], faces)
    bm = bmesh.new()
    bm.from_mesh(data)
    bmesh.ops.recalc_face_normals(bm, faces=list(bm.faces))
    bm.to_mesh(data)
    bm.free()
    data.update()
    obj = bpy.data.objects.new(name, data)
    asset.objects.link(obj)
    return attach(obj, name, mat)


def uv_map(obj, project):
    for uv in list(obj.data.uv_layers):
        obj.data.uv_layers.remove(uv)
    uv = obj.data.uv_layers.new(name='UVMap')
    for face in obj.data.polygons:
        for li in face.loop_indices:
            index = obj.data.loops[li].vertex_index
            uv.data[li].uv = project(index, face)


def sphere(name, loc, scale, mat, steps=18, rings=10):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=steps, ring_count=rings, location=loc)
    obj = attach(bpy.context.object, name, mat)
    obj.scale = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    return obj


def box(name, loc, size, radius, mat, segments=6):
    bpy.ops.mesh.primitive_cube_add(size=1, location=loc)
    obj = attach(bpy.context.object, name, mat)
    obj.scale = size
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    bevel = obj.modifiers.new('Soft corners', 'BEVEL')
    bevel.width = radius
    bevel.segments = segments
    bpy.ops.object.modifier_apply(modifier=bevel.name)
    normals = obj.modifiers.new('Soft edge normals', 'WEIGHTED_NORMAL')
    normals.keep_sharp = True
    return obj


def bezier_outline(start, segments, steps=9):
    result = []
    p = np.asarray(start)
    for handles in segments:
        a, b, q = map(np.asarray, handles)
        for i in range(steps):
            t = i/steps
            s = 1-t
            result.append(s**3*p + 3*s*s*t*a + 3*s*t*t*b + t**3*q)
        p = q
    return result


def signed_distance(x, y, outline):
    distance = np.full(x.shape, 100.0)
    inside = np.zeros(x.shape, dtype=bool)
    for a, b in zip(outline, outline[1:] + outline[:1]):
        dx, dy = b-a
        t = np.clip(((x-a[0])*dx + (y-a[1])*dy)/(dx*dx+dy*dy), 0, 1)
        distance = np.minimum(distance, (x-a[0]-t*dx)**2 + (y-a[1]-t*dy)**2)
        if abs(dy) > 1e-8:
            inside ^= ((a[1] > y) != (b[1] > y)) & (x < a[0] + (y-a[1])*dx/dy)
    return np.where(inside, 1, -1) * np.sqrt(distance)


def shape_alpha(x, y, outline, width=.009):
    return smooth(.5 + signed_distance(x, y, outline)/width)


def disk_faces(steps, rings, solid=False):
    faces = [(0, 1+j, 1+(j+1)%steps) for j in range(steps)]
    for i in range(rings-1):
        a, b = 1+i*steps, 1+(i+1)*steps
        faces.extend((a+j, b+j, b+(j+1)%steps, a+(j+1)%steps) for j in range(steps))
    if solid:
        a = 1+(rings-1)*steps
        faces.extend((a+j, 1+rings*steps, a+(j+1)%steps) for j in range(steps))
    return faces


def pillow(name, center, axes, outline, mat, thickness, dish=0, texture=False, mirror=False):
    """An inflated closed outline, with optional shallow scoop on its face."""
    h, v = map(Vector, axes)
    front = h.cross(v).normalized()
    center = Vector(center)
    focal = np.mean(outline, axis=0)
    vertices, projected = [], []
    steps = len(outline)

    def point(x, y, d):
        vertices.append(center + h*(-x if mirror else x) + v*y + front*d)
        projected.append(((x+1)*.5, (y+1)*.5))

    point(*focal, thickness[0]-dish)
    radial = [.25, .53, .76, .91, 1, .91, .68, .36]
    for i, r in enumerate(radial):
        dome = math.sqrt(max(0, 1-r*r))
        depth = thickness[0]*dome - dish*math.exp(-4*r*r) if i < 4 else -thickness[1]*dome
        for x, y in outline:
            point(*(focal+r*(np.array([x, y])-focal)), depth)
    point(*focal, -thickness[1])
    obj = mesh(name, vertices, disk_faces(steps, len(radial), solid=True), mat)
    if texture:
        uv_map(obj, lambda i, f: projected[i] if f.normal.dot(front) > .04 else (.98, .98))
    return obj


def catmull(points, t):
    k = min(len(points)-2, int(t))
    a, b = points[k:k+2]
    p = points[k-1] if k else 2*a-b
    q = points[k+2] if k+2 < len(points) else 2*b-a
    u = t-k
    return a + .5*u*(b-p + u*(2*p-5*a+4*b-q + u*(3*a-3*b+q-p)))


def sweep(name, stations, mat, axis=(1, 0, 0), steps=22, rings=22, texture=False):
    """Loft rounded elliptical sections down a hand-shaped centreline."""
    points = np.array(stations)
    end = len(stations)-1
    vertices = [points[0, :3]]
    uv = [(.5, 0)]
    for i in range(1, rings+1):
        t = end*i/(rings+1)
        x, y, z, width, depth = catmull(points, t)
        tangent = Vector(catmull(points, t+.001)[:3]-catmull(points, t-.001)[:3]).normalized()
        cross = Vector(axis).cross(tangent).normalized()
        along = tangent.cross(cross)
        for j in range(steps):
            angle = 2*math.pi*j/steps
            vertices.append(Vector((x, y, z)) + along*max(.004, width)*math.cos(angle) + cross*max(.004, depth)*math.sin(angle))
            uv.append((j/steps, i/(rings+1)))
    vertices.append(points[-1, :3])
    uv.append((.5, 1))
    obj = mesh(name, vertices, disk_faces(steps, rings, solid=True), mat)
    if texture:
        def project(i, face):
            u, v = uv[i]
            sides = [uv[j][0] for j in face.vertices if j not in (0, len(uv)-1)]
            if max(sides)-min(sides) > .5:
                sides = [s+1 if s < .5 else s for s in sides]
                u = u+1 if u < .5 else u
            return (sum(sides)/len(sides) if i in (0, len(uv)-1) else u, v)
        uv_map(obj, project)
    return obj


def face_mask(x, z, lower=.34):
    # Low, continuous cream muzzle with two high arches above the eyes.
    outline = bezier_outline((0, 1.32), [
        ((-.24, 1.82), (-.66, 1.84), (-.84, 1.51)),
        ((-.98, 1.29), (-.95, .79), (-.93, .57)),
        ((-.92, .36), (-.67, lower), (0, lower)),
        ((.67, lower), (.92, .36), (.93, .57)),
        ((.95, .79), (.98, 1.29), (.84, 1.51)),
        ((.66, 1.84), (.24, 1.82), (0, 1.32)),
    ])
    return shape_alpha(x, z, outline)


def body_pixel(u, v):
    z = .24+2*v
    x = 2*(2*u % 1)-1
    if NAME == 'MoonOwl':
        a = 1-((np.abs(x)-.427)/.455)**2-((z-1.115-.10*(np.abs(x)-.427))/.553)**2
        mask = smooth(.5+a/.034)
    else:
        mask = face_mask(x, z, .33 if NAME == 'BloomFox' else .36)
    coat = np.array(color(COAT))
    front = mix(coat, color(CREAM), mask)
    if NAME != 'MoonOwl':
        blush = .72*np.exp(-2.1*(((np.abs(x)-.65)/.185)**2 + ((z-.88)/.15)**2))
        front = mix(front, color(BLUSH), blush*mask)
    if NAME == 'GroveGuardian':
        spots = np.zeros(x.shape)
        for y, height, w, h in [(-.30, 1.08, .068, .11), (.02, 1.16, .072, .115), (-.08, 1.41, .062, .108)]:
            spots = np.maximum(spots, smooth(.5+(1-((x-y)/w)**2-((z-height)/h)**2)/.25))
        side = mix(coat, color('EBCB9E'), spots)
    else:
        side = np.broadcast_to(coat, front.shape)
    return np.where((u < .5)[..., None], front, side)


coat_mat = material('Body coat', COAT)
paint(coat_mat, 'body-albedo', body_pixel)
paw_mat = material('Paws', PAW, .42)
body = box('Square body', (0, 0, 1.24), (2, 2, 2), .22, coat_mat, 6)


def body_projection(i, face):
    x, y, z = body.data.vertices[i].co
    if face.normal.y < -.17:
        return (.25+.243*x, (z+1)*.5)
    if abs(face.normal.x) > .66:
        return (.75+.243*y, (z+1)*.5)
    return (.98, .97)


uv_map(body, body_projection)
for s, side in [(-1, 'L'), (1, 'R')]:
    for y, end in [(-.62, 'front'), (.60, 'rear')]:
        box(f'Paw {side} {end}', (s*.62, y, .15), (.43, .45, .30), .132, paw_mat, 3)
    for toe in [-1, 1]:
        sphere(f'Toe {side} {toe}', (s*.62+toe*.091, -.752, .109), (.106, .102, .106), paw_mat, 12, 6)


def eye_pixel(u, v):
    x, z = (u-.5)*2, (v-.5)*2
    if NAME == 'MoonOwl':
        lower, upper, pupil = 'FFBD2D', '8F480F', '42220D'
    else:
        lower, upper, pupil = '24E594', '117858', '0A3929'
    r = np.sqrt(((x-.025)/.865)**2 + ((z+.030)/.892)**2)
    iris = mix(color(lower), color(upper), smooth((z+.76)/1.48))
    iris = mix(iris, color(upper), .22*smooth((r-.84)/.16))
    p = ((x-.025)/.72)**2 + ((z-.17)/.687)**2
    iris = mix(iris, color(pupil), smooth((1.09-p)/.30))
    glint = smooth((.224-np.hypot(x+.276, z-.456))/.035)
    small = .88*smooth((.081-np.hypot(x-.37, z+.37))/.033)
    iris = mix(iris, color('FFFDF2'), np.maximum(glint, small))
    return mix(color('FFF5EB'), iris, smooth((1.01-r)/.021))


eyes = material('Glossy iris and catchlights', 'FFF5EB', .29)
eyes.node_tree.nodes.get('Principled BSDF').inputs['Specular IOR Level'].default_value = .26
paint(eyes, 'iris-albedo', eye_pixel, 256)
for s, side in [(-1, 'L'), (1, 'R')]:
    eye_x, eye_z = s*(.417 if NAME == 'MoonOwl' else .385), 1.15
    r_x, r_z = (.258, .271) if NAME == 'MoonOwl' else (.257, .263)
    coords = [(eye_x, -1.061, eye_z)]
    projections = [(.5, .5)]
    for ring in range(1, 8):
        r = ring/7
        for j in range(32):
            a = 2*math.pi*j/32
            u, v = r*math.cos(a), r*math.sin(a)
            coords.append((eye_x+u*r_x, -1.008-.053*math.sqrt(1-r*r), eye_z+v*r_z))
            projections.append((.5+.495*u, .5+.495*v))
    coords.append((eye_x, -.987, eye_z))
    projections.append((.5, .5))
    eye = mesh(f'Eye {side}', coords, disk_faces(32, 7, solid=True), eyes)
    uv_map(eye, lambda i, _: projections[i])


def smile():
    nose = material('Coral nose', 'E67569', .32)
    dark = material('Chocolate smile', '553624', .45)
    sphere('Little nose', (0, -1.031, .954), (.084, .046, .046), nose, 18, 10)
    data = bpy.data.curves.new('Smile', 'CURVE')
    data.dimensions = '3D'
    data.resolution_u = 7
    data.bevel_resolution = 1
    data.bevel_depth = .015
    data.use_fill_caps = True
    spline = data.splines.new('BEZIER')
    points = [(-.144, -1.011, .864), (-.085, -1.019, .821), (0, -1.022, .903),
              (.085, -1.019, .821), (.144, -1.011, .864)]
    spline.bezier_points.add(len(points)-1)
    for point, coord in zip(spline.bezier_points, points):
        point.co = coord
        point.handle_left_type = point.handle_right_type = 'AUTO'
    obj = bpy.data.objects.new('Smile', data)
    asset.objects.link(obj)
    obj.parent = root
    data.materials.append(dark)


def ear_panel(mat, name, main, inner, outline):
    def pixel(u, v):
        return mix(color(main), color(inner), shape_alpha(2*u-1, 2*v-1, outline, .015))
    paint(mat, name, pixel, 256)


FRONTAL = ((1, 0, 0), (0, 0, 1))


def fox():
    smile()
    ear_outer = bezier_outline((-.34, -.12), [
        ((-.44, .21), (-.37, .64), (-.27, .85)),
        ((-.24, .92), (-.19, .93), (-.11, .89)),
        ((.18, .76), (.40, .44), (.46, .08)),
        ((.40, -.05), (-.16, -.15), (-.34, -.12)),
    ])
    ear_inner = bezier_outline((-.225, .025), [
        ((-.29, .23), (-.26, .50), (-.20, .68)),
        ((-.18, .715), (-.15, .72), (-.10, .67)),
        ((.09, .54), (.27, .26), (.29, .025)),
        ((.16, -.045), (-.10, -.055), (-.225, .025)),
    ])
    ear = material('Coral ears with apricot insets', COAT)
    ear_panel(ear, 'ear-albedo', COAT, 'F8C397', ear_inner)
    tufts = material('Ivory ear tufts', 'FFE5CD')
    for s, side in [(1, 'L'), (-1, 'R')]:
        pillow(f'Pointed ear {side}', (-s*.64, -.54, 2.105), FRONTAL,
               ear_outer, ear, (.162, .148), dish=.027, texture=True, mirror=s == -1)
        for j, (offset, height, tilt) in enumerate([(-.12, .112, -.44), (.015, .172, -.23)]):
            tuft = sphere(f'Ear tuft {side} {j+1}', (s*(-.63+offset), -.685, 2.20+height*.43),
                          (.094, .066, height), tufts, 14, 8)
            tuft.rotation_euler.y = s*tilt
    tails = material('Coral and cream tail tips', 'EC6944')

    def tail_pixel(u, v):
        tooth = np.abs((u*4+.43) % 1*2-1)
        border = .49 + .22*tooth + .042*np.sin(2*np.pi*(u+.08))
        blend = smooth(.5+(v-border)/.011)
        return mix(color('EC6944'), color('FFE1BF'), blend)

    paint(tails, 'tail-albedo', tail_pixel, 512)
    sweep('High cream-tipped tail', [
        (-.24, .69, .83, 0, 0), (-.22, 1.12, .91, .26, .22),
        (-.18, 1.67, 1.35, .44, .40), (.05, 2.07, 1.88, .51, .46),
        (.36, 2.28, 2.25, .46, .36), (.58, 2.43, 2.41, .33, .24),
        (.78, 2.57, 2.49, .20, .13), (.92, 2.70, 2.49, 0, 0),
    ], tails, rings=29, texture=True)
    sweep('Low cream-tipped tail', [
        (.46, .69, .70, 0, 0), (.66, 1.06, .69, .27, .23),
        (.90, 1.49, .83, .47, .38), (1.04, 1.79, 1.25, .55, .45),
        (1.11, 1.88, 1.77, .50, .39), (1.23, 1.97, 2.06, .37, .28),
        (1.41, 2.10, 2.24, .21, .15), (1.58, 2.22, 2.28, 0, 0),
    ], tails, rings=29, texture=True)


def owl():
    ear = material('Lilac ear and plum fold', 'CF9AD1')
    ear_outline = bezier_outline((-.32, -.13), [
        ((-.38, .11), (-.34, .46), (-.26, .59)),
        ((-.15, .73), (.24, .40), (.40, .01)),
        ((.29, -.11), (-.19, -.13), (-.32, -.13)),
    ], 12)
    ear_fold = bezier_outline((-.34, -.10), [
        ((-.37, .14), (-.32, .44), (-.29, .52)),
        ((-.18, .41), (.05, .16), (.106, -.03)),
        ((.02, -.14), (-.30, -.19), (-.34, -.10)),
    ], 10)
    ear_panel(ear, 'ear-albedo', 'CF9AD1', 'A471AC', ear_fold)
    pillow('Left plumage tuft', (-.69, -.52, 2.11), FRONTAL, ear_outline, ear, (.137, .17), texture=True)
    pillow('Right plumage tuft', (.69, -.52, 2.11), FRONTAL, ear_outline, ear, (.137, .17), texture=True, mirror=True)

    wing_mat = material('Soft plum wings', 'A970B3')
    wing = bezier_outline((-.48, -.19), [
        ((-.44, .18), (-.18, .55), (.21, .61)),
        ((.50, .65), (.59, .36), (.49, .14)),
        ((.46, .045), (.37, -.05), (.28, -.106)),
        ((.45, -.063), (.49, -.14), (.38, -.31)),
        ((.20, -.60), (-.07, -.63), (-.27, -.49)),
        ((-.43, -.43), (-.50, -.32), (-.48, -.19)),
    ], 7)
    for s, side in [(1, 'R'), (-1, 'L')]:
        pillow(f'Scalloped wing {side}', (s*.96, -.07, 1.15), ((.49, s*.872, 0), (0, 0, 1)),
               [np.array((s*u, v)) for u, v in wing], wing_mat, (.237, .12))
    for s in [-1, 0, 1]:
        sweep(f'Rounded tail feather {s+2}', [
            (.31*s, .80, .61, 0, 0), (.39*s, 1.00, .64, .24, .15),
            (.54*s, 1.26, .70, .23, .14), (.75*s, 1.46, .79, .16, .09),
            (.83*s, 1.54, .84, 0, 0),
        ], wing_mat, rings=9, steps=14)
    moon_mat = material('Vanilla crescent', 'FFE4AE', .35)
    moon = bezier_outline((-.10, .238), [
        ((-.37, .17), (-.33, -.20), (-.096, -.245)),
        ((.15, -.314), (.30, -.14), (.277, .082)),
        ((.273, .128), (.25, .169), (.223, .166)),
        ((.223, .031), (.149, -.046), (.057, -.050)),
        ((-.075, -.066), (-.180, .057), (-.10, .238)),
    ], 10)
    # Place the concave crescent as a thin, smoothly rounded extruded plaque.
    plaque('Forehead crescent', (0, -1.013, 1.845), moon, moon_mat)
    beak = material('Honey beak', 'F3AB24', .32)
    profile = bezier_outline((-.139, .045), [
        ((-.149, .13), (.117, .141), (.137, .068)),
        ((.154, .029), (.065, -.134), (.016, -.176)),
        ((-.022, -.199), (-.102, -.086), (-.139, .045)),
    ], 12)
    pillow('Little golden beak', (0, -1.036, .97), FRONTAL, profile, beak, (.14, .04))


def plaque(name, center, outline, mat):
    # An n-gon front lets Blender tessellate the hollow of the crescent.
    verts = [(center[0]+x, center[1]+d, center[2]+z) for d in [-.036, .021] for x, z in outline]
    n = len(outline)
    faces = [tuple(range(n)), tuple(range(n, 2*n))]
    faces.extend((i, n+i, n+(i+1)%n, (i+1)%n) for i in range(n))
    obj = mesh(name, verts, faces, mat)
    bpy.ops.object.select_all(action='DESELECT')
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    bevel = obj.modifiers.new('Rounded edge', 'BEVEL')
    bevel.width = .023
    bevel.segments = 4
    bpy.ops.object.modifier_apply(modifier=bevel.name)
    obj.modifiers.new('Smooth plaque normals', 'WEIGHTED_NORMAL')


def guardian():
    smile()
    ear = material('Cream ears with salmon cups', 'FFE4BF')
    outer = bezier_outline((-.28, .06), [
        ((-.22, .36), (.16, .49), (.57, .37)),
        ((.48, .13), (.29, -.22), (.036, -.23)),
        ((-.21, -.26), (-.28, -.09), (-.28, .06)),
    ], 12)
    inner = bezier_outline((-.15, .085), [
        ((-.09, .27), (.18, .38), (.44, .30)),
        ((.34, .10), (.22, -.133), (.047, -.126)),
        ((-.09, -.127), (-.16, -.057), (-.15, .085)),
    ], 12)
    ear_panel(ear, 'ear-albedo', 'FFE4BF', 'EF9F85', inner)
    ear_dish = (.14, .108)
    ear_center = (1.002, -.56, 2.05)
    pillow('Cream ear R', ear_center, FRONTAL, outer, ear, ear_dish, dish=.10, texture=True)
    pillow('Cream ear L', (-ear_center[0], ear_center[1], ear_center[2]), FRONTAL,
           outer, ear, ear_dish, dish=.10, texture=True, mirror=True)
    wood = material('Warm caramel antler', 'A95926', .38)
    rim = material('Amber bud rim', 'E58423', .36)
    glow = material('Golden bud centre', 'FFB536', .34, .28)
    paint(glow, 'bud-albedo', lambda u, v: mix(color('F18D21'), color('FFE171'),
          np.exp(-4*((u-.45)**2+(v-.48)**2))), 128)
    for s, side in [(1, 'R'), (-1, 'L')]:
        def mirrored_path(rows):
            return [(s*x, y, z, w, d) for x, y, z, w, d in rows]

        main = sweep(f'Branched antler {side}', mirrored_path([
            (.56, -.26, 2.12, 0, 0), (.66, -.24, 2.26, .224, .175),
            (.84, -.22, 2.43, .202, .171), (1.05, -.18, 2.60, .167, .143),
            (1.18, -.19, 2.81, .150, .132), (1.13, -.23, 3.035, .125, .114),
            (1.03, -.32, 3.215, .104, .094), (.99, -.345, 3.28, 0, 0),
        ]), wood, axis=(0, 1, 0), rings=23)
        fork = sweep(f'Antler fork {side}', mirrored_path([
            (.85, -.20, 2.48, 0, 0), (1.00, -.18, 2.50, .151, .148),
            (1.25, -.17, 2.49, .142, .141), (1.48, -.20, 2.55, .131, .122),
            (1.60, -.28, 2.69, .124, .111), (1.62, -.32, 2.775, .090, .082),
            (1.60, -.325, 2.83, 0, 0),
        ]), wood, axis=(0, 1, 0), rings=17)
        bpy.ops.object.select_all(action='DESELECT')
        main.select_set(True)
        fork.select_set(True)
        bpy.context.view_layer.objects.active = main
        bpy.ops.object.join()
        remesh = main.modifiers.new('Continuous branch junction', 'REMESH')
        remesh.mode = 'VOXEL'
        remesh.voxel_size = .036
        remesh.use_smooth_shade = True
        bpy.ops.object.modifier_apply(modifier=remesh.name)
        smoothing = main.modifiers.new('Rounded junction', 'SMOOTH')
        smoothing.factor = .9
        smoothing.iterations = 3
        bpy.ops.object.modifier_apply(modifier=smoothing.name)
        decimate = main.modifiers.new('Antler triangle budget', 'DECIMATE')
        main.data.calc_loop_triangles()
        decimate.ratio = min(1, 1160/len(main.data.loop_triangles))
        bpy.ops.object.modifier_apply(modifier=decimate.name)
        bud_axis = Vector((-s*.37, -.86, .43)).normalized()
        bud_center = Vector((s*1.006, -.329, 3.218))
        rotation = bud_axis.to_track_quat('Z', 'Y').to_euler()
        bud = sphere(f'Amber tip {side}', bud_center, (.133, .17, .093), rim, 16, 10)
        bud.rotation_euler = rotation
        core = sphere(f'Golden inset {side}', bud_center+bud_axis*.071, (.093, .128, .032), glow, 16, 8)
        core.rotation_euler = rotation
        uv_map(core, lambda i, _: (.5+core.data.vertices[i].co.x/.19, .5+core.data.vertices[i].co.y/.26))
    forehead = material('Ivory forehead petals', 'FFF0CE', .42)
    leaf = bezier_outline((0, -.12), [
        ((-.056, -.045), (-.107, .092), (-.059, .143)),
        ((-.019, .189), (.058, .171), (.072, .109)),
        ((.094, .050), (.032, -.055), (0, -.12)),
    ], 6)
    for name, x, z, angle in [('Crown', 0, 1.95, -.13), ('Left', -.164, 1.85, -.60), ('Right', .164, 1.85, .60)]:
        oriented = [np.array((u*math.cos(angle)+v*math.sin(angle), v*math.cos(angle)-u*math.sin(angle))) for u, v in leaf]
        pillow(f'{name} forehead petal', (x, -.996, z), FRONTAL, oriented, forehead, (.027, .02))
    tail = material('Olive tail with cream tip', COAT)
    paint(tail, 'tail-albedo', lambda u, v: mix(color(COAT), color('FFE5C2'),
          smooth(.5+(v-.66-.056*np.cos(2*np.pi*u))/.018)), 256)
    sweep('Upturned cream-tipped tail', [
        (.42, .83, .79, 0, 0), (.47, 1.05, .82, .24, .18),
        (.60, 1.37, .97, .285, .213), (.74, 1.65, 1.17, .233, .174),
        (.84, 1.80, 1.43, .14, .11), (.86, 1.82, 1.61, 0, 0),
    ], tail, steps=18, rings=18, texture=True)


{'BloomFox': fox, 'MoonOwl': owl, 'GroveGuardian': guardian}[NAME]()


FRONT = {
    'BloomFox': ((4.8, -10, 3.75), (.39, .60, 1.50), 4.15),
    'MoonOwl': ((4.9, -10, 3.77), (.01, .12, 1.36), 3.53),
    'GroveGuardian': ((4.3, -10, 3.88), (.02, .14, 1.66), 4.30),
}[NAME]
REAR = ((6.7, 9.6, 4.6), FRONT[1], FRONT[2])


def view_rotation(loc, target):
    return (Vector(target)-Vector(loc)).to_track_quat('-Z', 'Y')


def audit():
    bpy.context.view_layer.update()
    graph = bpy.context.evaluated_depsgraph_get()
    points, parts = [], {}
    for obj in bpy.context.scene.objects:
        if obj.type not in {'MESH', 'CURVE'}:
            continue
        evaluated = obj.evaluated_get(graph)
        geometry = evaluated.to_mesh()
        geometry.calc_loop_triangles()
        assert all(t.area > 1e-12 for t in geometry.loop_triangles), obj.name
        parts[obj.name] = len(geometry.loop_triangles)
        points.extend(evaluated.matrix_world @ v.co for v in geometry.vertices)
        evaluated.to_mesh_clear()
    bounds = [[op(point[i] for point in points) for i in range(3)] for op in (min, max)]
    return {'triangles': sum(parts.values()), 'max_part_triangles': max(parts.values()), 'bounds': bounds, 'parts': parts}


def export():
    bpy.ops.object.select_all(action='DESELECT')
    body.select_set(True)
    bpy.context.view_layer.objects.active = body
    for screen in bpy.data.screens:
        for area in screen.areas:
            if area.type == 'VIEW_3D':
                space = area.spaces.active
                space.region_3d.view_rotation = view_rotation(*FRONT[:2])
                space.region_3d.view_location = FRONT[1]
                space.region_3d.view_distance = FRONT[2]*1.45
                space.region_3d.view_perspective = 'ORTHO'
                space.shading.type = 'MATERIAL'
    bpy.ops.wm.save_as_mainfile(filepath=str(MODEL / (NAME + '.blend')))
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.export_scene.gltf(filepath=str(MODEL / (NAME + '.glb')), export_format='GLB',
                              use_selection=True, export_apply=True, export_animations=False)

    # The FBX exporter filters curves. Use the evaluated mouth only in this export.
    smile = asset.objects.get('Smile')
    if smile:
        graph = bpy.context.evaluated_depsgraph_get()
        geometry = bpy.data.meshes.new_from_object(smile.evaluated_get(graph), depsgraph=graph)
        baked = bpy.data.objects.new('Smile mesh', geometry)
        asset.objects.link(baked)
        baked.parent = root
        baked.matrix_world = smile.matrix_world
        smile.select_set(False)
        baked.select_set(True)
    bpy.ops.export_scene.fbx(filepath=str(MODEL / (NAME + '.fbx')), use_selection=True,
                             global_scale=1, apply_scale_options='FBX_SCALE_UNITS',
                             axis_forward='Z', axis_up='Y', object_types={'MESH', 'EMPTY'},
                             use_triangles=True, bake_anim=False, path_mode='COPY', embed_textures=True)
    if smile:
        bpy.data.objects.remove(baked, do_unlink=True)


def check_exports(source):
    glb = (MODEL / (NAME + '.glb')).read_bytes()
    length = struct.unpack_from('<I', glb, 12)[0]
    header = json.loads(glb[20:20+length])
    assert not any(item.get('uri') for group in ('buffers', 'images') for item in header.get(group, []))
    reports, scenes = {}, {}
    for ext in ('blend', 'glb', 'fbx'):
        check = bpy.data.scenes.new('Roundtrip ' + ext)
        bpy.context.window.scene = check
        with tempfile.TemporaryDirectory(dir=WORK) as isolated:
            path = shutil.copy2(MODEL / (NAME + '.' + ext), isolated)
            if ext == 'blend':
                with bpy.data.libraries.load(path, link=False) as (available, loaded):
                    assert available.scenes == [NAME]
                    loaded.collections = [NAME + '_Asset']
                check.collection.children.link(loaded.collections[0])
            elif ext == 'glb':
                bpy.ops.import_scene.gltf(filepath=path, import_pack_images=True)
            else:
                bpy.ops.import_scene.fbx(filepath=path)
        measured = audit()
        delta = max(abs(a-b) for u, v in zip(measured['bounds'], source['bounds']) for a, b in zip(u, v))
        assert delta < .006, (ext, delta)
        assert measured['triangles'] == source['triangles'], (ext, measured, source)
        assert not any(o.type in {'LIGHT', 'CAMERA'} for o in check.objects)
        missing = [name for name in source['parts'] if not any(o.name.startswith(name) for o in check.objects)]
        assert not missing, (ext, missing)
        mats = {m for o in check.objects if o.type in {'MESH', 'CURVE'} for m in o.data.materials if m}
        images = {n.image for m in mats if m.use_nodes for n in m.node_tree.nodes if n.type == 'TEX_IMAGE' and n.image}
        expected = {'BloomFox': 4, 'MoonOwl': 3, 'GroveGuardian': 5}[NAME]
        assert len(images) == expected and all(im.packed_file for im in images), (ext, images)
        reports[ext] = {'triangles': measured['triangles'], 'bounds_error': delta, 'packed_images': len(images)}
        scenes[ext] = check
        bpy.context.window.scene = scene
    return reports, scenes


def stage_preview():
    preview = bpy.data.scenes.new('Preview')
    preview.collection.children.link(asset)
    bpy.context.window.scene = preview
    world = bpy.data.worlds.new('Neutral soft fill')
    world.use_nodes = True
    world.node_tree.nodes['Background'].inputs[0].default_value = (.96, .97, 1, 1)
    world.node_tree.nodes['Background'].inputs[1].default_value = .38
    preview.world = world
    backdrop = material('Sage backdrop', 'C4D0AF', .9, .28)
    bpy.ops.mesh.primitive_plane_add(size=100, location=(0, 0, -.006))
    bpy.context.object.data.materials.append(backdrop)
    for name, loc, energy, size in [
        ('Softbox key', (-3.9, -4.5, 6.6), 420, 5.0),
        ('Softbox fill', (4.2, -3.6, 4.6), 185, 4.4),
        ('Softbox rim', (1.6, 4.4, 5.7), 275, 4.5),
    ]:
        light = bpy.data.lights.new(name, 'AREA')
        light.energy, light.size = energy, size
        obj = bpy.data.objects.new(name, light)
        preview.collection.objects.link(obj)
        obj.location = loc
        obj.rotation_euler = view_rotation(loc, (0, .5, 1.4)).to_euler()
    camera = bpy.data.objects.new('Review camera', bpy.data.cameras.new('Review camera'))
    preview.collection.objects.link(camera)
    camera.data.type = 'ORTHO'
    return preview, camera


def render(view, camera, shot, filename, size, samples):
    loc, target, scale = shot
    camera.location = loc
    camera.rotation_euler = view_rotation(loc, target).to_euler()
    camera.data.ortho_scale = scale
    view.camera = camera
    view.render.engine = 'CYCLES'
    view.cycles.samples = samples
    view.cycles.use_denoising = True
    view.render.resolution_x = view.render.resolution_y = size
    view.render.resolution_percentage = 100
    view.render.image_settings.file_format = 'PNG'
    view.view_settings.view_transform = 'Standard'
    view.view_settings.look = 'None'
    view.render.filepath = str(WORK / filename)
    bpy.ops.render.render(write_still=True, scene=view.name)


source = audit()
print('MODEL_AUDIT', NAME, json.dumps(source), flush=True)
assert source['triangles'] < 10000
assert abs(source['bounds'][0][2]) < .003
source['front'] = '-Y'
if not DRAFT:
    export()
    source['imports'], validation_scenes = check_exports(source)
    (WORK / 'verification.json').write_text(json.dumps(source, indent=2)+'\n', encoding='utf-8')

preview, camera = stage_preview()
if DRAFT:
    render(preview, camera, FRONT, 'draft-front.png', 520, 12)
    render(preview, camera, REAR, 'draft-rear.png', 520, 12)
else:
    render(preview, camera, FRONT, 'front-three-quarter.png', 800, 36)
    render(preview, camera, REAR, 'rear-three-quarter.png', 800, 36)
    for ext, check in validation_scenes.items():
        for obj in preview.objects:
            if obj.name not in asset.objects:
                check.collection.objects.link(obj)
        check.world = preview.world
        render(check, camera, FRONT, f'roundtrip-{ext}.png', 480, 16)
