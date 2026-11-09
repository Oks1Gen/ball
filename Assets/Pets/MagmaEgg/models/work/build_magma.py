"""Headless bpy source for the five vibrant Magma Egg pets.

Shared closed soft forms, packed paint, export/reimport and camera helpers are
reused from the verified Frost pipeline. Front is -Y, Z up, ground is Z=0.
"""
import argparse
import json
import math
import sys
from pathlib import Path

import bpy
import numpy as np

MODELS = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(MODELS.parents[1] / 'FrostEgg/models/work'))
import build_frost as b

b.MODELS = MODELS
b.SPECS = {
    'CoalMole': ('Coal Mole', '303546', '303546', 'FF6507', 'amber', .435, 1.06, .278, .282),
    'CinderGecko': ('Cinder Gecko', 'FF5912', 'FFB65A', 'FFD298', 'green', .430, 1.075, .279, .280),
    'EmberRam': ('Ember Ram', 'F94D0B', 'FFE0AD', '322A30', 'amber', .426, 1.075, .277, .280),
    'BlazeBat': ('Blaze Bat', '54218D', '54218D', 'F6570A', 'amber', .428, 1.065, .272, .280),
    'InfernoPhoenix': ('Inferno Phoenix', 'FF3012', 'FFE2AD', 'FFAD00', 'amber', .416, 1.055, .268, .274),
}
rgb, blend, smooth = b.rgb, b.blend, b.smooth
material, bezier = b.material, b.bezier
FRONT = b.FRONT_AXES


class MagmaPet(b.Pet):
    def __init__(self, name):
        super().__init__(name)
        self.root['Reference'] = 'Assets/Pets/World1/remaining-eggs-v2/magma-egg-five-pets-v2.png'
        self.root['ScaleBrief'] = '2-unit cube body, static collectible, ground pivot'

    def body(self):
        coat = material('Painted body', self.coat)
        heart = bezier((0, 1.37), [
            ((-.27, 1.81), (-.68, 1.84), (-.84, 1.57)),
            ((-.99, 1.31), (-.93, .69), (-.85, .51)),
            ((-.74, .32), (-.46, .34), (0, .34)),
            ((.46, .34), (.74, .32), (.85, .51)),
            ((.93, .69), (.99, 1.31), (.84, 1.57)),
            ((.68, 1.84), (.27, 1.81), (0, 1.37)),
        ], 10)

        def pixels(u, v):
            x, z = 2*(2*u % 1)-1, .24+2*v
            solid = rgb(self.coat)
            front = np.broadcast_to(np.asarray(solid), (*x.shape, 3)).copy()
            side = front.copy()
            if self.name in {'EmberRam', 'InfernoPhoenix'}:
                mask = smooth(.5+b.distance_to_outline(x, z, heart)/.012)
                front = blend(front, rgb(self.cream), mask)
            if self.name == 'CinderGecko':
                muzzle = 1-(x/.89)**4-((z-.65)/.32)**4
                front = blend(front, rgb(self.cream), smooth((muzzle+.03)/.15))
                spots = np.zeros(x.shape)
                for y, height in [(-.40, .94), (-.13, 1.30), (.14, 1.64)]:
                    spots = np.maximum(spots, smooth((1.02-((x-y)/.095)**2-((z-height)/.146)**2)/.13))
                side = blend(side, rgb('FFE1A6'), spots)
            if self.name == 'CoalMole':
                marking = smooth((1.02-((x+.02)/.157)**2-((z-1.27)/.245)**2)/.13)
                side = blend(side, rgb('FF7800'), marking)
            blush = ((np.abs(x)-.665)/.146)**2+((z-.825)/.118)**2
            front = blend(front, rgb('FF3979'), .90*np.exp(-1.5*blush))
            return np.where((u < .5)[..., None], front, side)

        self.paint(coat, 'body-albedo', pixels)
        bpy.ops.mesh.primitive_cube_add(size=2, location=(0, 0, 1.24))
        obj = self.attach(bpy.context.object, 'Square body', coat)
        bevel = obj.modifiers.new('Soft square edges', 'BEVEL')
        bevel.width, bevel.segments = .220, 7
        bpy.ops.object.modifier_apply(modifier=bevel.name)
        normal = obj.modifiers.new('Flat face normals', 'WEIGHTED_NORMAL')
        normal.keep_sharp = True
        def project(i, face):
            x, y, z = obj.data.vertices[i].co
            if face.normal.y < -.18:
                return (.25+.243*x, (z+1)*.5)
            if abs(face.normal.x) > .65:
                return (.75+.243*y, (z+1)*.5)
            return (.98, .97)
        b.uv_map(obj, project)
        return obj

    def pink_nose(self, color='FF527E', height=.92, size=.108):
        mat = material('Candy nose', color, .30)
        self.sphere('Tiny rounded nose', (0, -1.063, height), (size, .068, size*.62), mat)

    def coal_mole(self):
        dark = material('Charcoal ears', '2B2D40')
        pink = material('Hot pink ear inset', 'FF2469')
        outline = bezier((-.28, -.08), [
            ((-.31, .13), (-.22, .40), (0, .405)),
            ((.22, .40), (.31, .13), (.28, -.08)),
            ((.13, -.115), (-.13, -.115), (-.28, -.08)),
        ], 7)
        for s, label in [(-1, 'left'), (1, 'right')]:
            self.pillow(label+' rounded mole ear', (s*.57, -.23, 2.18), FRONT, outline, dark, (.135,.14))
            shape = [np.asarray(p)*.64 for p in outline]
            self.pillow(label+' pink ear inset', (s*.57, -.357, 2.20), FRONT, shape, pink, (.035,.025))
        self.smile(.77, nose=False)
        self.pink_nose(height=.925,size=.123)

    def cinder_gecko(self):
        outer = material('Tangerine rounded eye bumps', 'FF6214')
        gold = material('Golden eye bumps', 'FFAC00', .34)
        for s, label in [(-1, 'left'), (1, 'right')]:
            self.sphere(label+' low rounded bump', (s*.56, -.41, 2.205), (.287,.245,.265), outer)
            self.sphere(label+' golden bump front', (s*.56, -.582, 2.222), (.211,.091,.190), gold)
        tail = material('Golden curled gecko tail', 'FF9900')
        self.paint(tail, 'tail-albedo', lambda u,v: blend(rgb('F67305'),rgb('FFB509'),smooth(v)),256)
        self.sweep('Thick curled cinder tail', [
            (.40,.74,.61,0,0),(.50,1.10,.86,.22,.22),(.57,1.48,1.21,.31,.28),
            (.61,1.74,1.73,.36,.31),(.62,1.79,2.22,.35,.29),
            (.61,1.61,2.62,.31,.27),(.59,1.24,2.79,.28,.24),
            (.57,.95,2.67,.235,.20),(.55,.94,2.40,.18,.17),(.54,1.13,2.31,0,0),
        ],tail,rings=34,sides=22,texture=True)
        self.smile(.78,nose=False)
        self.pink_nose('FFB229',.925,.098)

    def ember_ram(self):
        horn = material('Charcoal ember horns', '282332', .36)
        def pixels(u,v):
            glow = smooth((v-.13)/.055)*(1-smooth((v-.335)/.055))
            tone = blend(rgb('FF8F00'),rgb('FFEC20'),smooth((v-.15)/.18))
            return blend(rgb('282332'),tone,glow)
        self.paint(horn,'horn-albedo',pixels,256)
        for s,label in [(-1,'left'),(1,'right')]:
            self.sweep(label+' thick curled ram horn',[
                (s*.52,-.10,2.11,0,0),(s*.64,-.19,2.40,.275,.255),
                (s*.90,-.30,2.70,.345,.29),(s*1.23,-.39,2.75,.335,.285),
                (s*1.51,-.47,2.53,.29,.255),(s*1.54,-.54,2.22,.257,.23),
                (s*1.35,-.59,2.04,.188,.17),(s*1.12,-.64,2.10,.107,.098),
                (s*1.10,-.68,2.28,.060,.057),(s*1.24,-.70,2.32,0,0),
            ],horn,axis=(0,1,0),rings=34,sides=22,texture=True)
            cap=self.sphere(label+' rounded inner horn end',(s*1.17,-.686,2.29),(.107,.092,.106),horn)
            b.uv_map(cap,lambda i,f:(.5,.97))
        mat=material('Short ember tail','F35C13')
        self.sweep('Little lifted ram tail',[(.53,.79,.96,0,0),(.66,1.10,1.05,.14,.13),
                   (.73,1.27,1.22,.16,.145),(.74,1.23,1.36,0,0)],mat,rings=14,sides=16)
        self.smile(.785,nose=False)
        self.pink_nose('FF6680',.925,.086)

    def blaze_bat(self):
        ear_shape=bezier((-.36,-.09),[
            ((-.40,.23),(-.25,.67),(-.055,.86)),
            ((.006,.93),(.095,.91),(.16,.79)),
            ((.32,.51),(.36,.18),(.33,-.08)),
            ((.14,-.15),(-.16,-.15),(-.36,-.09)),
        ],7)
        inner=bezier((-.25,.01),[
            ((-.27,.24),(-.16,.56),(-.025,.72)),
            ((.04,.77),(.08,.63),(.15,.43)),
            ((.24,.21),(.23,.05),(.22,.01)),
            ((.10,-.035),(-.12,-.035),(-.25,.01)),
        ],7)
        ears=material('Violet ears with ember insets','54218D')
        self.paint(ears,'ear-albedo',lambda u,v:blend(rgb('54218D'),rgb('FF9200'),
                   smooth(.5+b.distance_to_outline(2*u-1,2*v-1,inner)/.018)),256)
        for s,label in [(-1,'left'),(1,'right')]:
            self.pillow(label+' tall soft bat ear',(s*.56,-.08,2.18),FRONT,ear_shape,ears,(.13,.15),
                        mirror=s==-1,map_mode=lambda x,z,n:(((-x if s==-1 else x)+1)/2,(z+1)/2))
        self.bat_wings()
        tail=material('Violet tail','54218D')
        self.sweep('Tiny bat tail',[(.55,.8,.63,0,0),(.64,1.09,.69,.14,.12),
                   (.75,1.24,.83,.10,.085),(.82,1.24,.94,0,0)],tail,rings=12,sides=14)
        mouth=material('Small smiling bat mouth','2A1639')
        outline=bezier((-.195,.03),[
            ((-.09,-.01),(.09,-.01),(.195,.03)),
            ((.14,-.17),(-.14,-.17),(-.195,.03)),
        ],8)
        self.pillow('Little smiling mouth',(0,-1.022,.787),FRONT,outline,mouth,(.022,.014))
        ivory=material('Ivory baby fangs','FFF0CC')
        for s,label in [(-1,'left'),(1,'right')]:
            self.sweep(label+' small fang',[(s*.126,-1.050,.801,0,0),
                (s*.123,-1.058,.778,.040,.023),(s*.106,-1.060,.709,0,0)],ivory,
                axis=(0,1,0),rings=8,sides=10)

    def bat_wings(self):
        profile=np.array([
            (-.08,-.08,-.08),(.04,.32,-.40),(.21,.60,-.53),(.36,.66,-.34),
            (.54,.56,-.28),(.72,.39,-.29),(.90,.19,-.41),(1.10,-.07,-.07),
        ])
        stations=[b.catmull(profile,(len(profile)-1)*i/60) for i in range(61)]
        outline=[np.array((x,t)) for x,t,l in stations]+[np.array((x,l)) for x,t,l in reversed(stations[1:-1])]
        membrane=material('Orange bat wing membrane','FF8C00')
        def pixels(u,v):
            x,z=-.15+1.36*u,-.62+1.40*v
            edge=smooth((b.distance_to_outline(x,z,outline)-.025)/.035)
            face=blend(rgb('FFB000'),rgb('FF7000'),smooth((.7-z)/1.3))
            rib=.35*np.exp(-((x-(.36+.13*(.65-z)))/.033)**2)
            face=blend(face,rgb('CC4809'),rib)
            return blend(rgb('54218D'),face,edge)
        self.paint(membrane,'wing-albedo',pixels)
        rim=material('Soft violet wing leading edge','54218D')
        for s,label in [(-1,'left'),(1,'right')]:
            def world(x,z,d=0): return (s*(.92+x),.27+.18*x+d,1.58+z)
            rings,sides=30,14
            vertices=[world(*profile[0,:2])];uv=[(0,0)]
            for i in range(1,rings+1):
                x,hi,lo=b.catmull(profile,(len(profile)-1)*i/(rings+1))
                assert hi>lo
                for j in range(sides):
                    a=2*math.pi*j/sides
                    z=(hi+lo)/2+math.sin(a)*(hi-lo)/2
                    vertices.append(world(x,z,math.cos(a)*min(.085,(hi-lo)*.22)))
                    uv.append(((x+.15)/1.36,(z+.62)/1.4))
            vertices.append(world(*profile[-1,:2]));uv.append((1,1))
            obj=self.mesh(label+' scalloped flame wing',vertices,b.caps_and_rings(sides,rings),membrane)
            b.uv_map(obj,lambda i,_:uv[i])
            self.sweep(label+' rounded wing rim', [(*world(x,top),r,r) for (x,top,_),r in zip(profile,
                       [0,.059,.069,.071,.066,.057,.041,0])],rim,axis=(0,1,0),rings=18,sides=12)

    def flame_material(self,name,low,high):
        mat=material(name,low,.34)
        self.paint(mat,name.lower().replace(' ','-')+'-albedo',
                   lambda u,v:blend(rgb(low),rgb(high),smooth(v)),256)
        return mat

    def plume(self,name,stations,mat,**kwargs):
        # The sweep's first radius follows the chosen axis (depth). These
        # feathers are broad in XZ and shallow in Y, rather than round tubes.
        return self.sweep(name,[(x,y,z,depth,width) for x,y,z,width,depth in stations],
                          mat,axis=(0,1,0),**kwargs)

    def inferno_phoenix(self):
        gold=self.flame_material('Golden flight feathers','FF8600','FFF529')
        # Three broad, overlapping feathers per side: simple readable rarity silhouette.
        for s,label in [(-1,'left'),(1,'right')]:
            for j,(root_z,reach,peak,width) in enumerate([(1.18,1.59,1.52,.31),(1.50,1.83,2.10,.37),(1.82,1.76,2.69,.40)]):
                self.plume(label+f' golden wing feather {j+1}',[
                    (s*.78,.17,root_z,0,0),(s*1.04,.17,root_z+.03,width*.80,.125),
                    (s*(reach-.26),.19,(root_z+peak)/2,width,.14),
                    (s*reach,.22,peak-.20,width*.34,.060),
                    (s*(reach+.08),.24,peak,0,0),
                ],gold,rings=18,sides=16,texture=True)
        crest=self.flame_material('Swept golden crest','FF6B00','FFED21')
        self.plume('Single flowing flame crest',[
            (-.10,-.16,2.08,0,0),(-.12,-.15,2.28,.34,.18),(-.20,-.12,2.54,.35,.19),
            (-.04,-.07,2.80,.32,.18),(.26,-.02,2.94,.18,.12),
            (.46,.02,3.08,.060,.050),(.48,.05,3.22,0,0),
        ],crest,rings=24,sides=20,texture=True)
        tail=self.flame_material('Fire tail feathers','EC310F','FFEB21')
        for j,(x,y,z) in enumerate([(1.18,1.47,1.04),(.80,1.86,1.39)]):
            self.plume(f'Sweeping tail feather {j+1}',[
                (.37,.74,.55,0,0),(.58,1.06,.47,.30,.13),
                (x,1.30,.47,.42,.15),(x+.47,y,.64,.45,.16),
                (x+.68,y+.09,z,.20,.095),(x+.78,y+.13,z+.23,0,0),
            ],tail,rings=23,sides=18,texture=True)
        beak=material('Golden round beak','FFB707',.31)
        shape=bezier((-.148,.029),[
            ((-.112,.144),(.102,.142),(.151,.035)),
            ((.124,-.031),(.048,-.123),(0,-.146)),
            ((-.047,-.124),(-.139,-.041),(-.148,.029)),
        ],8)
        self.pillow('Tiny golden beak',(0,-1.04,.89),FRONT,shape,beak,(.135,.026))

    def build(self):
        body=self.body()
        self.paws(.46,.48,.28)
        self.eyes()
        getattr(self, {'CoalMole':'coal_mole','CinderGecko':'cinder_gecko','EmberRam':'ember_ram',
                      'BlazeBat':'blaze_bat','InfernoPhoenix':'inferno_phoenix'}[self.name])()
        return body


def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('pets',nargs='*')
    parser.add_argument('--draft',action='store_true')
    args=parser.parse_args(sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else [])
    for name in args.pets or b.SPECS:
        pet=MagmaPet(name)
        body=pet.build()
        report=b.audit(pet.collection.objects)
        assert report['triangles']<10000, report
        assert abs(report['bounds'][0][2])<.005
        print('MAGMA_AUDIT',name,json.dumps(report),flush=True)
        if not args.draft:
            report['imports'], imported=b.export(pet,body,report)
            (pet.work/'verification.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8',newline='')
        stage,ground,camera=b.preview(pet)
        stage.name='Warm neutral review studio'
        ground.data.materials.clear()
        ground.data.materials.append(material('Warm light backdrop','EAD6C3',.93))
        target=(0,.24,1.44)
        front=(4.35,-10.45,3.62)
        if args.draft:
            b.render(stage,camera,target,front,pet.work/'draft-front.png',560,14)
            continue
        b.render(stage,camera,target,front,pet.work/'front-three-quarter.png',780,32)
        b.render(stage,camera,target,(6.4,9.2,4.9),pet.work/'rear-three-quarter.png',780,32)
        for ext,check in imported.items():
            for obj in stage.objects:
                if obj.name not in pet.collection.objects: check.collection.objects.link(obj)
            check.world=stage.world
            b.render(check,camera,target,front,pet.work/f'roundtrip-{ext}.png',400,14)
        ground.hide_render=True
        if name in {'CinderGecko','EmberRam','InfernoPhoenix'}: pet.root.scale.x=-1
        b.render(stage,camera,target,(-5.05,-10.5,5.37),pet.work/'ui-source.png',768,30,.83,alpha=True)


if __name__=='__main__': main()
