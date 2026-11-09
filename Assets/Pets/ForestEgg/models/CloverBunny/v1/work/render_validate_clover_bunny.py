import bpy, json
from pathlib import Path
from mathutils import Vector

BASE=Path('C:/Users/dakem/Documents/RobloxGames/ball/Assets/Pets/ForestEgg/models/CloverBunny/v1')
WORK=BASE/'work'
asset_scene=bpy.data.scenes['CloverBunny'];preview=bpy.data.scenes['CB_Preview']
helpers=bpy.data.collections['CB_PreviewOnly'];cam=preview.camera
def camera_at(loc):
    cam.location=loc;cam.rotation_euler=(Vector((0,0,1.78))-cam.location).to_track_quat('-Z','Y').to_euler()
camera_at((5,-8,5))
preview.render.filepath=str(WORK/'front-three-quarter.png')
bpy.ops.render.render(write_still=True,scene=preview.name)
camera_at((-5,7,4.5))
preview.render.filepath=str(WORK/'rear-three-quarter.png')
bpy.ops.render.render(write_still=True,scene=preview.name)
camera_at((5,-8,5))
for label in ('BLEND','GLB','FBX'):
    sc=bpy.data.scenes['CB_Roundtrip_'+label]
    sc.collection.children.link(helpers)
    sc.world=preview.world;sc.camera=cam
    sc.render.engine='CYCLES';sc.cycles.samples=24;sc.cycles.use_denoising=True
    sc.view_settings.view_transform='Standard';sc.view_settings.look='None';sc.view_settings.exposure=.20
    sc.render.resolution_x=512;sc.render.resolution_y=512;sc.render.resolution_percentage=100
    sc.render.image_settings.file_format='PNG';sc.render.filepath=str(WORK/('roundtrip-'+label.lower()+'.png'))
    bpy.ops.render.render(write_still=True,scene=sc.name)

# Remove only our verification scenes/copies; preserve user scene and authoring asset.
preserved=set(bpy.data.collections['CloverBunny_Asset'].objects)|set(helpers.objects)
for sc in list(bpy.data.scenes):
    if sc.name.startswith('CB_Roundtrip_') or sc.name=='CB_Export_Check':
        for ob in list(sc.objects):
            if ob not in preserved:bpy.data.objects.remove(ob,do_unlink=True)
        bpy.data.scenes.remove(sc)
bpy.context.window.scene=asset_scene;bpy.context.view_layer.update()
for o in bpy.context.selected_objects:o.select_set(False)
bpy.context.view_layer.objects.active=bpy.data.objects['CB_Body']
for a in bpy.context.screen.areas:
    if a.type=='VIEW_3D':
        a.spaces.active.shading.type='MATERIAL'
        a.spaces.active.region_3d.view_location=(0,0,1.8)
        a.spaces.active.region_3d.view_distance=6.3
        a.spaces.active.region_3d.view_rotation=cam.rotation_euler.to_quaternion()
        a.spaces.active.region_3d.view_perspective='ORTHO'
bpy.ops.wm.save_as_mainfile(filepath=str(WORK/'authoring-session.blend'),copy=True)
result={'renders':['front-three-quarter.png','rear-three-quarter.png','roundtrip-blend.png','roundtrip-glb.png','roundtrip-fbx.png'],'active_scene':asset_scene.name,'clean_scene_objects':len(asset_scene.objects),'original_scene_objects':len(bpy.data.scenes['Scene'].objects)}
