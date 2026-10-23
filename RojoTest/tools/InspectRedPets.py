"""Inspect the provided pet pack in a background Blender process; never save it."""
import bpy
import json

def normalized_body_width(root):
    graph = bpy.context.evaluated_depsgraph_get()
    heights = []
    body = next(o for o in root.children_recursive if o.name.startswith("Cube pet body"))
    for obj in root.children_recursive:
        if obj.type not in {"MESH", "CURVE"} or obj.hide_render:
            continue
        evaluated = obj.evaluated_get(graph)
        mesh = evaluated.to_mesh(preserve_all_data_layers=True, depsgraph=graph)
        heights.extend((obj.matrix_world @ v.co).z for v in mesh.vertices)
        evaluated.to_mesh_clear()
    return body.dimensions.x * 3 / (max(heights) - min(heights))

print("RED_PETS_INSPECT=" + json.dumps({
    "file": bpy.data.filepath,
    "collections": [{"name": c.name, "objects": len(c.objects), "children": [x.name for x in c.children]} for c in bpy.data.collections],
    "pet_roots": [{"name": o.name, "children": len(o.children_recursive)} for o in bpy.data.objects if o.type == "EMPTY" and o.name[:2].isdigit()],
    "object_count": len(bpy.data.objects),
    "normalized_body_widths": {o.name: normalized_body_width(o) for o in bpy.data.objects if o.type == "EMPTY" and o.name[:2] in {"06", "09", "21", "25"}},
    "bodies": [{"name": o.name, "parent": o.parent.name if o.parent else None, "dimensions": list(o.dimensions)} for o in bpy.data.objects if o.type == "MESH" and ("body" in o.name.lower() or "cube" in o.name.lower())],
    "images": [{"name": i.name, "path": i.filepath, "packed": bool(i.packed_file)} for i in bpy.data.images],
}, ensure_ascii=False))
