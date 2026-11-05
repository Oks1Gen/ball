import json,struct
from pathlib import Path
BASE=Path(__file__).resolve().parent.parent
with open(BASE/'model/nautilus-shell.glb','rb') as f:
    f.read(12);length,kind=struct.unpack('<II',f.read(8));data=json.loads(f.read(length))
def srgb(v):return 12.92*v if v<=.0031308 else 1.055*v**(1/2.4)-.055
parts={}
for m in data['meshes']:
    for i,p in enumerate(m['primitives']):
        material=data['materials'][p['material']]
        rgba=material['pbrMetallicRoughness']['baseColorFactor']
        name=m['name']+(str(i+1) if i else '')
        canonical=m['name'].replace('_PeriodicMesh','').replace('_Mesh','')+(f'_Material{i+1}' if i else '')
        parts[name]={'canonical':canonical,'color':[srgb(v) for v in rgba[:3]],'alpha':rgba[3], 'material':material['name']}
(BASE/'work/import-manifest.json').write_text(json.dumps({'parts':parts},separators=(',',':')),encoding='utf-8')
print(len(parts),'expected MeshParts')
