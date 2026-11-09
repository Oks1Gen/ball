"""Build the five Void Egg collectible pets and their review renders in Blender."""
import argparse
import json
import math
import sys
from pathlib import Path

import bpy
import numpy as np
from mathutils import Vector

MODELS = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(MODELS.parents[1] / 'FrostEgg/models/work'))
import build_frost as shared

SPECS = {
    'DuskMoth': ('Dusk Moth', 'B05AE7', 'FFE0EA', 'A44CD9', 'violet', .433, 1.12, .281, .284),
    'ShadowKitten': ('Shadow Kitten', '352584', '352584', '2C216C', 'amber', .437, 1.07, .283, .282),
    'OrbitAxolotl': ('Orbit Axolotl', '4854C7', 'FFE5EE', '1CD8F6', 'teal', .438, 1.11, .281, .284),
    'RiftWyrm': ('Rift Wyrm', '872BC6', 'FFE1EE', '42207A', 'teal', .437, 1.08, .281, .282),
    'Singularity': ('Singularity', '191228', '191228', '241930', 'violet', .435, 1.16, .298, .301),
}
shared.MODELS = MODELS
shared.SPECS = SPECS
material = shared.material
bezier = shared.bezier
rgb, blend, smooth = shared.rgb, shared.blend, shared.smooth
FRONT = shared.FRONT_AXES


class VoidPet(shared.Pet):
    def __init__(self, name):
        super().__init__(name)
        self.root['Reference'] = 'Assets/Pets/VoidEgg/reference.png'
        self.root['ScaleBrief'] = 'Two-unit cube, front -Y, +Z up, origin at feet'

    def body(self):
        coat = material('Painted soft cube', self.coat)
        face_mask = bezier((0, 1.40), [
            ((-.23, 1.80), (-.61, 1.82), (-.79, 1.57)),
            ((-.89, 1.43), (-.90, 1.24), (-.84, 1.13)),
            ((-.96, 1.00), (-.97, .67), (-.80, .52)),
            ((-.67, .39), (-.39, .39), (0, .39)),
            ((.39, .39), (.67, .39), (.80, .52)),
            ((.97, .67), (.96, 1.00), (.84, 1.13)),
            ((.90, 1.24), (.89, 1.43), (.79, 1.57)),
            ((.61, 1.82), (.23, 1.80), (0, 1.40)),
        ], 9)
        marks = [
            [(.62, .93), (.91, 1.105), (.91, .88)],
            [(.61, .795), (.915, .79), (.912, .56)],
        ]
        marks = [[np.array(p) for p in tri] for tri in marks]

        def pixels(u, v):
            x, height = (2*u % 1)*2-1, 2*v-1
            z = height+1.24
            solid = rgb(self.coat)
            plain = np.broadcast_to(solid, (*u.shape, 3))
            if self.name == 'Singularity':
                # This trim is baked into the atlas and survives Studio lighting
                # and variant tints without adding a runtime effect or part.
                edge = np.maximum(np.abs(x), np.abs(height))
                plain = blend(plain, rgb('2D295C'), .66*smooth((edge-.80)/.14))
                plain = blend(plain, rgb('146AB8'), smooth((edge-.865)/.085))
                plain = blend(plain, rgb('26DFFB'), smooth((edge-.906)/.057))
                plain = blend(plain, rgb('B2FFFF'), smooth((edge-.946)/.027))
            front = plain
            if self.name in {'DuskMoth', 'OrbitAxolotl', 'RiftWyrm'}:
                mask = smooth(.5+shared.distance_to_outline(x, z, face_mask)/.013)
                front = blend(front, rgb(self.cream), mask)
            blush_z = .826 if self.name == 'Singularity' else .807
            blush = ((np.abs(x)-.648)/.163)**2+((z-blush_z)/.133)**2
            front = blend(front, rgb('F83A9C'), .88*np.exp(-1.55*blush))
            if self.name == 'ShadowKitten':
                for triangle in marks:
                    mask = smooth(.5+shared.distance_to_outline(np.abs(x), z, triangle)/.016)
                    front = blend(front, rgb('EDC9FF'), mask)
            return np.where((u < .5)[..., None], front, plain)

        self.paint(coat, 'body-albedo', pixels, 1024 if self.name == 'Singularity' else 512)
        bpy.ops.mesh.primitive_cube_add(size=2, location=(0, 0, 1.24))
        body = self.attach(bpy.context.object, 'Square body', coat)
        bevel = body.modifiers.new('Soft square edges', 'BEVEL')
        bevel.width = .112 if self.name == 'Singularity' else .215
        bevel.segments = 7
        bpy.ops.object.modifier_apply(modifier=bevel.name)
        normal = body.modifiers.new('Flat face normals', 'WEIGHTED_NORMAL')
        normal.keep_sharp = True

        def project(index, face):
            x, y, z = body.data.vertices[index].co
            nx, ny, nz = face.normal
            if self.name == 'Singularity':
                if abs(ny) >= max(abs(nx), abs(nz)):
                    return ((.25 if ny < 0 else .75)+.244*x, .5+.488*z)
                if abs(nx) >= abs(nz):
                    return (.75+.244*y, .5+.488*z)
                return (.75+.244*x, .5+.488*y)
            if ny < -.18:
                return (.25+.243*x, (z+1)*.5)
            return (.75+.243*y, (z+1)*.5) if abs(nx) > .65 else (.98, .97)

        shared.uv_map(body, project)
        return body

    def face(self, pale_mouth=False, nose=True):
        if pale_mouth:
            ink = material('Light smile', 'F7DEFF', .39)
            for s, side in [(-1, 'left'), (1, 'right')]:
                self.sweep(side+' light smile curl', [
                    (0,-1.020,.883,0,0),(s*.040,-1.032,.839,.017,.014),
                    (s*.085,-1.034,.821,.020,.014),(s*.132,-1.025,.857,.016,.012),
                    (s*.148,-1.017,.892,0,0),
                ], ink, axis=(0,1,0), rings=10, sides=10)
        else:
            self.smile(.81, nose=False)
        if nose:
            candy = material('Berry pink nose', 'F875AE', .31)
            self.sphere('Little pink nose', (0,-1.059,.950), (.094,.061,.054), candy)

    def dusk_moth(self):
        upper = bezier((-.20,-.29), [
            ((-.30,-.08),(-.31,.24),(-.20,.44)),
            ((-.04,.71),(.26,.87),(.56,.84)),
            ((.83,.80),(.91,.58),(.87,.32)),
            ((.83,.03),(.58,-.25),(.31,-.35)),
            ((.10,-.43),(-.08,-.42),(-.20,-.29)),
        ], 8)
        lower = bezier((-.21,.14), [
            ((-.15,.33),(.18,.32),(.42,.22)),
            ((.66,.12),(.70,-.15),(.56,-.31)),
            ((.43,-.49),(.14,-.47),(-.05,-.37)),
            ((-.24,-.27),(-.31,-.05),(-.21,.14)),
        ], 7)
        wing = material('Violet wing with lilac oval', 'A44BD5')
        def wing_pixels(u, v):
            x,z=-.40+1.4*u,-.56+1.53*v
            dx,dz=x-.38,z-.24
            across=.87*dx-.493*dz
            along=.493*dx+.87*dz
            oval=1-(across/.257)**2-(along/.325)**2
            return blend(rgb('A64BDA'), rgb('DEA2FB'), smooth((oval+.02)/.09))
        self.paint(wing,'moth-wing-albedo',wing_pixels,256)
        small_wing = material('Lower violet wing', '9040CB')
        antenna = material('Violet antenna', '8C39BD')
        for s, side in [(-1, 'left'), (1, 'right')]:
            self.pillow(side+' small lower moth wing',(s*.98,.39,.94),FRONT,lower,small_wing,(.154,.137),mirror=s<0)
            self.pillow(side+' oval-marked moth wing',(s*.98,.27,1.56),FRONT,upper,wing,(.173,.153),
                        mirror=s<0,map_mode=lambda x,z,n:((x+.40)/1.4,(z+.56)/1.53))
            self.sweep(side+' rounded moth antenna',[
                (s*.32,-.39,2.12,0,0),(s*.35,-.37,2.30,.105,.096),
                (s*.39,-.35,2.54,.110,.102),(s*.49,-.33,2.72,.118,.106),
                (s*.56,-.32,2.78,.119,.103),(s*.68,-.31,2.81,0,0),
            ],antenna,rings=22,sides=16)
            self.sphere(side+' rounded antenna bulb',(s*.658,-.314,2.813),(.227,.143,.164),antenna)
        self.face()

    def shadow_kitten(self):
        outer = bezier((-.41,-.12), [
            ((-.36,.14),(-.21,.50),(.064,.78)),
            ((.119,.83),(.181,.83),(.222,.766)),
            ((.364,.53),(.405,.14),(.378,-.14)),
            ((.180,-.17),(-.18,-.17),(-.41,-.12)),
        ],8)
        inner = bezier((-.255,-.05), [
            ((-.20,.158),(-.07,.418),(.131,.635)),
            ((.211,.574),(.286,.210),(.267,-.055)),
            ((.128,-.09),(-.14,-.09),(-.255,-.05)),
        ],8)
        ear = material('Indigo cat ear with violet inset','352584')
        def ear_pixels(u,v):
            x,z=2*u-1,2*v-1
            mark=smooth(.5+shared.distance_to_outline(x,z,inner)/.016)
            return blend(rgb('352584'), blend(rgb('D26CF7'),rgb('A943DC'),smooth(z/.8)),mark)
        self.paint(ear,'ear-albedo',ear_pixels,256)
        for s,side in [(-1,'left'),(1,'right')]:
            self.pillow(side+' triangular kitten ear',(s*.57,-.38,2.18),FRONT,outer,ear,(.148,.181),
                        mirror=s<0,map_mode=lambda x,z,n:((x+1)/2,(z+1)/2) if n>0 else (.95,.94))
        tail=material('Indigo kitten tail','352584')
        self.sweep('Hooked kitten tail',[
            (.43,.79,.89,0,0),(.59,1.05,.99,.172,.149),(.73,1.38,1.19,.20,.169),
            (.82,1.66,1.59,.193,.155),(.83,1.72,1.92,.185,.150),(.82,1.62,2.25,.187,.160),
            (.82,1.60,2.59,.207,.171),(.89,1.80,2.78,.205,.174),
            (1.02,2.04,2.80,.171,.146),(1.13,2.19,2.72,.142,.121),
            (1.17,2.25,2.65,.105,.085),(1.21,2.28,2.60,0,0),
        ],tail,rings=38,sides=20)
        self.face(pale_mouth=True)

    def orbit_axolotl(self):
        gills = material('Turquoise gills','27DDF7',.34)
        self.paint(gills,'gill-albedo',lambda u,v:blend(rgb('169BD9'),rgb('61F9FA'),smooth((v-.06)/.87)),256)
        for s,side in [(-1,'left'),(1,'right')]:
            for i,(z,end_x,rise) in enumerate([(1.57,1.70,.51),(1.17,1.76,.045),(.82,1.65,-.285)]):
                self.sweep(f'{side} pillowy gill {i+1}',[
                    (s*.89,-.22,z,0,0),(s*1.06,-.23,z+rise*.16,.136,.127),
                    (s*(end_x-.27),-.17,z+rise*.67,.194,.158),
                    (s*(end_x-.09),-.11,z+rise*.93,.136,.113),
                    (s*end_x,-.10,z+rise,0,0),
                ],gills,axis=(0,1,0),rings=17,sides=16,texture=True)
        tail=material('Indigo axolotl tail with aqua fin','4854C7')
        outer=bezier((-.55,-.36),[
            ((-.53,-.60),(-.14,-.57),(.19,-.40)),
            ((.51,-.23),(.77,.01),(.90,.39)),
            ((1.01,.70),(1.23,.94),(1.20,1.16)),
            ((1.14,1.43),(.79,1.49),(.49,1.32)),
            ((.13,1.12),(-.18,.67),(-.32,.28)),
            ((-.49,-.02),(-.64,-.22),(-.55,-.36)),
        ],9)
        inner=bezier((-.53,-.39),[
            ((-.51,-.64),(-.17,-.63),(.19,-.44)),
            ((.62,-.24),(.77,.11),(.87,.52)),
            ((.94,.79),(.96,1.03),(1.03,1.12)),
            ((.76,1.12),(.48,.92),(.27,.68)),
            ((.05,.44),(-.20,.20),(-.36,-.06)),
            ((-.51,-.17),(-.61,-.29),(-.53,-.39)),
        ],9)
        def tail_pixels(u,v):
            x,z=1.96*u-.66,2.17*v-.65
            mask=smooth(.5+shared.distance_to_outline(x,z,inner)/.021)
            aqua=blend(rgb('24CBEF'),rgb('66F8FF'),smooth(z/1.38))
            return blend(aqua,rgb('4854C7'),mask)
        self.paint(tail,'tail-albedo',tail_pixels)
        # A swept fin extending back and outward so it reads in both review views.
        self.pillow('Broad swept axolotl tail',(.44,.95,1.20),((.50,.866,0),(0,0,1)),outer,tail,(.235,.217),
                    map_mode=lambda x,z,n:((x+.66)/1.96,(z+.65)/2.17))
        self.face()

    def rift_wyrm(self):
        horn=material('Indigo horns with orchid tips','401A7F',.36)
        self.paint(horn,'horn-albedo',lambda u,v:blend(rgb('35156D'),rgb('CF3DF6'),smooth((v-.53)/.45)),256)
        for s,side in [(-1,'left'),(1,'right')]:
            x=s*.49
            self.sweep(side+' smooth swept horn',[
                (x,-.52,2.08,0,0),(x,-.47,2.23,.269,.236),(x+.025,-.37,2.52,.262,.195),
                (x+.084,-.12,2.70,.224,.156),(x+.155,.19,2.82,.153,.113),
                (x+.199,.34,3.00,.088,.073),(x+.198,.31,3.13,0,0),
            ],horn,rings=24,sides=18,texture=True)
        self.rift_wings()
        tail=material('Dark violet tail','3B197A')
        self.sweep('Sweeping rift tail',[(.42,.73,.65,0,0),(.65,.99,.58,.213,.181),
            (.98,1.16,.53,.234,.182),(1.31,1.27,.58,.217,.177),
            (1.59,1.28,.71,.17,.140),(1.74,1.29,.97,.121,.103),(1.78,1.28,1.12,0,0)],tail,rings=23,sides=18)
        spade=bezier((-.305,-.035),[
            ((-.286,.06),(.015,.17),(.253,.292)),
            ((.326,.332),(.333,.215),(.314,.09)),
            ((.311,-.066),(.321,-.271),(.238,-.261)),
            ((.106,-.244),(.026,-.152),(-.093,-.144)),
            ((-.20,-.133),(-.328,-.12),(-.305,-.035)),
        ],7)
        self.pillow('Orchid spade tail tip',(1.68,1.28,1.045),FRONT,spade,material('Orchid tail tip','B930EC'),(.110,.108))
        self.face()

    def rift_wings(self):
        profile=np.array([
            (-.11,-.07,-.07),(.035,.30,-.29),(.21,.66,-.39),(.39,.70,-.245),
            (.57,.63,-.23),(.75,.54,-.33),(.95,.41,-.105),(1.15,.24,.003),
            (1.33,.085,.031),(1.39,.018,.018),
        ])
        mat=material('Indigo wings with aqua hem','382073',.38)
        def wing_pixels(u,v):
            t=np.clip(u*(len(profile)-1),0,len(profile)-1)
            x=np.floor(t).astype(int).clip(0,len(profile)-2)
            # Interpolate the same section bounds used by the wing mesh.
            lo=np.empty_like(t)
            hi=np.empty_like(t)
            for k in range(len(profile)-1):
                mask=x==k
                if not np.any(mask): continue
                a,b=profile[k:k+2]
                p=profile[k-1] if k else 2*a-b
                q=profile[k+2] if k+2<len(profile) else 2*b-a
                k_u=t[mask]-k
                for ix,arr in [(1,hi),(2,lo)]:
                    arr[mask]=a[ix]+.5*k_u*(b[ix]-p[ix]+k_u*(2*p[ix]-5*a[ix]+4*b[ix]-q[ix]+k_u*(3*a[ix]-3*b[ix]+q[ix]-p[ix])))
            d=v*np.maximum(hi-lo,.01)
            trim=(1-smooth((d-.109)/.018))*smooth((u-.07)/.14)*smooth((.995-u)/.11)
            plum=blend(rgb('382073'),rgb('6033A2'),.57*smooth(v))
            return blend(plum,rgb('39F0F5'),trim)
        self.paint(mat,'rift-wing-albedo',wing_pixels)
        rim=material('Rounded violet leading edge','562394')
        for s,side in [(-1,'left'),(1,'right')]:
            def world(x,z,depth=0):
                return (s*(.84+x),.24+.18*x+depth,1.51+z)
            vertices=[world(*profile[0,:2])]
            uv=[(0,.5)]
            rings,sides=28,14
            for i in range(1,rings+1):
                t=i/(rings+1)
                x,hi,lo=shared.catmull(profile,(len(profile)-1)*t)
                assert hi>lo
                for j in range(sides):
                    theta=2*math.pi*j/sides
                    v=.5+.5*math.sin(theta)
                    vertices.append(world(x,lo+v*(hi-lo),math.cos(theta)*min(.091,(hi-lo)*.23)))
                    uv.append((t,v))
            vertices.append(world(*profile[-1,:2])); uv.append((1,.5))
            obj=self.mesh(side+' scalloped rift wing',vertices,shared.caps_and_rings(sides,rings),mat)
            shared.uv_map(obj,lambda index,face:uv[index])
            radii=[0,.061,.089,.091,.080,.067,.052,.042,.026,0]
            self.sweep(side+' wing rim',[(*world(x,z-.018),r,r) for (x,z,_),r in zip(profile,radii)],
                       rim,axis=(0,1,0),rings=19,sides=12)

    def singularity(self):
        ring=material('Neon violet orbit ring','A92DF5',.29)
        def ring_pixels(u,v):
            f=.5+.5*np.sin(2*math.pi*(u+.18))
            ring_color=blend(rgb('861DF2'),rgb('EA43FF'),f)
            top=.5+.5*np.cos(2*math.pi*(v-.09))
            return blend(ring_color,rgb('FFB4FF'),.59*top**11)
        self.paint(ring,'orbit-albedo',ring_pixels,512)
        bpy.ops.mesh.primitive_torus_add(major_segments=88,minor_segments=16,major_radius=1.79,minor_radius=.109,
                                        location=(0,0,1.28),rotation=(.31,-.27,0))
        obj=self.attach(bpy.context.object,'Tilted neon orbit ring',ring)
        obj.scale=(1.12,.99,.91)
        bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
        bpy.context.view_layer.update()
        # Check that the ring does not cut through the cube in any camera view.
        assert all(max(abs(p.x),abs(p.y))>1.01 for p in (obj.matrix_world @ v.co for v in obj.data.vertices))
        self.face(pale_mouth=True,nose=False)

    def build(self):
        body=self.body()
        self.paws(.47,.47,.28)
        self.eyes()
        builder={
            'DuskMoth':self.dusk_moth,
            'ShadowKitten':self.shadow_kitten,
            'OrbitAxolotl':self.orbit_axolotl,
            'RiftWyrm':self.rift_wyrm,
            'Singularity':self.singularity,
        }[self.name]
        builder()
        return body


def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('pets',nargs='*')
    parser.add_argument('--draft',action='store_true')
    args=parser.parse_args(sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else [])
    for name in args.pets or SPECS:
        pet=VoidPet(name)
        body=pet.build()
        report=shared.audit(pet.collection.objects)
        assert report['triangles']<10000 and abs(report['bounds'][0][2])<.005,report
        print('VOID_AUDIT',name,json.dumps(report),flush=True)
        if not args.draft:
            report['imports'],imported=shared.export(pet,body,report)
            (pet.work/'verification.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8',newline='')
        stage,ground,camera=shared.preview(pet)
        stage.name='Void Egg studio'
        ground.data.materials.clear()
        ground.data.materials.append(material('Pale lilac backdrop','E2D0F3',.92))
        target=(0,.20,1.44)
        front=(4.35,-10.45,3.62)
        if args.draft:
            shared.render(stage,camera,target,front,pet.work/'draft-front.png',560,14)
            continue
        shared.render(stage,camera,target,front,pet.work/'front-three-quarter.png',768,26)
        shared.render(stage,camera,target,(6.4,9.2,4.9),pet.work/'rear-three-quarter.png',768,26)
        for ext,check in imported.items():
            for obj in stage.objects:
                if obj.name not in pet.collection.objects:
                    check.collection.objects.link(obj)
            check.world=stage.world
            shared.render(check,camera,target,front,pet.work/f'roundtrip-{ext}.png',400,14)
        ground.hide_render=True
        if name in {'ShadowKitten','OrbitAxolotl','RiftWyrm','Singularity'}:
            pet.root.scale.x=-1
        shared.render(stage,camera,target,(-5.05,-10.5,5.37),pet.work/'ui-source.png',768,26,.83,alpha=True)


if __name__=='__main__':
    main()
