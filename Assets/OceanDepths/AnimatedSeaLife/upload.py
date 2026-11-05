"""Upload the generated rigs with a resumable journal per species. No secrets in output."""
import concurrent.futures
import json
import os
import sys
from pathlib import Path

OUT=Path(__file__).resolve().parent
REPO=OUT.parents[2]
sys.path.insert(0,str(REPO/'.tools/python-libs'))
sys.path.insert(0,'C:/Users/dakem/Documents/SecondBrain/skills/roblox-3d-model/scripts')
from upload_asset import upload

def one(entry):
    name=entry['name']
    creator={'userId':os.environ['ROBLOX_USER_ID']}
    result=upload(OUT/(name+'.glb'),'Ball_Ocean_'+name+'_Animated','Model',
                  'Blender-authored animated wildlife for Ball Ocean Depths.',
                  os.environ['ROBLOX_API_KEY'],creator,None,
                  journal=REPO/'.tools'/('ocean-upload-'+name+'.json'),timeout=50)
    print(name,result,flush=True)
    return name,result

manifest=json.loads((OUT/'rig-manifest.json').read_text(encoding='utf-8'))
with concurrent.futures.ThreadPoolExecutor(max_workers=3) as pool:
    results=dict(pool.map(one,manifest))
(OUT/'roblox-assets.json').write_text(json.dumps(results,indent=2),encoding='utf-8',newline='')
