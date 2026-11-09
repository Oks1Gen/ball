"""Blender source -> GLB/FBX and equivalent native Roblox primitives (no mesh upload)."""
import bpy, json, math
from pathlib import Path
from mathutils import Vector
root = Path(__file__).resolve().parents[1]
model_dir = root / 'model'
model_dir.mkdir(parents=True, exist_ok=True)
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)
parts=[]
colors={'navy':(0.08,0.14,0.25),'white':(0.86,0.94,1),'gold':(1,0.73,0.06),'purple':(0.65,0.3,0.95),'cyan':(0.03,0.74,1),'dark':(0.06,0.25,0.4)}
mats={}
for name,color in colors.items():
 m=bpy.data.materials.new(name);m.diffuse_color=(*color,1);m.use_nodes=True;m.node_tree.nodes.get('Principled BSDF').inputs['Base Color'].default_value=(*color,1);mats[name]=m
def part(name,pos,size,color,shape='Block',neon=False,collide=False):
 # Roblox Y up/Z depth -> Blender Z up/Y depth.
 loc=(pos[0],-pos[2],pos[1]);dims=(size[0],size[2],size[1])
 if shape=='Cylinder':
  bpy.ops.mesh.primitive_cylinder_add(vertices=32,radius=size[0]/2,depth=size[1],location=loc)
 else:
  bpy.ops.mesh.primitive_cube_add(size=1,location=loc);bpy.context.object.dimensions=dims
 o=bpy.context.object;o.dimensions=dims;o.name=name;o.data.materials.append(mats[color]);bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
 properties={'Name':name,'Anchored':True,'CanCollide':collide,'CanTouch':False,'CanQuery':collide,'Size':size,'Position':pos,'Color':list(colors[color]),'Material':'Neon' if neon else 'SmoothPlastic','TopSurface':'Smooth','BottomSurface':'Smooth'}
 if shape=='Cylinder':
  properties['Shape']='Cylinder';properties['Size']=[size[1],size[0],size[2]];properties.pop('Position');properties['CFrame']=[*pos,0,-1,0,1,0,0,0,0,1]
 parts.append({'ClassName':'Part','Properties':properties})
part('Foundation',(0,.35,0),(16,.7,12),'navy',collide=True)
part('FoundationTrim',(0,.8,0),(15.6,.2,11.6),'gold')
for x,accent,prefix in [(-3.65,'gold','Fusion'),(3.65,'purple','Mutation')]:
 part(prefix+'Cabinet',(x,4.5,-2),(6.3,7.2,4.5),'white',collide=True)
 part(prefix+'Roof',(x,8.2,-2),(6.8,.6,4.9),accent)
 part(prefix+'RoofStep',(x,8.65,-2),(5.3,.3,3.5),accent)
 part(prefix+'Frame',(x,5.1,.3),(5.4,4.4,.35),accent)
 part(prefix+'Screen',(x,5.1,.52),(4.8,3.8,.16),'dark')
 part(prefix+'Window',(x,5.1,.64),(4.4,3.4,.1),'cyan')
 # Stylized pet silhouette, physically part of the display, not a new UI icon.
 part(prefix+'PetBody',(x,4.9,.8),(1.8,1.55,.18),'white')
 part(prefix+'PetEarLeft',(x-.65,5.95,.8),(.5,.65,.18),'white')
 part(prefix+'PetEarRight',(x+.65,5.95,.8),(.5,.65,.18),'white')
 part(prefix+'Console',(x,2.5,.6),(5.2,.8,1.2),accent)
 part(prefix+'Control',(x-.6,2.95,.7),(2.7,.12,.65),'cyan',neon=True)
 for i in range(3): part(prefix+'Key'+str(i),(x+1+i*.38,2.95,.7),(.25,.15,.45),'white')
 part(prefix+'Antenna',(x,9.3,-2),(.32,1, .32),'cyan')
 part(prefix+'Beacon',(x,10,-2),(.9,.9,.9),accent,neon=True)
 part(prefix+'Platform',(x,1.05,3.4),(5.2,.3,4.2),accent,'Cylinder',collide=True)
 part(prefix+'Pad',(x,1.23,3.4),(4.4,.1,3.6),'cyan','Cylinder',neon=True)
part('CenterSpine',(0,4.25,-2),(.45,6.6,4.7),'navy')
bpy.ops.wm.save_as_mainfile(filepath=str(model_dir/'pet-workshop.blend'))
bpy.ops.export_scene.gltf(filepath=str(model_dir/'pet-workshop.glb'),export_format='GLB')
bpy.ops.export_scene.fbx(filepath=str(model_dir/'pet-workshop.fbx'),use_selection=False,add_leaf_bones=False)
target=root.parents[1]/'RojoTest/src/shared/PetWorkshopTemplate.model.json'
target.write_text(json.dumps({'ClassName':'Model','Children':parts},indent=2),encoding='utf-8')
scene=bpy.context.scene
scene.render.engine='CYCLES';scene.cycles.samples=16
scene.render.resolution_x=850;scene.render.resolution_y=650;scene.render.resolution_percentage=100
scene.world.color=(.4,.4,.4)
bpy.ops.object.light_add(type='AREA',location=(0,-8,16));bpy.context.object.data.energy=2300;bpy.context.object.data.shape='DISK';bpy.context.object.data.size=10
for name,loc in [('front',(17,-23,16)),('back',(-17,19,15))]:
 bpy.ops.object.camera_add(location=loc);camera=bpy.context.object;camera.rotation_euler=(Vector((0,0,4))-camera.location).to_track_quat('-Z','Y').to_euler();camera.data.type='ORTHO';camera.data.ortho_scale=23;scene.camera=camera;scene.render.filepath=str(root/'work'/f'{name}.png');bpy.ops.render.render(write_still=True)
print('WORKSHOP_NATIVE_PARTS',len(parts))
