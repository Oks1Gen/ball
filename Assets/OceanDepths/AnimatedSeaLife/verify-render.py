"""Round-trip both export formats; render ROM frames from complementary views."""
import bpy,json,math,sys
from pathlib import Path
from mathutils import Vector
OUT=Path(__file__).resolve().parent
source=OUT/'animated-wildlife.blend'
meta=json.loads((OUT/'rig-manifest.json').read_text())
reports=[]
for entry in meta:
    for suffix in ('glb','fbx'):
        bpy.ops.wm.read_factory_settings(use_empty=True)
        if suffix=='glb': bpy.ops.import_scene.gltf(filepath=str(OUT/(entry['name']+'.glb')))
        else: bpy.ops.import_scene.fbx(filepath=str(OUT/(entry['name']+'.fbx')))
        rigs=[o for o in bpy.context.scene.objects if o.type=='ARMATURE']; meshes=[o for o in bpy.context.scene.objects if o.type=='MESH' and any(m.type=='ARMATURE' for m in o.modifiers)]
        assert len(rigs)==1 and len(meshes)==1,(entry['name'],suffix,'structure')
        assert len(rigs[0].data.bones)==entry['bones']
        for v in meshes[0].data.vertices:
            weights=[g.weight for g in v.groups if g.weight>.00001]
            assert 1<=len(weights)<=4 and abs(sum(weights)-1)<.001
        reports.append({'name':entry['name'],'format':suffix,'bones':len(rigs[0].data.bones),'vertices':len(meshes[0].data.vertices)})
(OUT/'roundtrip-validation.json').write_text(json.dumps(reports,indent=2),encoding='utf-8',newline='')
bpy.ops.wm.open_mainfile(filepath=str(source))
scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.samples=12
scene.render.resolution_x=600;scene.render.resolution_y=450;scene.render.resolution_percentage=100
scene.world=bpy.data.worlds.new('QA World');scene.world.color=(.25,.25,.25)
scene.view_settings.view_transform='Standard'
for name in [m['name'] for m in meta]:
    for c in scene.collection.children:c.hide_render=c.name!=name
    obj=bpy.data.objects[name];bpy.context.view_layer.update()
    coords=[obj.matrix_world@Vector(c) for c in obj.bound_box];center=sum(coords,Vector())/8
    radius=max((p-center).length for p in coords)
    views=[('top',(0,-.1,3)),('underside',(0,1,-3))] if '--extra-views' in sys.argv else [('front',(1,-2,1)),('back',(-1,2,-.35))]
    for view,direction in views:
        camdata=bpy.data.cameras.new('QA');cam=bpy.data.objects.new('QA',camdata);scene.collection.objects.link(cam)
        cam.location=center+Vector(direction).normalized()*radius*3.5;cam.rotation_euler=(center-cam.location).to_track_quat('-Z','Y').to_euler()
        camdata.type='ORTHO';camdata.ortho_scale=radius*2.4;scene.camera=cam
        lights=[]
        for offset,power,size in [((1,-2,3),1800,8),((-2,1,1),1200,7)]:
            ld=bpy.data.lights.new('QA','AREA');ld.energy=power;ld.shape='DISK';ld.size=size*max(1,radius/4)
            light=bpy.data.objects.new('QA',ld);scene.collection.objects.link(light);light.location=center+Vector(offset)*max(3,radius)
            light.rotation_euler=(center-light.location).to_track_quat('-Z','Y').to_euler();lights.append(light)
        for frame in ((31,) if '--extra-views' in sys.argv else (1,31,61,91)):
            scene.frame_set(frame);scene.render.filepath=str(OUT/(name+'-'+view+'-'+str(frame)+'.png'));bpy.ops.render.render(write_still=True)
        for o in [cam]+lights:bpy.data.objects.remove(o,do_unlink=True)
print('ROUNDTRIP_AND_RENDER_PASS',len(reports))
