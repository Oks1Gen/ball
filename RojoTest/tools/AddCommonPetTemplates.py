"""Register the four selected persistent red-egg meshes in the Rojo template file."""
from copy import deepcopy
from pathlib import Path
import json
import xml.etree.ElementTree as ET

project = Path(__file__).resolve().parents[1]
path = project / "assets/pets/pack36/UncommonPetTemplates.rbxmx"
assets = json.loads((project / "assets/pets/red30/common-egg-assets.json").read_text(encoding="utf-8"))
tree = ET.parse(path)
folder = tree.getroot().find("Item[@class='Folder']")
sample = folder.find("Item[@class='Model']")
assert sample is not None
for asset in assets:
    pet_id = asset["id"]
    existing = next((m for m in folder.findall("Item") if m.findtext("Properties/string[@name='Name']") == pet_id), None)
    if existing is not None:
        assert existing.findtext("Item/Properties/Content[@name='MeshId']/url") == asset["meshId"]
        continue
    model = deepcopy(sample)
    model.set("referent", pet_id)
    model.find("Properties/string[@name='Name']").text = pet_id
    body = model.find("Item[@class='MeshPart']")
    body.set("referent", pet_id + "Body")
    props = body.find("Properties")
    props.find("Content[@name='MeshId']/url").text = asset["meshId"]
    texture = ET.SubElement(props, "Content", {"name": "TextureID"})
    ET.SubElement(texture, "url").text = asset["texture"]
    assert asset["texture"].startswith("rbxassetid://")
    for property_name, values in (("Size", [v * 1.8 / asset["bodyWidth"] for v in asset["size"]]), ("MeshSize", asset["meshSize"])):
        for axis, value in zip("XYZ", values):
            props.find(f"Vector3[@name='{property_name}']/{axis}").text = str(value)
    # The new pack has baked atlas colors, not the old pack's normal map.
    for appearance in body.findall("Item[@class='SurfaceAppearance']"):
        body.remove(appearance)
    folder.append(model)
tree.write(path, encoding="utf-8", xml_declaration=False)
print("Four red-egg pet templates registered; all earlier templates retained")
