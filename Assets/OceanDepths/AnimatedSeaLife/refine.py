"""Incremental art pass: moon jelly variant, attached squid eyes, fishlike angler rig."""
import bpy,json,importlib.util,copy
from pathlib import Path
OUT=Path(__file__).resolve().parent
spec=importlib.util.spec_from_file_location('builder',OUT/'build.py');b=importlib.util.module_from_spec(spec);spec.loader.exec_module(b)
bpy.ops.wm.open_mainfile(filepath=str(OUT/'animated-wildlife.blend'))
sea=json.loads((OUT.parent/'sea-life-geometry.json').read_text());kit=json.loads((OUT.parent/'LocationKit/location-kit-geometry.json').read_text())
manifest=json.loads((OUT/'rig-manifest.json').read_text())
for name,source,kind in [('YellowTang',sea['YellowTang'],'Fish'),('Anglerfish',kit['Anglerfish'],'Fish'),('AbyssSquid',kit['AbyssSquid'],'Squid'),('MoonJellyfish',kit['ReefJellyfish'],'Jelly')]:
    old=bpy.data.collections.get(name)
    if old:
        for obj in list(old.objects):bpy.data.objects.remove(obj,do_unlink=True)
        bpy.data.collections.remove(old)
    groups=copy.deepcopy(source)
    if name=='AbyssSquid':
        for g in groups:
            if g['name']=='Features':
                for v in g['v']: v[0]*=.57;v[2]*=.72
    if name=='MoonJellyfish':
        tones={'F3A1E5':'9FE7EF','EC88D1':'68C3E0','FFB7EB':'C4FFF2','EEADD8':'A3DFEB','FFD3EE':'E0FFF2'}
        for g in groups:
            for v in g['v']:v[0]*=1.12;v[2]*=1.12
            for t in g['t']:t[1]=tones.get(t[1],t[1])
    entry=b.build(name,groups,kind)
    manifest=[m for m in manifest if m['name']!=name]+[entry]
(OUT/'rig-manifest.json').write_text(json.dumps(manifest,indent=2),encoding='utf-8',newline='')
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'animated-wildlife.blend'))
print('REFINED',[m['name'] for m in manifest])
