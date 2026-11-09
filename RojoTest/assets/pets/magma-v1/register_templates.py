"""Install the approved Magma assets into the Rojo pet template library."""
import copy
import json
from pathlib import Path
import xml.etree.ElementTree as ET

here=Path(__file__).resolve().parent
assets=json.loads((here/'roblox-assets.json').read_text(encoding='utf-8'))['assets']
path=here.parent/'pack36/UncommonPetTemplates.rbxmx'
tree=ET.parse(path)
folder=tree.getroot().find('Item')
def name(item): return item.find("Properties/string[@name='Name']").text
old_names={'Shark','CloudBird','AngelCat','IceCat'}
archive=here/'previous-templates.rbxmx'
if not archive.exists():
    original=ET.Element('roblox',version='4')
    backup=ET.SubElement(original,'Item',{'class':'Folder','referent':'PreviousMagmaPets'})
    props=ET.SubElement(backup,'Properties')
    ET.SubElement(props,'string',name='Name').text='PreviousMagmaPets'
    old=[x for x in folder.findall('Item') if name(x) in old_names]
    assert len(old)==4
    for item in old: backup.append(copy.deepcopy(item))
    archive.write_text(ET.tostring(original,encoding='unicode')+'\n',encoding='utf-8',newline='')
source=next(x for x in folder.findall('Item') if name(x)=='BloomFox')
for item in list(folder.findall('Item')):
    if name(item) in old_names | {a['visual'] for a in assets}: folder.remove(item)
for asset in assets:
    model=copy.deepcopy(source)
    model.set('referent',asset['visual'])
    model.find("Properties/string[@name='Name']").text=asset['visual']
    part=model.find('Item')
    part.set('referent',asset['visual']+'Body')
    props=part.find('Properties')
    for prop,key in [('MeshId','meshId'),('TextureID','textureId')]: props.find(f"Content[@name='{prop}']/url").text=asset[key]
    for axis,value in zip('XYZ',asset['meshSize']):
        props.find(f"Vector3[@name='Size']/{axis}").text=str(value*.9)
        props.find(f"Vector3[@name='MeshSize']/{axis}").text=str(value)
    for p in props.find("CoordinateFrame[@name='CFrame']"):
        p.text='1' if p.tag in {'R00','R11','R22'} else '0'
    for p in props.find("Color3[@name='Color']"): p.text='1'
    folder.append(model)
assert len(folder.findall('Item'))==19
path.write_text(ET.tostring(tree.getroot(),encoding='unicode')+'\n',encoding='utf-8',newline='')
print('Registered five Magma models; 19 templates, four prior models archived off-scene.')
