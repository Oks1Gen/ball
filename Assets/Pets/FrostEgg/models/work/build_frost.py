"""Build the five Frost Egg pets and render the headless review views."""

import argparse
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
from bpy_extras.object_utils import world_to_camera_view
from mathutils import Vector


MODELS = Path(__file__).resolve().parents[1]
SPECS = {
    'SnowPup': ('Snow Pup', 'F5DEBA', 'F5DEBA', 'EAB676', 'blue', .43, 1.12, .283, .285),
    'SnowyPenguin': ('Snowy Penguin', '2643A3', 'FFF1D9', 'FF8907', 'amber', .425, 1.18, .265, .275),
    'GlacierWalrus': ('Glacier Walrus', '16ADB9', '74E2E9', '078F9F', 'blue', .438, 1.31, .289, .287),
    'AuroraLynx': ('Aurora Lynx', '805ADB', 'FFDFB5', '7048C5', 'teal', .425, 1.14, .273, .277),
    'GlacierDragon': ('Glacier Dragon', '2B9EDC', '97E1FC', '177BAE', 'violet', .420, 1.12, .258, .270),
}
FRONT_AXES = ((1, 0, 0), (0, 0, 1))


def rgb(code):
    return tuple(int(code[i:i+2], 16) for i in (0, 2, 4))


def linear(v):
    v /= 255
    return v/12.92 if v < .04045 else ((v+.055)/1.055)**2.4


def smooth(t):
    t = np.clip(t, 0, 1)
    return t*t*(3-2*t)


def blend(a, b, amount):
    return np.asarray(a) + (np.asarray(b)-a)*np.asarray(amount)[..., None]


def material(name, code, roughness=.40):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    rgba = (*map(linear, rgb(code)), 1)
    shader = mat.node_tree.nodes.get('Principled BSDF')
    shader.inputs['Base Color'].default_value = rgba
    shader.inputs['Roughness'].default_value = roughness
    mat.diffuse_color = rgba
    mat['sRGB'] = '#' + code
    return mat


def bezier(start, segments, steps=9):
    result = []
    p = np.asarray(start)
    for a, b, q in (map(np.asarray, row) for row in segments):
        for i in range(steps):
            t = i/steps
            s = 1-t
            result.append(s**3*p+3*s*s*t*a+3*s*t*t*b+t**3*q)
        p = q
    return result


def distance_to_outline(x, y, outline):
    distance = np.full(x.shape, 100.0)
    inside = np.zeros(x.shape, dtype=bool)
    for a, b in zip(outline, outline[1:]+outline[:1]):
        dx, dy = b-a
        t = np.clip(((x-a[0])*dx+(y-a[1])*dy)/(dx*dx+dy*dy), 0, 1)
        distance = np.minimum(distance, (x-a[0]-t*dx)**2+(y-a[1]-t*dy)**2)
        if abs(dy) > 1e-8:
            inside ^= ((a[1] > y) != (b[1] > y)) & (x < a[0]+(y-a[1])*dx/dy)
    return np.where(inside, 1, -1)*np.sqrt(distance)


def caps_and_rings(steps, rings):
    faces = [(0, 1+j, 1+(j+1)%steps) for j in range(steps)]
    for i in range(rings-1):
        a, b = 1+i*steps, 1+(i+1)*steps
        faces.extend((a+j, b+j, b+(j+1)%steps, a+(j+1)%steps) for j in range(steps))
    a = 1+(rings-1)*steps
    faces.extend((a+j, 1+rings*steps, a+(j+1)%steps) for j in range(steps))
    return faces


def catmull(points, t):
    k = min(len(points)-2, int(t))
    a, b = points[k:k+2]
    p = points[k-1] if k else 2*a-b
    q = points[k+2] if k+2 < len(points) else 2*b-a
    u = t-k
    return a+.5*u*(b-p+u*(2*p-5*a+4*b-q+u*(3*a-3*b+q-p)))


def uv_map(obj, project):
    for layer in list(obj.data.uv_layers):
        obj.data.uv_layers.remove(layer)
    uv = obj.data.uv_layers.new(name='UVMap')
    for face in obj.data.polygons:
        for li in face.loop_indices:
            uv.data[li].uv = project(obj.data.loops[li].vertex_index, face)


class Pet:
    def __init__(self, name):
        self.name = name
        self.label, self.coat, self.cream, self.feet, self.eye_tint, self.eye_x, self.eye_z, self.eye_w, self.eye_h = SPECS[name]
        self.work = MODELS / name / 'v1' / 'work'
        self.output = self.work.parent / 'model'
        self.work.mkdir(parents=True, exist_ok=True)
        self.output.mkdir(exist_ok=True)
        bpy.ops.wm.read_factory_settings(use_empty=True)
        bpy.context.preferences.filepaths.save_version = 0
        self.scene = bpy.context.scene
        self.scene.name = name
        self.collection = bpy.data.collections.new(name + '_Asset')
        self.scene.collection.children.link(self.collection)
        self.root = bpy.data.objects.new(name, None)
        self.collection.objects.link(self.root)
        self.root['Reference'] = 'Frost Egg / ' + self.label
        self.root['Front'] = '-Y'

    def paint(self, mat, label, pixels, size=512):
        u, v = np.meshgrid((np.arange(size)+.5)/size, 1-(np.arange(size)+.5)/size)
        array = np.rint(pixels(u, v)).clip(0, 255).astype('uint8')
        data = b''.join(b'\0'+row.tobytes() for row in array)

        def chunk(tag, body):
            return struct.pack('>I', len(body))+tag+body+struct.pack('>I', zlib.crc32(tag+body))

        path = self.work / (label + '.png')
        path.write_bytes(
            b'\x89PNG\r\n\x1a\n'
            + chunk(b'IHDR', struct.pack('>IIBBBBB', size, size, 8, 2, 0, 0, 0))
            + chunk(b'IDAT', zlib.compress(data, 8)) + chunk(b'IEND', b'')
        )
        image = bpy.data.images.load(str(path), check_existing=False)
        image.pack()
        tex = mat.node_tree.nodes.new('ShaderNodeTexImage')
        tex.image = image
        tex.extension = 'EXTEND'
        mat.node_tree.links.new(tex.outputs['Color'], mat.node_tree.nodes.get('Principled BSDF').inputs['Base Color'])

    def mesh(self, name, vertices, faces, mat):
        data = bpy.data.meshes.new(name)
        data.from_pydata(vertices, [], faces)
        bm = bmesh.new()
        bm.from_mesh(data)
        bmesh.ops.recalc_face_normals(bm, faces=list(bm.faces))
        bm.to_mesh(data)
        bm.free()
        data.update()
        obj = bpy.data.objects.new(name, data)
        self.collection.objects.link(obj)
        return self.attach(obj, name, mat)

    def attach(self, obj, name, mat):
        if self.collection not in obj.users_collection:
            self.collection.objects.link(obj)
            for collection in tuple(obj.users_collection):
                if collection != self.collection:
                    collection.objects.unlink(obj)
        obj.name = name
        obj.parent = self.root
        obj.data.materials.append(mat)
        for face in obj.data.polygons:
            face.use_smooth = True
        return obj

    def sphere(self, name, loc, scale, mat, sides=18, rings=10):
        bpy.ops.mesh.primitive_uv_sphere_add(segments=sides, ring_count=rings, location=loc)
        obj = self.attach(bpy.context.object, name, mat)
        obj.scale = scale
        bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
        return obj

    def pillow(self, name, loc, axes, outline, mat, depth, mirror=False, dish=0, map_mode=None):
        h, v = map(Vector, axes)
        normal = h.cross(v).normalized()
        center = Vector(loc)
        focal = np.mean(outline, axis=0)
        coords, uv = [], []

        def point(x, z, d):
            coords.append(center+h*(-x if mirror else x)+v*z+normal*d)
            uv.append((x, z))

        point(*focal, depth[0]-dish)
        rings = [.25, .53, .76, .91, 1, .91, .68, .36]
        for i, radius in enumerate(rings):
            dome = math.sqrt(max(0, 1-radius**2))
            d = depth[0]*dome-dish*math.exp(-4*radius**2) if i < 4 else -depth[1]*dome
            for xy in outline:
                point(*(focal+radius*(xy-focal)), d)
        point(*focal, -depth[1])
        obj = self.mesh(name, coords, caps_and_rings(len(outline), len(rings)), mat)
        if map_mode:
            uv_map(obj, lambda i, face: map_mode(*uv[i], face.normal.dot(normal)))
        return obj

    def sweep(self, name, stations, mat, axis=(1, 0, 0), sides=22, rings=21, texture=False):
        path = np.array(stations)
        end = len(stations)-1
        coords = [path[0, :3]]
        uvs = [(.5, 0)]
        for i in range(1, rings+1):
            t = end*i/(rings+1)
            x, y, z, width, depth = catmull(path, t)
            tangent = Vector(catmull(path, t+.001)[:3]-catmull(path, t-.001)[:3]).normalized()
            other = Vector(axis).cross(tangent).normalized()
            along = tangent.cross(other)
            for j in range(sides):
                a = 2*math.pi*j/sides
                coords.append(Vector((x, y, z))+along*max(.003, width)*math.cos(a)+other*max(.003, depth)*math.sin(a))
                uvs.append((j/sides, i/(rings+1)))
        coords.append(path[-1, :3])
        uvs.append((.5, 1))
        obj = self.mesh(name, coords, caps_and_rings(sides, rings), mat)
        if texture:
            def project(i, face):
                u, v = uvs[i]
                ring = [uvs[j][0] for j in face.vertices if j not in (0, len(uvs)-1)]
                if max(ring)-min(ring) > .5:
                    ring = [s+1 if s < .5 else s for s in ring]
                    u = u+1 if u < .5 else u
                return (sum(ring)/len(ring) if i in (0, len(uvs)-1) else u, v)
            uv_map(obj, project)
        return obj

    def body(self):
        coat = material('Painted body', self.coat)
        cream = rgb(self.cream)
        is_penguin = self.name == 'SnowyPenguin'
        is_lynx = self.name == 'AuroraLynx'
        is_dragon = self.name == 'GlacierDragon'
        is_walrus = self.name == 'GlacierWalrus'
        if is_penguin or is_lynx or is_dragon:
            top = 1.82 if is_penguin else 1.71 if is_lynx else 1.64
            dip = 1.52 if is_penguin else 1.37 if is_lynx else 1.25
            base = .30 if is_penguin else .34
            outline = bezier((0, dip), [
                ((-.29, top+.14), (-.72, top+.11), (-.86, top-.18)),
                ((-.97, top-.39), (-.94, .72), (-.87, .57)),
                ((-.78, .35), (-.59, base), (0, base)),
                ((.59, base), (.78, .35), (.87, .57)),
                ((.94, .72), (.97, top-.39), (.86, top-.18)),
                ((.72, top+.11), (.29, top+.14), (0, dip)),
            ], 13)

        def pixels(u, v):
            x, z = 2*(2*u % 1)-1, .24+2*v
            solid = rgb(self.coat)
            front = np.broadcast_to(np.asarray(solid), (*x.shape, 3))
            side = front
            if is_penguin or is_lynx or is_dragon:
                mask = smooth(.5+distance_to_outline(x, z, outline)/.012)
                front = blend(solid, cream, mask)
            if is_walrus:
                muzzle = 1-((np.abs(x)-.236)/.48)**2-((z-.99)/.20)**2
                front = blend(solid, cream, .78*smooth((muzzle+.18)/.82))
            blush_z = .82 if not is_walrus else .97
            blush = ((np.abs(x)-.657)/.157)**2+((z-blush_z)/.137)**2
            front = blend(front, rgb('FF5F8B'), .88*np.exp(-1.4*blush))
            if is_walrus:
                dot = ((np.abs(x)-.691)/.029)**2+((z-.99)/.031)**2
                front = blend(front, rgb('73465A'), smooth((1.12-dot)/.36))
            if is_lynx:
                spots = np.zeros(x.shape)
                for y, height, rx, rz in [(-.40, 1.40, .088, .144), (-.15, 1.13, .090, .137), (.08, 1.52, .088, .147)]:
                    spots = np.maximum(spots, smooth((1.04-((x-y)/rx)**2-((z-height)/rz)**2)/.13))
                side = blend(solid, rgb('5434A8'), spots)
            return np.where((u < .5)[..., None], front, side)

        self.paint(coat, 'body-albedo', pixels)
        bpy.ops.mesh.primitive_cube_add(size=2, location=(0, 0, 1.24))
        body = self.attach(bpy.context.object, 'Square body', coat)
        bevel = body.modifiers.new('Soft square edges', 'BEVEL')
        bevel.width, bevel.segments = .235, 7
        bpy.ops.object.modifier_apply(modifier=bevel.name)
        normal = body.modifiers.new('Flat face normals', 'WEIGHTED_NORMAL')
        normal.keep_sharp = True

        def project(i, face):
            x, y, z = body.data.vertices[i].co
            if face.normal.y < -.18:
                return (.25+.243*x, (z+1)*.5)
            if abs(face.normal.x) > .65:
                return (.75+.243*y, (z+1)*.5)
            return (.98, .97)

        uv_map(body, project)
        return body

    def paws(self, width, length, height):
        mat = material('Paw colour', self.feet)
        outline = bezier((-.94, -.17), [
            ((-.96, -.73), (-.86, -1.11), (-.63, -1.10)),
            ((-.50, -1.12), (-.40, -.76), (-.34, -.93)),
            ((-.25, -1.17), (.23, -1.17), (.34, -.93)),
            ((.40, -.76), (.50, -1.12), (.63, -1.10)),
            ((.86, -1.11), (.96, -.73), (.94, -.17)),
            ((1.02, .59), (.63, .91), (0, .92)),
            ((-.63, .91), (-1.02, .59), (-.94, -.17)),
        ], 4)
        for s, side in [(-1, 'left'), (1, 'right')]:
            for y, end in [(-.64, 'front'), (.61, 'rear')]:
                shape = [np.array((x*width/2, v*length/2)) for x, v in outline]
                self.pillow(f'{end} {side} paw', (s*.61, y, height/2), ((1, 0, 0), (0, 1, 0)),
                            shape, mat, (height/2, height/2))

    def eyes(self):
        palette = {
            'blue': ('16D8FF', '0F63B5', '052544'),
            'amber': ('FFC329', 'A65106', '3C1C06'),
            'teal': ('11E6C4', '067A81', '042C38'),
            'violet': ('BA4DFF', '7B23C5', '290751'),
            'green': ('A5F51A', '4A9907', '163405'),
        }
        lower, upper, pupil = map(rgb, palette[self.eye_tint])
        mat = material('Glossy iris and catchlights', 'FFF8F3', .26)
        mat.node_tree.nodes.get('Principled BSDF').inputs['Specular IOR Level'].default_value = .25

        def pixels(u, v):
            x, z = 2*u-1, 2*v-1
            r = np.hypot((x-.014)/.862, (z+.034)/.894)
            iris = blend(lower, upper, smooth((z+.78)/1.50))
            p = ((x+.008)/.710)**2+((z-.123)/.680)**2
            pupil_tone = blend(pupil, upper, .27*smooth((.39-z)/1.03))
            iris = blend(iris, pupil_tone, smooth((1.035-p)/.28))
            iris = blend(iris, upper, .24*smooth((r-.92)/.10))
            large = smooth((.221-np.hypot(x+.270, z-.454))/.030)
            small = .75*smooth((.071-np.hypot(x-.408, z+.392))/.028)
            iris = blend(iris, rgb('FFFFFF'), np.maximum(large, small))
            return blend(rgb('FFF8F3'), iris, smooth((1.008-r)/.017))

        self.paint(mat, 'iris-albedo', pixels, 256)
        for s, label in [(-1, 'left'), (1, 'right')]:
            center = s*self.eye_x
            vertices, uv = [(center, -1.075, self.eye_z)], [(.5, .5)]
            for i in range(1, 8):
                r = i/7
                for j in range(30):
                    angle = 2*math.pi*j/30
                    x, z = r*math.cos(angle), r*math.sin(angle)
                    vertices.append((center+self.eye_w*x, -1.008-.067*math.sqrt(1-r*r), self.eye_z+self.eye_h*z))
                    uv.append((.5+.495*x, .5+.495*z))
            vertices.append((center, -.985, self.eye_z))
            uv.append((.5, .5))
            obj = self.mesh(f'{label} glossy eye', vertices, caps_and_rings(30, 7), mat)
            uv_map(obj, lambda i, _: uv[i])

    def smile(self, height, nose=True):
        ink = material('Warm charcoal smile', '433B36', .44)
        for s, label in [(-1, 'left'), (1, 'right')]:
            self.sweep(f'{label} smile curl', [
                (0, -1.022, height+.064, 0, 0), (s*.033, -1.026, height+.009, .021, .018),
                (s*.084, -1.023, height-.023, .021, .019), (s*.138, -1.018, height-.003, .020, .018),
                (s*.171, -1.015, height+.036, 0, 0),
            ], ink, axis=(0, 1, 0), sides=10, rings=10)
        if nose:
            self.sphere('Soft charcoal nose', (0, -1.038, height+.137), (.095, .064, .059), ink)

    def snow_pup(self):
        ears = material('Sky blue floppy ears', '278BEF', .36)
        flap = bezier((-.315, .095), [
            ((-.356, .231), (-.171, .365), (.056, .361)),
            ((.315, .358), (.606, .161), (.743, -.109)),
            ((.861, -.339), (.726, -.489), (.544, -.503)),
            ((.353, -.512), (.157, -.355), (.028, -.204)),
            ((-.081, -.082), (-.263, -.041), (-.315, .095)),
        ], 10)
        for s, label in [(-1, 'left'), (1, 'right')]:
            z = 2.13 if s == 1 else 2.20
            ear = self.pillow(f'{label} floppy ear', (s*.515, -.555, z), FRONT_AXES, flap, ears,
                              (.208, .163), mirror=s == -1)
            for vertex in ear.data.vertices:
                droop = smooth((2.50-vertex.co.z)/.46)
                tuck = smooth((.58-abs(vertex.co.x))/.30)
                vertex.co.y += .135-.73*float(droop)+.13*float(tuck)
            ear.data.update()
        tail = material('Ivory curl', 'F3D4A8')
        self.sweep('Curled plush tail', [
            (.68, .78, 1.19, 0, 0), (.75, 1.17, 1.21, .222, .207),
            (.84, 1.58, 1.35, .257, .236), (.87, 1.85, 1.58, .241, .216),
            (.88, 1.84, 1.86, .214, .197), (.89, 1.62, 2.01, .196, .179),
            (.90, 1.43, 1.875, .164, .146), (.91, 1.48, 1.68, .106, .097),
            (.92, 1.64, 1.66, 0, 0),
        ], tail, rings=32).location.z -= .365
        self.smile(.845)

    def snowy_penguin(self):
        wing = material('Royal blue flippers', '2F54C1', .39)
        self.flippers(wing, 1.28, False)
        beak = material('Golden orange beak', 'FFAE0A', .31)
        shape = bezier((-.161, .046), [
            ((-.143, .111), (.100, .141), (.154, .052)),
            ((.173, -.014), (.066, -.102), (.015, -.160)),
            ((-.023, -.186), (-.156, -.051), (-.161, .046)),
        ], 10)
        self.pillow('Soft triangular beak', (0, -1.040, .963), FRONT_AXES, shape, beak, (.162, .039))

    def flippers(self, mat, z, broad):
        if broad:
            shape = bezier((-.11, .079), [
                ((.078, .239), (.311, .167), (.551, -.011)),
                ((.745, -.141), (.839, -.300), (.701, -.401)),
                ((.565, -.488), (.264, -.398), (.074, -.273)),
                ((-.063, -.174), (-.159, -.026), (-.11, .079)),
            ], 10)
        else:
            shape = bezier((-.105, .058), [
                ((.005, .278), (.219, .190), (.403, -.024)),
                ((.574, -.229), (.687, -.553), (.561, -.638)),
                ((.433, -.725), (.228, -.532), (.089, -.367)),
                ((-.025, -.252), (-.157, -.057), (-.105, .058)),
            ], 10)
        for s, label in [(-1, 'left'), (1, 'right')]:
            fin = self.pillow(f'{label} flipper', (s*.914, -.307, z), FRONT_AXES, shape, mat,
                              (.178, .231), mirror=s == -1)
            for vertex in fin.data.vertices:
                vertex.co.y += .19*(abs(vertex.co.x)-.91)
            fin.data.update()

    def glacier_walrus(self):
        fin = material('Turquoise flippers', '23BCC7')
        self.flippers(fin, 1.01, True)
        ivory = material('Ivory tusks', 'FFE1AD', .32)
        for s, label in [(-1, 'left'), (1, 'right')]:
            self.sweep(f'{label} tapered tusk', [
                (s*.353, -.970, 1.049, 0, 0), (s*.354, -1.040, .984, .152, .100),
                (s*.356, -1.083, .858, .139, .101), (s*.338, -1.109, .654, .112, .086),
                (s*.319, -1.111, .461, .076, .063), (s*.304, -1.103, .368, .046, .039),
                (s*.299, -1.090, .332, 0, 0),
            ], ivory, rings=23, sides=20)
        self.smile(.997)

    def aurora_lynx(self):
        outer = bezier((-.342, -.12), [
            ((-.42, .13), (-.37, .55), (-.22, .78)),
            ((-.17, .89), (-.11, .88), (-.04, .82)),
            ((.21, .65), (.34, .33), (.40, .07)),
            ((.23, -.07), (-.12, -.145), (-.342, -.12)),
        ])
        inner = bezier((-.25, -.055), [
            ((-.29, .15), (-.25, .47), (-.135, .63)),
            ((-.082, .72), (.09, .52), (.21, .04)),
            ((.13, -.056), (-.10, -.08), (-.25, -.055)),
        ], 11)
        ears = material('Violet ears with cream inset', '6B48C9')
        self.paint(ears, 'ear-albedo', lambda u, v: blend(
            rgb('6B48C9'), rgb('FFDEA9'), smooth(.5+distance_to_outline(2*u-1, 2*v-1, inner)/.016)), 256)
        tufts = material('Glacial turquoise ear tufts', '16E3D1', .35)
        tuft = bezier((-.171, -.16), [
            ((-.255, -.04), (-.292, .115), (-.234, .173)),
            ((-.216, .197), (-.185, .105), (-.157, .108)),
            ((-.166, .209), (-.10, .317), (-.057, .303)),
            ((-.017, .278), (.006, .181), (.048, .145)),
            ((.124, .093), (.220, .032), (.238, -.076)),
            ((.278, -.196), (-.035, -.222), (-.171, -.16)),
        ], 7)
        for s, label in [(-1, 'left'), (1, 'right')]:
            self.pillow(f'{label} lynx ear', (s*.668, -.45, 2.098), FRONT_AXES,
                        [np.array((x*1.07, z)) for x, z in outer], ears, (.145, .149),
                        mirror=s == 1, dish=.024,
                        map_mode=lambda x, z, facing: ((x/1.07+1)*.5, (z+1)*.5) if facing > .045 else (.98, .98))
            self.pillow(f'{label} aqua tuft', (s*.76, -.516, 2.76), FRONT_AXES, tuft, tufts, (.126, .098), mirror=s == 1)
        tail = material('Violet tail with aurora tip', '6544CB')

        def pixels(u, v):
            edge = .65+.058*np.cos(2*np.pi*(u*3+.10))+.025*np.cos(2*np.pi*u)
            return blend(rgb('6544CB'), rgb('16E3D1'), smooth(.5+(v-edge)/.015))

        self.paint(tail, 'tail-albedo', pixels, 256)
        self.sweep('Plush aurora tail', [
            (.42, .82, .65, 0, 0), (.57, 1.10, .72, .193, .186),
            (.73, 1.43, .84, .309, .256), (.88, 1.67, 1.11, .371, .295),
            (.96, 1.77, 1.44, .330, .271), (1.03, 1.81, 1.71, .244, .189),
            (1.06, 1.84, 1.895, .136, .114), (1.075, 1.85, 1.956, 0, 0),
        ], tail, rings=27, texture=True)
        self.smile(.839)

    def glacier_dragon(self):
        horn = material('Glacial horn', '5EDBF7', .31)
        for s, label in [(-1, 'left'), (1, 'right')]:
            self.sweep(f'{label} swept ice horn', [
                (s*.464, -.56, 2.10, 0, 0), (s*.47, -.53, 2.244, .299, .222),
                (s*.47+.016, -.435, 2.417, .277, .196), (s*.47+.049, -.222, 2.591, .216, .151),
                (s*.47+.095, .083, 2.710, .152, .109), (s*.47+.15, .381, 2.798, .089, .063),
                (s*.47+.186, .62, 2.956, 0, 0),
            ], horn, rings=22, sides=18)
        self.dragon_wings()
        tail = material('Glacial blue tail', '2393D6')
        self.sweep('Upturned tail stem', [
            (.39, .76, .51, 0, 0), (.51, 1.01, .57, .194, .184),
            (.72, 1.25, .62, .255, .217), (.99, 1.39, .70, .226, .186),
            (1.18, 1.43, .82, .169, .142), (1.31, 1.44, 1.01, .118, .097),
            (1.35, 1.44, 1.12, 0, 0),
        ], tail, rings=22)
        tip = material('Ice spade tail tip', '48DFF4', .31)
        shape = bezier((-.283, -.009), [
            ((-.293, .114), (.021, .175), (.248, .336)),
            ((.324, .393), (.330, .271), (.311, .111)),
            ((.291, -.079), (.188, -.273), (.071, -.256)),
            ((-.026, -.235), (-.035, -.132), (-.034, -.082)),
            ((-.124, -.102), (-.234, -.103), (-.283, -.009)),
        ], 7)
        self.pillow('Curved ice spade', (1.40, 1.47, 1.06), FRONT_AXES, shape, tip, (.127, .109))
        self.smile(.825, nose=False)

    def dragon_wings(self):
        profile = np.array([
            (-.12, -.13, -.13), (.05, .57, -.29), (.22, .933, -.391),
            (.39, .995, -.228), (.56, .946, -.139), (.73, .864, -.165),
            (.90, .758, -.258), (1.07, .631, -.31), (1.24, .482, -.088),
            (1.41, .315, .018), (1.58, .137, .057), (1.64, .073, .073),
        ])
        steps = 40
        stations = [catmull(profile, (len(profile)-1)*i/steps) for i in range(steps+1)]
        outline = [np.array((x, top)) for x, top, _ in stations]
        outline += [np.array((x, low)) for x, _, low in reversed(stations[1:-1])]
        membrane = material('Icy wing membrane', '198FEE', .37)

        def pixels(u, v):
            x, z = -.22+2.0*u, -.58+1.74*v
            d = distance_to_outline(x, z, outline)
            interior = blend(rgb('44DEF6'), rgb('167EE9'), smooth((z+.28)/1.24))
            ribs = (.20*np.exp(-((x-(.40+.48*(.85-z)))/.075)**2)
                    + .12*np.exp(-((x-(.22+.14*(.85-z)))/.073)**2))
            interior = blend(interior, rgb('64DAFA'), np.clip(ribs, 0, .29))
            return blend(rgb('6CE3FA'), interior, smooth(d/.114))

        self.paint(membrane, 'wing-albedo', pixels)
        trim = material('Rounded icy leading edge', '55D9F5', .34)
        for s, label in [(-1, 'left'), (1, 'right')]:
            center = (s*.766, .44, 1.594)

            def world(x, z, depth=0):
                return (center[0]+s*.969*x, center[1]+.247*x+depth, center[2]+z)

            sides, rings = 14, 30
            verts, uv = [], []

            def point(x, z, depth=0):
                verts.append(world(x, z, depth))
                uv.append(((x+.22)/2, (z+.58)/1.74))

            point(*profile[0, :2])
            for i in range(1, rings+1):
                x, hi, lo = catmull(profile, (len(profile)-1)*i/(rings+1))
                assert hi > lo, 'Wing sections must taper without folding over'
                for j in range(sides):
                    angle = 2*math.pi*j/sides
                    z = (hi+lo)/2+math.sin(angle)*(hi-lo)/2
                    point(x, z, math.cos(angle)*min(.093, (hi-lo)*.24))
            point(*profile[-1, :2])
            wing = self.mesh(f'{label} scalloped ice wing', verts, caps_and_rings(sides, rings), membrane)
            uv_map(wing, lambda i, _: uv[i])
            radii = [0, .068, .097, .096, .086, .077, .068, .058, .048, .036, .018, 0]
            edge = [(*world(x, z-.025), r, r) for (x, z, _), r in zip(profile, radii)]
            self.sweep(f'{label} frosted wing leading edge', edge, trim, axis=(0, 1, 0), sides=13, rings=22)

    def build(self):
        body = self.body()
        self.paws(*{
            'SnowPup': (.47, .48, .30), 'SnowyPenguin': (.55, .50, .28),
            'GlacierWalrus': (.63, .52, .28), 'AuroraLynx': (.45, .48, .28),
            'GlacierDragon': (.46, .48, .28),
        }[self.name])
        self.eyes()
        {
            'SnowPup': self.snow_pup, 'SnowyPenguin': self.snowy_penguin,
            'GlacierWalrus': self.glacier_walrus, 'AuroraLynx': self.aurora_lynx,
            'GlacierDragon': self.glacier_dragon,
        }[self.name]()
        return body


def audit(objects):
    bpy.context.view_layer.update()
    graph = bpy.context.evaluated_depsgraph_get()
    points, parts = [], {}
    for obj in objects:
        if obj.type != 'MESH':
            continue
        evaluated = obj.evaluated_get(graph)
        data = evaluated.to_mesh()
        data.calc_loop_triangles()
        assert all(tri.area > 1e-12 for tri in data.loop_triangles), obj.name
        parts[obj.name] = len(data.loop_triangles)
        points.extend(evaluated.matrix_world @ v.co for v in data.vertices)
        evaluated.to_mesh_clear()
    bounds = [[op(p[i] for p in points) for i in range(3)] for op in (min, max)]
    return {'triangles': sum(parts.values()), 'largestPart': max(parts.values()), 'bounds': bounds, 'parts': parts}


def aim(obj, target):
    obj.rotation_euler = (Vector(target)-obj.location).to_track_quat('-Z', 'Y').to_euler()


def export(pet, body, expected):
    bpy.ops.object.select_all(action='DESELECT')
    body.select_set(True)
    bpy.context.view_layer.objects.active = body
    view = (Vector((0, .22, 1.43))-Vector((4.6, -10.4, 3.73))).to_track_quat('-Z', 'Y')
    for screen in bpy.data.screens:
        for area in screen.areas:
            if area.type == 'VIEW_3D':
                space = area.spaces.active
                space.region_3d.view_rotation = view
                space.region_3d.view_location = (0, .22, 1.43)
                space.region_3d.view_distance = 5.6
                space.region_3d.view_perspective = 'ORTHO'
                space.shading.type = 'MATERIAL'
    paths = {ext: pet.output / f'{pet.name}.{ext}' for ext in ('blend', 'glb', 'fbx')}
    bpy.ops.wm.save_as_mainfile(filepath=str(paths['blend']))
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.export_scene.gltf(filepath=str(paths['glb']), export_format='GLB', use_selection=True,
                              export_apply=True, export_animations=False)
    bpy.ops.export_scene.fbx(filepath=str(paths['fbx']), use_selection=True, global_scale=1,
                             apply_scale_options='FBX_SCALE_UNITS', axis_forward='Z', axis_up='Y',
                             object_types={'MESH', 'EMPTY'}, use_triangles=True, bake_anim=False,
                             path_mode='COPY', embed_textures=True)
    raw = paths['glb'].read_bytes()
    size = struct.unpack_from('<I', raw, 12)[0]
    header = json.loads(raw[20:20+size])
    assert not any(item.get('uri') for key in ('buffers', 'images') for item in header.get(key, []))

    def textures(objects):
        mats = {m for o in objects if o.type == 'MESH' for m in o.data.materials}
        return {n.image for m in mats if m.use_nodes for n in m.node_tree.nodes if n.type == 'TEX_IMAGE' and n.image}

    count = len(textures(pet.collection.objects))
    reports, imported = {}, {}
    for ext, path in paths.items():
        check = bpy.data.scenes.new('Roundtrip ' + ext)
        bpy.context.window.scene = check
        with tempfile.TemporaryDirectory(dir=pet.work) as isolated:
            copy = shutil.copy2(path, isolated)
            if ext == 'blend':
                with bpy.data.libraries.load(copy, link=False) as (available, loaded):
                    assert available.scenes == [pet.name]
                    loaded.collections = [pet.collection.name]
                check.collection.children.link(loaded.collections[0])
            elif ext == 'glb':
                bpy.ops.import_scene.gltf(filepath=copy, import_pack_images=True)
            else:
                bpy.ops.import_scene.fbx(filepath=copy)
        got = audit(check.objects)
        delta = max(abs(a-b) for u, v in zip(got['bounds'], expected['bounds']) for a, b in zip(u, v))
        images = textures(check.objects)
        assert delta < .006 and got['triangles'] == expected['triangles'], (ext, delta, got['triangles'])
        assert len(images) == count and all(img.packed_file for img in images), (ext, [im.name for im in images])
        assert not any(o.type in {'CAMERA', 'LIGHT'} for o in check.objects)
        assert all(any(o.name.startswith(name) for o in check.objects) for name in expected['parts'])
        reports[ext] = {'triangles': got['triangles'], 'boundsError': delta, 'packedImages': len(images)}
        imported[ext] = check
        bpy.context.window.scene = pet.scene
    return reports, imported


def preview(pet):
    scene = bpy.data.scenes.new('Soft winter studio')
    scene.collection.children.link(pet.collection)
    bpy.context.window.scene = scene
    world = bpy.data.worlds.new('Neutral fill')
    world.use_nodes = True
    node = world.node_tree.nodes.get('Background')
    node.inputs[0].default_value = (1, .977, .955, 1)
    node.inputs[1].default_value = .44
    scene.world = world
    bpy.ops.mesh.primitive_plane_add(size=100, location=(0, 0, -.009))
    ground = bpy.context.object
    backdrop = material('Pale winter blue', 'C6E0EA', .93)
    backdrop.node_tree.nodes.get('Principled BSDF').inputs['Emission Color'].default_value = backdrop.diffuse_color
    backdrop.node_tree.nodes.get('Principled BSDF').inputs['Emission Strength'].default_value = .18
    ground.data.materials.append(backdrop)
    for name, loc, energy, size in [
        ('Key softbox', (-3.7, -4.5, 6.7), 400, 4.5),
        ('Face softbox', (4.3, -4.1, 4.5), 173, 5),
        ('Rim softbox', (1.0, 4.7, 5.8), 262, 4.5),
    ]:
        light = bpy.data.lights.new(name, 'AREA')
        light.energy, light.size = energy, size
        obj = bpy.data.objects.new(name, light)
        scene.collection.objects.link(obj)
        obj.location = loc
        aim(obj, (0, .30, 1.40))
    camera = bpy.data.objects.new('Orthographic review camera', bpy.data.cameras.new('Orthographic review camera'))
    camera.data.type = 'ORTHO'
    scene.collection.objects.link(camera)
    return scene, ground, camera


def render(scene, camera, target, angle, path, pixels, samples, occupancy=.82, alpha=False):
    bpy.context.window.scene = scene
    scene.camera = camera
    scene.render.resolution_x = scene.render.resolution_y = pixels
    scene.render.resolution_percentage = 100
    camera.location = angle
    aim(camera, target)
    camera.data.ortho_scale = 5.0
    camera.data.shift_x = camera.data.shift_y = 0
    bpy.context.view_layer.update()
    graph = bpy.context.evaluated_depsgraph_get()
    projected = []
    for obj in scene.objects:
        if obj.type != 'MESH' or not obj.parent:
            continue
        evaluated = obj.evaluated_get(graph)
        data = evaluated.to_mesh()
        projected.extend(world_to_camera_view(scene, camera, evaluated.matrix_world @ v.co) for v in data.vertices)
        evaluated.to_mesh_clear()
    l, r = min(p.x for p in projected), max(p.x for p in projected)
    b, t = min(p.y for p in projected), max(p.y for p in projected)
    camera.data.ortho_scale = 5*max(r-l, t-b)/occupancy
    camera.data.shift_x = ((l+r)/2-.5)*5/camera.data.ortho_scale
    camera.data.shift_y = ((b+t)/2-.5)*5/camera.data.ortho_scale
    scene.render.engine = 'CYCLES'
    scene.cycles.samples = samples
    scene.cycles.use_denoising = True
    scene.render.film_transparent = alpha
    scene.render.image_settings.file_format = 'PNG'
    scene.render.image_settings.color_mode = 'RGBA' if alpha else 'RGB'
    scene.view_settings.view_transform = 'Standard'
    scene.view_settings.look = 'None'
    scene.render.filepath = str(path)
    bpy.ops.render.render(write_still=True)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('pets', nargs='*', choices=list(SPECS))
    parser.add_argument('--draft', action='store_true')
    args = parser.parse_args(sys.argv[sys.argv.index('--')+1:])
    for name in args.pets or SPECS:
        pet = Pet(name)
        body = pet.build()
        report = audit(pet.collection.objects)
        assert report['triangles'] < 10000, report
        assert abs(report['bounds'][0][2]) < .005, report
        print('FROST_AUDIT', name, json.dumps(report), flush=True)
        if not args.draft:
            report['imports'], imported = export(pet, body, report)
            (pet.work/'verification.json').write_text(json.dumps(report, indent=2)+'\n', encoding='utf-8')
        stage, ground, camera = preview(pet)
        target = (0, .24, 1.44)
        front = (4.35, -10.45, 3.62)
        if args.draft:
            render(stage, camera, target, front, pet.work/'draft-front.png', 560, 12)
            continue
        render(stage, camera, target, front, pet.work/'front-three-quarter.png', 780, 32)
        render(stage, camera, target, (6.4, 9.2, 4.9), pet.work/'rear-three-quarter.png', 780, 32)
        for ext, check in imported.items():
            for obj in stage.objects:
                if obj.name not in pet.collection.objects:
                    check.collection.objects.link(obj)
            check.world = stage.world
            render(check, camera, target, front, pet.work/f'roundtrip-{ext}.png', 400, 14)
        ground.hide_render = True
        # Only the UI staging copy is mirrored so the signature tail is visible from the left.
        if name in {'SnowPup', 'AuroraLynx', 'GlacierDragon'}:
            pet.root.scale.x = -1
        render(stage, camera, target, (-5.05, -10.50, 5.37), pet.work/'ui-source.png', 768, 30, .83, alpha=True)


if __name__ == '__main__':
    main()
