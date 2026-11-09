"""Sculpt the Solar Crown Egg pets and render their Blender review views."""
import argparse
import json
import math
import sys
from pathlib import Path

import bpy
import numpy as np

MODELS = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(MODELS.parents[1] / 'FrostEgg/models/work'))
import build_frost as shared

SPECS = {
    'HoneyBee': ('Honey Bee', 'FFBD10', 'FFDEA7', '693509', 'amber', .424, 1.06, .276, .284),
    'DawnChick': ('Dawn Chick', 'FFB232', 'FFE4BA', 'FB850A', 'blue', .421, 1.09, .270, .279),
    'SunLion': ('Sun Lion', 'FF9A2C', 'FFE6BA', 'FFCC91', 'green', .413, 1.08, .264, .273),
    'SkyPegasus': ('Sky Pegasus', 'FFE1AC', 'FFF0D0', 'FFE3B1', 'blue', .420, 1.03, .270, .279),
    'SolarSeraph': ('Solar Seraph', 'FFE6BA', 'FFF1D5', 'FFE5B5', 'amber', .420, 1.00, .276, .286),
}
shared.MODELS = MODELS
shared.SPECS = SPECS
rgb, blend, smooth = shared.rgb, shared.blend, shared.smooth
material, bezier = shared.material, shared.bezier
FRONT = shared.FRONT_AXES
SIDES = [(-1, 'left'), (1, 'right')]


class SolarPet(shared.Pet):
    def __init__(self, name):
        super().__init__(name)
        self.root['Reference'] = 'Assets/Pets/SolarCrownEgg/reference.png'
        self.root['ScaleBrief'] = 'Two-unit cube, front -Y, +Z up, origin at feet'

    def cube(self, name, center, dimensions, radius, mat):
        bpy.ops.mesh.primitive_cube_add(size=2, location=center)
        obj = self.attach(bpy.context.object, name, mat)
        obj.scale = tuple(size / 2 for size in dimensions)
        bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
        bevel = obj.modifiers.new('Soft square edges', 'BEVEL')
        bevel.width, bevel.segments = radius, 7
        bpy.ops.object.modifier_apply(modifier=bevel.name)
        normal = obj.modifiers.new('Flat face normals', 'WEIGHTED_NORMAL')
        normal.keep_sharp = True
        return obj

    def body(self):
        coat = material('Soft painted cube', self.coat)
        lion = self.name == 'SunLion'
        bee = self.name == 'HoneyBee'
        dip = 1.36 if not bee else 1.25
        top = 1.69 if not bee else 1.60
        mask = bezier((0, dip), [
            ((-.24, top+.13), (-.65, top+.11), (-.81, top-.13)),
            ((-.92, top-.32), (-.93, .70), (-.81, .54)),
            ((-.67, .38), (-.47, .38), (0, .38)),
            ((.47, .38), (.67, .38), (.81, .54)),
            ((.93, .70), (.92, top-.32), (.81, top-.13)),
            ((.65, top+.11), (.24, top+.13), (0, dip)),
        ], 11)

        def pixels(u, v):
            x, z = 2*(2*u % 1)-1, .24+2*v
            base = rgb('FFAA39' if lion else self.coat)
            front = blend(base, rgb(self.cream), smooth(.5+shared.distance_to_outline(x, z, mask)/.013))
            cheek = ((np.abs(x)-.664)/.153)**2+((z-.795)/.131)**2
            front = blend(front, rgb('FF5680'), .78*np.exp(-1.58*cheek))
            side = np.broadcast_to(base, front.shape)
            if bee:
                # A single continuous UV coordinate follows the head-to-tail axis.
                stripes = np.maximum(smooth((.169-np.abs(x-.14))/.014),
                                     smooth((.110-np.abs(x-.705))/.014))
                side = blend(side, rgb('69340B'), stripes)
            return np.where((u < .5)[..., None], front, side)

        self.paint(coat, 'body-albedo', pixels, 1024 if bee else 512)
        if lion:
            self.cube('Rear orange cube', (0, .17, 1.24), (2, 1.66, 2), .215,
                      material('Golden orange coat', self.coat))
            body = self.cube('Rounded square face panel', (0, -.727, 1.242), (1.84, .546, 1.88), .170, coat)
        else:
            body = self.cube('Square body', (0, 0, 1.24), (2, 2, 2), .205, coat)

        def project(i, face):
            x, y, z = body.data.vertices[i].co
            if face.normal.y < -.18:
                return (.25+.243*x, (z+1)*.5)
            if bee:
                return (.75+.243*y, (z+1)*.5)
            return (.98, .97)

        shared.uv_map(body, project)
        return body

    def gradient(self, name, low, high, roughness=.34):
        mat = material(name, low, roughness)
        self.paint(mat, name.lower().replace(' ', '-')+'-albedo',
                   lambda u, v: blend(rgb(low), rgb(high), smooth(v)), 256)
        return mat

    def plume(self, name, stations, mat, **options):
        return self.sweep(name, [(x,y,z,depth,width) for x,y,z,width,depth in stations],
                          mat, axis=(0,1,0), **options)

    def honey_bee(self):
        dark = material('Caramel antennae', '743B0C')
        yellow = material('Gold antenna tips', 'FFC200', .29)
        wing = material('Ivory bee wings', 'FFEDBD', .33)
        outline = bezier((-.245,-.115), [
            ((-.326,.005),(-.37,.27),(-.255,.57)),
            ((-.143,.90),(.204,1.02),(.385,.874)),
            ((.568,.713),(.501,.378),(.264,.108)),
            ((.081,-.082),(-.09,-.17),(-.245,-.115)),
        ], 8)
        def wing_pixels(u, v):
            x, z = 1.22*u-.57, 1.19*v-.20
            rim = smooth((.052-shared.distance_to_outline(x, z, outline))/.060)
            pearl = blend(rgb('FFE5A0'), rgb('FFF9E8'), smooth(v/.88))
            return blend(pearl, rgb('FFF9E9'), .87*rim)
        self.paint(wing, 'wing-albedo', wing_pixels, 256)
        for s, side in SIDES:
            self.sweep(side+' short bent antenna', [
                (s*.42,-.72,2.12,0,0),(s*.433,-.717,2.21,.125,.115),
                (s*.446,-.710,2.35,.125,.106),(s*.488,-.719,2.50,.111,.098),
                (s*.576,-.72,2.59,.083,.076),(s*.618,-.729,2.64,0,0),
            ], dark, rings=16, sides=15)
            self.sphere(side+' golden antenna bulb', (s*.594,-.723,2.620), (.184,.17,.186), yellow)
            self.pillow(side+' pillowy ivory wing',(s*.43,.37,2.19),
                        ((.92,-s*.39,0),(0,.39,.921)),outline,wing,(.092,.078),mirror=s<0,
                        dish=.024,map_mode=lambda x,z,n:((x+.57)/1.22,(z+.20)/1.19))
        self.smile(.79)

    def dawn_chick(self):
        wing = material('Orange chick wings', 'FF941B', .37)
        outline = bezier((-.24,-.27), [
            ((-.37,-.13),(-.27,.14),(-.07,.29)),
            ((.13,.48),(.37,.61),(.47,.48)),
            ((.55,.37),(.46,.20),(.36,.115)),
            ((.52,.13),(.52,-.008),(.39,-.166)),
            ((.22,-.35),(-.11,-.43),(-.24,-.27)),
        ], 8)
        for s, side in SIDES:
            self.pillow(side+' soft chick wing',(s*1.019,-.61,1.14),((s*.67,.742,0),(0,0,1)),
                        outline,wing,(.165,.133) if s>0 else (.133,.165))
        crest = self.gradient('Orange swept comb', 'F88203', 'FFAF24')
        self.plume('Short second comb lobe', [
            (-.17,.06,2.09,0,0),(-.06,.11,2.23,.23,.14),(.20,.14,2.32,.17,.11),
            (.41,.18,2.40,.08,.062),(.51,.20,2.49,0,0),
        ], crest, rings=14, sides=14, texture=True)
        self.plume('Swept forelock of orange feathers', [
            (-.26,-.50,2.13,0,0),(-.28,-.47,2.34,.244,.234),(-.20,-.39,2.55,.285,.212),
            (.065,-.30,2.72,.254,.177),(.33,-.23,2.83,.168,.118),
            (.49,-.15,2.96,.077,.055),(.51,-.11,3.07,0,0),
        ], crest, rings=25, sides=20, texture=True)
        beak = bezier((-.126,.029), [
            ((-.115,.105),(-.037,.162),(0,.150)),((.055,.14),(.123,.084),(.126,.028)),
            ((.091,-.041),(.037,-.111),(0,-.132)),((-.04,-.112),(-.097,-.032),(-.126,.029)),
        ], 6)
        orange = self.gradient('Glossy golden beak', 'ED7803', 'FFC12A', .29)
        self.pillow('Tiny chick beak',(0,-1.028,.895),FRONT,beak,orange,(.117,.031),
                    map_mode=lambda x,z,n:((x+.16)/.32,(z+.16)/.34))

    def sun_lion(self):
        mane = self.gradient('Golden mane petals', 'FFA600', 'FFCD18')
        petal = bezier((-.25,-.31), [
            ((-.388,-.204),(-.489,.146),(-.379,.395)),
            ((-.294,.600),(-.129,.727),(0,.753)),
            ((.132,.729),(.302,.615),(.397,.416)),
            ((.50,.189),(.396,-.157),(.255,-.31)),
            ((.147,-.416),(-.133,-.421),(-.25,-.31)),
        ], 5)
        for i in range(8):
            angle = i*math.tau/8
            c, s = math.cos(angle), math.sin(angle)
            reach = [.822,.716,.716,.73,.50,.73,.716,.716][i]
            scale = [1.02,.94,1,.94,.64,.94,1,.94][i]
            self.pillow(f'Mane petal {i+1}',(s*reach,-.72,1.235+c*reach),
                        ((c,0,-s),(s,0,c)),[np.asarray(p)*scale for p in petal],mane,(.249,.216),
                        map_mode=lambda x,z,n:((x+.56)/1.12,(z+.44)/1.25))
        gold = material('Yellow lion tail', 'FFBA06', .36)
        tuft = self.gradient('Orange tail tuft', 'ED7400', 'FFA619')
        self.sweep('Curved lion tail',[
            (.58,.68,.68,0,0),(.85,.84,.69,.139,.133),(1.22,.94,.73,.147,.129),
            (1.52,.98,.88,.126,.115),(1.69,1.00,1.13,.114,.102),(1.75,.99,1.41,.109,.092),
            (1.74,.97,1.69,0,0),
        ],gold,rings=24,sides=16)
        self.plume('Rounded pointed tail tuft', [
            (1.73,.99,1.43,0,0),(1.72,.99,1.57,.222,.195),(1.72,.97,1.79,.267,.213),
            (1.77,.95,1.98,.222,.171),(1.86,.93,2.16,.105,.088),(1.87,.92,2.28,0,0),
        ],tuft,rings=20,sides=18,texture=True)
        self.smile(.82)

    def hooves(self):
        self.paws(.44,.46,.287)
        mat = material('Ivory hooves with a gold rim', self.feet, .30)
        def hoof_pixels(u, v):
            lower = blend(rgb('EF8800'), rgb('FFCB1F'), smooth(v/.37))
            return blend(lower, rgb(self.feet), smooth((v-.45)/.045))
        self.paint(mat, 'hooves-albedo', hoof_pixels, 128)
        for obj in self.collection.objects:
            if not obj.name.endswith(' paw'):
                continue
            obj.name = obj.name.removesuffix(' paw')+' hoof'
            obj.data.materials[0] = mat
            shared.uv_map(obj, lambda i, face: (.5, obj.data.vertices[i].co.z/.287))

    def feather_wings(self, seraph):
        ivory = self.gradient('Ivory flight feathers', 'FFD492', 'FFF1D8')
        gold = None if seraph else self.gradient('Golden wing primaries', 'F28B00', 'FFD729')
        layout = [(1.00,1.88,1.44,.239),(1.29,2.21,1.98,.305),(1.59,2.24,2.79,.338)] if seraph else [
            (1.00,1.68,1.38,.204),(1.25,1.92,1.79,.254),(1.50,1.92,2.36,.286),
        ]
        lobe = bezier((0,-.18), [
            ((-.055,.33),(.35,.89),(.72,.89)),
            ((.91,.91),(1.02,.65),(1.00,.13)),
            ((.98,-.54),(.81,-.97),(.55,-1.02)),
            ((.29,-1.04),(.05,-.75),(0,-.18)),
        ],6)
        for s, side in SIDES:
            feathers = [(f'ivory feather {i+1}', root, reach, tip, width, .13, ivory)
                        for i,(root,reach,tip,width) in enumerate(layout)]
            if gold:
                feathers.append(('outer golden primary', 1.48, 2.22, 2.58, .28, .38, gold))
            for name, root, reach, tip, width, depth, mat in feathers:
                dx,dz = reach-.79,tip-root
                length = math.hypot(dx,dz)
                shape = [(x*length,z*width) for x,z in lobe]
                self.pillow(side+' '+name,(s*.79,depth,root),
                            ((s*dx/length,0,dz/length),(-s*dz/length,0,dx/length)),
                            shape,mat,(.183,.161) if s>0 else (.161,.183),
                            map_mode=lambda x,z,n:(.5,x/length))

    def sky_pegasus(self):
        outer = bezier((-.284,-.095), [
            ((-.318,.100),(-.262,.420),(-.122,.575)),
            ((-.051,.666),(.117,.408),(.206,.236)),
            ((.260,.128),(.277,.028),(.266,-.101)),
            ((.132,-.142),(-.156,-.135),(-.284,-.095)),
        ], 8)
        inner = bezier((-.173,-.064), [
            ((-.216,.147),(-.160,.410),(-.087,.476)),
            ((-.007,.406),(.125,.206),(.154,-.061)),
            ((.047,-.107),(-.090,-.108),(-.173,-.064)),
        ], 8)
        ear = material('Vanilla ear with pink centre', 'FFE3B2')
        self.paint(ear,'ear-albedo',lambda u,v:blend(rgb('FFE3B2'),rgb('FF916E'),
                   smooth(.5+shared.distance_to_outline(2*u-1,2*v-1,inner)/.018)),256)
        for s, side in SIDES:
            self.pillow(side+' rounded upright ear',(s*.62,-.43,2.16),FRONT,outer,ear,(.142,.128),mirror=s>0,
                        map_mode=lambda x,z,n:((x+1)/2,(z+1)/2) if n>0 else (.96,.95))
        gold = self.gradient('Golden forelock and tail', 'FFA100', 'FFD22B', .32)
        self.plume('Sweeping gold forelock', [
            (-.12,-1.023,1.985,0,0),(-.218,-.968,2.154,.174,.110),
            (-.262,-.735,2.355,.299,.169),(-.155,-.524,2.578,.333,.206),
            (.107,-.334,2.716,.260,.164),(.289,-.251,2.823,.143,.099),
            (.342,-.181,2.936,.068,.056),(.309,-.143,3.032,0,0),
        ],gold,rings=22,sides=16,texture=True)
        self.plume('Broad curling golden tail', [
            (.32,.774,1.12,0,0),(.45,1.02,1.25,.229,.202),(.66,1.27,1.09,.298,.227),
            (.90,1.50,.73,.341,.211),(1.15,1.63,.44,.313,.184),
            (1.42,1.65,.42,.208,.134),(1.62,1.63,.54,.098,.064),(1.70,1.59,.72,0,0),
        ],gold,rings=22,sides=16,texture=True)
        self.feather_wings(seraph=False)
        self.smile(.77)

    def solar_seraph(self):
        gold = material('Polished golden halo', 'FFC006', .28)
        self.paint(gold, 'halo-albedo', lambda u,v: blend(
            blend(rgb('ED8A00'), rgb('FFC300'), .5+.5*np.cos(2*math.pi*(u-.15))),
            rgb('FFED8A'),.85*(.5+.5*np.cos(2*math.pi*(v-.18)))**7), 256)
        bpy.ops.mesh.primitive_torus_add(major_segments=64, minor_segments=14, major_radius=1.04,
                                        minor_radius=.135, location=(0,.554,2.06),rotation=(math.pi/2,0,0))
        halo = self.attach(bpy.context.object,'Raised circular halo',gold)
        halo.scale = (1.065,1,.68)
        bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
        # Tiny raised four-sided sun jewel on the forehead.
        x, z, y = .205, 1.805, -1.013
        vertices = [(0,y,z+x),(x,y,z),(0,y,z-x),(-x,y,z),(0,y-.148,z),(0,y+.043,z)]
        jewel = self.mesh('Golden forehead diamond',vertices,
                          [(i,(i+1)%4,pole) for i in range(4) for pole in (4,5)],
                          material('Golden crown gem','FFB600',.27))
        for poly in jewel.data.polygons:
            poly.use_smooth = False
        bevel = jewel.modifiers.new('Tiny polished bevel', 'BEVEL')
        bevel.width, bevel.segments = .016, 3
        self.feather_wings(seraph=True)
        self.smile(.747)

    def build(self):
        body = self.body()
        if self.name in {'SkyPegasus', 'SolarSeraph'}:
            self.hooves()
        else:
            self.paws(.462,.48,.28)
        self.eyes()
        builders = {
            'HoneyBee': self.honey_bee,
            'DawnChick': self.dawn_chick,
            'SunLion': self.sun_lion,
            'SkyPegasus': self.sky_pegasus,
            'SolarSeraph': self.solar_seraph,
        }
        builders[self.name]()
        return body


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('pets', nargs='*')
    parser.add_argument('--draft', action='store_true')
    args = parser.parse_args(sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else [])
    for name in args.pets or SPECS:
        pet = SolarPet(name)
        body = pet.build()
        report = shared.audit(pet.collection.objects)
        assert report['triangles'] < 10000 and abs(report['bounds'][0][2]) < .005, report
        print('SOLAR_AUDIT', name, json.dumps(report), flush=True)
        if not args.draft:
            report['imports'], imported = shared.export(pet, body, report)
            (pet.work/'verification.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8',newline='')
        stage, ground, camera = shared.preview(pet)
        stage.name = 'Solar Crown Egg studio'
        ground.data.materials.clear()
        ground.data.materials.append(material('Soft warm backdrop', 'E9DCC0', .92))
        target, front = (0,.18,1.43), (4.55,-10.6,3.67)
        if args.draft:
            shared.render(stage,camera,target,front,pet.work/'draft-front.png',540,12)
            continue
        shared.render(stage,camera,target,front,pet.work/'front-three-quarter.png',768,26)
        shared.render(stage,camera,target,(6.4,9.2,4.9),pet.work/'rear-three-quarter.png',768,26)
        for ext, check in imported.items():
            for obj in stage.objects:
                if obj.name not in pet.collection.objects:
                    check.collection.objects.link(obj)
            check.world = stage.world
            shared.render(check,camera,target,front,pet.work/f'roundtrip-{ext}.png',400,14)
        ground.hide_render = True
        if name in {'SunLion', 'SkyPegasus'}:
            pet.root.scale.x = -1
        shared.render(stage,camera,target,(-4.8,-10.6,4.52),pet.work/'ui-source.png',768,26,.83,alpha=True)


if __name__ == '__main__':
    main()
