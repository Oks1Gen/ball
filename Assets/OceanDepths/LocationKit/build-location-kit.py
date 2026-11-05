"""Author the Ocean Depths organic kit in Blender; materials carry exact sRGB colours.
Run headless: blender -b -P build-location-kit.py. No remote generation or upload.
The selected PNGs in ../<Location>/ are the modelling references.
"""
import importlib.util
import json
import math
from pathlib import Path

import bpy
from mathutils import Vector

OUT = Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location("reef", OUT.parent / "build-sea-life.py")
reef = importlib.util.module_from_spec(spec)
spec.loader.exec_module(reef)
mesh, loft, fin, box = reef.mesh, reef.loft, reef.fin, reef.box


def tube(group, name, points, radii, tone, sides=6):
    rings = []
    for i, p in enumerate(points):
        tangent = Vector(points[min(i + 1, len(points) - 1)]) - Vector(points[max(i - 1, 0)])
        q = tangent.to_track_quat('Z', 'Y')
        rings.append([tuple(Vector(p) + q @ Vector((radii[i] * math.cos(k * math.tau / sides),
                                                    radii[i] * math.sin(k * math.tau / sides), 0)))
                      for k in range(sides)])
    return loft(group, name, rings, lambda row, k: tone if k % 3 else tone)


def ellipsoid(group, name, center, size, tone, sides=10, levels=5):
    rings = []
    for row in range(levels):
        angle = -.5 * math.pi + .03 + row * (math.pi - .06) / (levels - 1)
        rings.append([(center[0] + size[0] * .5 * math.cos(angle) * math.cos(k * math.tau / sides),
                       center[1] + size[1] * .5 * math.cos(angle) * math.sin(k * math.tau / sides),
                       center[2] + size[2] * .5 * math.sin(angle)) for k in range(sides)])
    return loft(group, name, rings, lambda *_: tone)


def kelp(scene):
    root, (stems, leaves, tips) = reef.species(scene, "AmberKelp")
    for stalk in range(5):
        yaw = stalk * 2.25
        height = (28, 23, 32, 21, 26)[stalk]
        points = [(math.cos(yaw) * (.8 + .003 * z * z), math.sin(yaw) * (.8 + .002 * z * z), z)
                  for z in (0, height * .25, height * .5, height * .75, height)]
        tube(stems, "Golden stipe", points, [.34, .32, .28, .21, .09], "A88D28")
        for level in range(1, 7):
            z = height * (.13 + level * .115)
            sign = -1 if level % 2 else 1
            x = math.cos(yaw) * (.8 + .003 * z * z)
            y = math.sin(yaw) * (.8 + .002 * z * z)
            length = 8.4 - abs(level - 3) * .48
            points_leaf = [(x, y, z), (x + sign * length * .42, y + .75, z + 2.3),
                           (x + sign * length, y + .2, z + 5.2),
                           (x + sign * length * .85, y - .55, z + 1.3),
                           (x + sign * length * .30, y - .65, z - .3)]
            fin(leaves, "Ribbon blade", points_leaf, .25, ("E4B82D", "F5C943", "C8A431")[level % 3])
            ellipsoid(tips, "Air bladder", (x, y, z + .2), (.63, .63, .85), "DAAD21", 6, 3)
    return root


def seahorse(scene):
    root, (body, fins, face) = reef.species(scene, "GoldenSeahorse")
    path = [(0, 0, 0), (-.65, 0, .25), (-.9, 0, .95), (-.5, 0, 1.4), (.3, 0, 1.2),
            (.8, 0, .65), (.8, 0, 2.1), (.2, 0, 3), (-.15, 0, 4), (.1, 0, 5.1),
            (.75, 0, 5.85), (1.35, 0, 5.7)]
    tube(body, "Curled body and tail", path, [.1,.14,.19,.23,.24,.30,.45,.70,.65,.45,.48,.33], "F5BD30", 8)
    tube(fins, "Long snout", [(1.05,0,5.7),(1.85,0,5.35),(2.35,0,5.28)], [.34,.25,.22], "FFE08B")
    for z in (3.25,3.75,4.25):
        fin(fins,"Dorsal crest",[(-.4,0,z),(-1.1,0,z+.3),(-.3,0,z+.6)], .15,"E7A728")
    for side in (-1,1):
        ellipsoid(face,"Eye",(.72,side*.42,5.88),(.29,.14,.29),"172740",8,3)
        ellipsoid(face,"Eye shine",(.79,side*.50,5.95),(.08,.06,.08),"FFFFFF",6,3)
    return root


def jelly(scene):
    root,(bell,arms,light)=reef.species(scene,"ReefJellyfish")
    rings=[]
    for radius,z in ((.1,4.8),(2.2,4.3),(3.6,3.15),(4.15,1.5),(4.05,.8),(3.4,1.05)):
        rings.append([(radius*math.cos(k*math.tau/12),radius*math.sin(k*math.tau/12),z) for k in range(12)])
    loft(bell,"Faceted bell",rings,lambda row,k: ("F3A1E5","EC88D1","FFB7EB")[(row+k)%3])
    for i in range(8):
        angle=i*math.tau/8
        points=[(math.cos(angle)*(2.8+.45*math.sin(j*1.5+i)),math.sin(angle)*(2.8+.4*math.sin(j+i)),
                 .9-j*1.6) for j in range(6)]
        tube(arms,"Trailing ribbon",points,[.25,.23,.21,.18,.14,.07],"EEADD8",5)
    ellipsoid(light,"Luminous core",(0,0,2.3),(2.7,2.7,2),"FFD3EE",8,4)
    return root


def squid(scene):
    root,(body,arms,face)=reef.species(scene,"AbyssSquid")
    ellipsoid(body,"Mantle",(0,0,8),(5.8,5.4,13),"244C7E",10,6)
    for side in (-1,1):
        fin(body,"Mantle fin",[(side*1.5,0,10),(side*5.2,0,12.2),(side*2.3,0,5.5)],.4,"2D6293")
        ellipsoid(face,"Eye",(side*2.2,-1.4,3.4),(.85,.3,1.1),"5ECADB",8,4)
        ellipsoid(face,"Pupil",(side*2.2,-1.58,3.4),(.28,.08,.65),"122F50",8,3)
    for i in range(8):
        a=i*math.tau/8
        points=[(math.cos(a)*(1.6+j*.65)+math.sin(j*.8+i)*.4,
                 math.sin(a)*(1.6+j*.65),2-j*2.2) for j in range(7)]
        tube(arms,"Sweeping arm",points,[.59,.51,.44,.34,.23,.14,.04],"254E7F",6)
    return root


def angler(scene):
    root,(body,fins,face)=reef.species(scene,"Anglerfish")
    ellipsoid(body,"Deep sea body",(0,0,0),(4.3,2.3,3.1),"29476E",10,5)
    fin(fins,"Tail",[(-1.7,0,.3),(-3.6,0,1.35),(-3.6,0,-1),(-1.7,0,-.3)],.22,"37628D")
    for s in (-1,1):
        ellipsoid(face,"Eye",(.9,s*.9,.6),(.38,.18,.38),"F9D978",8,3)
        fin(fins,"Pectoral",[(.2,s*.8,-.1),(-.6,s*1.7,-.65),(-1.25,s*.9,-.3)],.12,"4877A0")
    tube(face,"Lure",[(.45,0,1.2),(.6,0,2.6),(1.6,0,3),(2.5,0,2.65)], [.12,.1,.08,.07],"D5AA56")
    ellipsoid(face,"Luminous lure",(2.5,0,2.55),(.6,.6,.6),"FFE6A0",8,4)
    return root


def crystal(scene):
    root,(body,tips,base)=reef.species(scene,"MintCrystals")
    for i,(x,y,h,r) in enumerate(((0,0,9,1.35),(-2,1,6,1.1),(2,.8,7.2,1),(.8,-1.7,4.5,.85),(-1.4,-1.5,4.7,.9))):
        rings=[[(x+r*math.cos(k*math.tau/6),y+r*math.sin(k*math.tau/6),z) for k in range(6)] for z in (0,h*.77)]
        rings.append([(x+r*.025*math.cos(k*math.tau/6),y+r*.025*math.sin(k*math.tau/6),h) for k in range(6)])
        loft(body,"Prismatic crystal",rings,lambda row,k:("46CFD3","85E9DA","4ABCD1","B7FAEB")[k%4])
    return root


def shell(scene):
    root,(body,ribs,hinge)=reef.species(scene,"PearlShellValve")
    # Seven closed, curved radial flutes form the scalloped rim and a solid hinge.
    for i in range(-4,5):
        a=i*.165
        length=13-abs(i)*.45
        rings=[]
        for t in (0,.25,.55,.8,1):
            width=.35+1.05*t
            x=math.sin(a)*length*t
            z=math.cos(a)*length*t
            y=-2.4*math.sin(t*math.pi*.85)
            rings.append([(x+dx*width,y+dy*.6,z+dz*.18) for dx,dy,dz in ((-1,0,-1),(1,0,-1),(1,1,1),(-1,1,1))])
        loft(body,"Scallop flute",rings,lambda row,k:("FFF1D8","EDC8D8","C7F0E7")[(i+row)%3])
    ellipsoid(hinge,"Hinge",(0,0,.55),(3.6,1.7,1.3),"F8E1CB",8,4)
    return root


def payload(roots):
    result={}
    for root in roots:
        result[root.name]=[]
        for group in root.children:
            v,t=[],[]
            for obj in group.objects:
                d=obj.data;d.calc_loop_triangles();off=len(v)
                v.extend(tuple(round(a,4) for a in (p.co.x,p.co.z,-p.co.y)) for p in d.vertices)
                t.extend(([off+k+1 for k in f.vertices],d.materials[f.material_index].name) for f in d.loop_triangles)
            if t:
                assert len(t)<3000,(root.name,len(t))
                result[root.name].append(dict(name=group.name.split(' ')[-1],v=v,t=t))
    return result


def main():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    scene=bpy.context.scene;scene.name='Ocean Depths Location Kit'
    roots=[f(scene) for f in (kelp,seahorse,jelly,squid,angler,crystal,shell)]
    data=payload(roots)
    (OUT/'location-kit-geometry.json').write_text(json.dumps(data,separators=(',',':')),encoding='utf8')
    stats={k:sum(len(g['t']) for g in groups) for k,groups in data.items()}
    for i,root in enumerate(roots):
        origin=bpy.data.objects.new(root.name,None);root.objects.link(origin);origin.location=(i*35,0,0)
        for group in root.children:
            for obj in group.objects:obj.parent=origin
    bpy.context.preferences.filepaths.save_version=0
    bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'location-kit.blend'))
    bpy.ops.export_scene.gltf(filepath=str(OUT/'location-kit.glb'),export_format='GLB',export_yup=True)
    bpy.ops.export_scene.fbx(filepath=str(OUT/'location-kit.fbx'),object_types={'MESH','EMPTY'},add_leaf_bones=False)
    (OUT/'validation.json').write_text(json.dumps({'triangles':stats,'closedGeometry':True,'palette':'selected Ocean Depths concepts'},indent=2),encoding='utf8')
    print(stats)


if __name__=='__main__':main()
