"""Blender-authored, skinned wildlife; colours and silhouettes derive from approved packs.
Run: blender --background --python build.py [-- --proof]
"""
import bpy
import json
import math
import sys
from pathlib import Path
from mathutils import Vector, Matrix

OUT = Path(__file__).resolve().parent
BASE = OUT.parent
PROOF = '--proof' in sys.argv
S = Matrix(((1,0,0),(0,0,1),(0,-1,0)))

def linear(x):
    x=x/255
    return x/12.92 if x <= .04045 else ((x+.055)/1.055)**2.4

def build(name, groups, kind):
    collection=bpy.data.collections.new(name)
    bpy.context.scene.collection.children.link(collection)
    verts=[]; faces=[]; colours=[]; sources=[]
    for group in groups:
        start=len(verts)
        verts.extend((v[0],-v[2],v[1]) for v in group['v'])
        sources.extend([group['name']]*len(group['v']))
        for ids,tone in group['t']:
            faces.append(tuple(start+i-1 for i in ids)); colours.append(tone)
    if name=='SilverSprat':
        verts=[(x*1.45,y*.62,z*.53) for x,y,z in verts]
        colours=[('A9DDE2' if int(c[:2],16)>100 else '426D90') for c in colours]
    mesh=bpy.data.meshes.new(name); mesh.from_pydata(verts,[],faces); mesh.update()
    obj=bpy.data.objects.new(name,mesh); collection.objects.link(obj)
    # Exact sRGB palette atlas. One material keeps each animal one MeshPart after import.
    palette=list(dict.fromkeys(colours)); side=64
    im=bpy.data.images.new(name+'Palette',width=side,height=side,alpha=False)
    pixels=[0.0]*(side*side*4)
    for y in range(side):
        for x in range(side):
            c=palette[min(len(palette)-1,(y//8)*8+x//8)]
            i=(y*side+x)*4
            pixels[i:i+4]=[int(c[j:j+2],16)/255 for j in (0,2,4)]+[1.0]
    im.pixels=pixels; im.filepath_raw=str(OUT/(name+'-palette.png')); im.file_format='PNG'; im.save(); im.pack()
    mat=bpy.data.materials.new(name+'Colours'); mat.use_nodes=True
    shader=mat.node_tree.nodes.get('Principled BSDF'); shader.inputs['Roughness'].default_value=.52
    tex=mat.node_tree.nodes.new('ShaderNodeTexImage'); tex.image=im; tex.interpolation='Closest'
    mat.node_tree.links.new(tex.outputs['Color'],shader.inputs['Base Color'])
    mesh.materials.append(mat); uv=mesh.uv_layers.new(name='Palette')
    for p,c in zip(mesh.polygons,colours):
        index=palette.index(c); value=((index%8+.5)/8,(index//8+.5)/8)
        for loop in p.loop_indices: uv.data[loop].uv=value
    arm=bpy.data.armatures.new(name+'Skeleton'); rig=bpy.data.objects.new(name+'Rig',arm); collection.objects.link(rig)
    bpy.context.view_layer.objects.active=rig; rig.select_set(True); bpy.ops.object.mode_set(mode='EDIT')
    bones={}; motions={}
    def bone(label,head,tail,parent='Body',axis=(0,0,1),amplitude=0,freq=1,phase=0,slide=None):
        b=arm.edit_bones.new(label); b.head=head; b.tail=tail
        if parent: b.parent=bones[parent]
        bones[label]=b
        motions[label]={'axisWorld':axis,'amplitude':amplitude,'frequency':freq,'phase':phase,'slideWorld':slide or (0,0,0)}
    bone('Root',(0,0,0),(0,0,.5),None)
    bone('Body',(0,0,0),(.5,0,0),'Root',amplitude=.035,freq=1.6)
    if kind=='Fish':
        bone('TailBase',(-.55,0,0),(-1.35,0,0),amplitude=.20 if name=='YellowTang' else .14,freq=2.3)
        bone('TailTip',(-1.35,0,0),(-2.45,0,0),'TailBase',amplitude=.40 if name=='YellowTang' else .29,freq=2.3,phase=-.8)
        for side in (-1,1): bone('Fin'+str(side),(.45,side*.25,0),(-.3,side*.65,-.2),amplitude=.18,freq=3.1,phase=side,axis=(1,0,0))
    elif kind=='Manta':
        for side in (-1,1):
            for j,(a,b) in enumerate(((1.5,5.3),(5.3,9),(9,13.65))):
                bone('Wing'+str(side)+'_'+str(j),(side*a,0,0),(side*b,0,.3),
                     'Body' if j==0 else 'Wing'+str(side)+'_'+str(j-1),axis=(0,1,0),amplitude=side*(.12+j*.055),freq=.27,phase=-j*.55)
        for j in range(3): bone('Tail'+str(j),(0,-3.5-j*2.8,0),(0,-6.3-j*2.8,0),'Body' if j==0 else 'Tail'+str(j-1),amplitude=.065,freq=.37,phase=-j*.7)
    elif kind=='Jelly':
        for i in range(8):
            a=i*math.tau/8; radial=Vector((math.cos(a),math.sin(a),0))
            bone('Rim'+str(i),tuple(radial*3+Vector((0,0,1.5))),tuple(radial*3+Vector((0,0,2.2))),
                 amplitude=0,freq=.48,phase=0,slide=tuple(-radial*.4+Vector((0,0,-.25))))
            for j in range(3):
                h=radial*2.8+Vector((0,0,.9-j*2.65)); t=h+Vector((0,0,-2.65))
                bone('Tentacle'+str(i)+'_'+str(j),h,t,'Rim'+str(i) if j==0 else 'Tentacle'+str(i)+'_'+str(j-1),
                     axis=(math.sin(a),-math.cos(a),0),amplitude=.075+j*.025,freq=.48,phase=-j*.75+i*.32)
    elif kind=='Squid':
        for i in range(8):
            a=i*math.tau/8
            for j in range(3):
                bone('Arm'+str(i)+'_'+str(j),(math.cos(a)*1.8,math.sin(a)*1.8,-j*3.5),
                     (math.cos(a)*1.8,math.sin(a)*1.8,-(j+1)*3.5),'Body' if j==0 else 'Arm'+str(i)+'_'+str(j-1),
                     axis=(math.sin(a),-math.cos(a),0),amplitude=.07+j*.03,freq=.24,phase=i*.6-j*.7)
    else:
        bone('TailBase',(-.5,0,0),(-1.5,0,0),amplitude=.12,freq=1.2)
        bone('Fin',(-.3,0,3),(-.8,0,3),amplitude=.2,freq=3.6,axis=(1,0,0))
    bpy.ops.object.mode_set(mode='OBJECT')
    obj.parent=rig; mod=obj.modifiers.new('Skin','ARMATURE'); mod.object=rig
    vg={n:obj.vertex_groups.new(name=n) for n in bones if n!='Root'}
    def weights(i,values):
        total=sum(values.values())
        for label,w in values.items():
            if w>.00001: vg[label].add([i],w/total,'REPLACE')
    for i,(v,source) in enumerate(zip(verts,sources)):
        x,y,z=v
        if kind=='Fish':
            if source=='Fins' and abs(y)>.33 and x>-.7 and x<.8: weights(i,{'Fin'+str(1 if y>0 else -1):1})
            else:
                t=max(0,min(1,(-x-.55)/.8)); tip=max(0,min(1,(-x-1.35)/.55))
                weights(i,{'Body':1-t,'TailBase':t*(1-tip),'TailTip':t*tip})
        elif kind=='Manta':
            if y<-3.8 and abs(x)<2:
                j=min(2,max(0,int((-y-3.8)/2.8))); weights(i,{'Tail'+str(j):1})
            else:
                side=1 if x>=0 else -1; a=abs(x)
                labels=['Body','Wing'+str(side)+'_0','Wing'+str(side)+'_1','Wing'+str(side)+'_2']; knots=[0,3,7.2,12]
                j=min(2,max(0,next((j for j in range(3) if a<=knots[j+1]),2))); t=max(0,min(1,(a-knots[j])/(knots[j+1]-knots[j])))
                weights(i,{labels[j]:1-t,labels[j+1]:t})
        elif kind=='Jelly':
            a=math.atan2(y,x)%math.tau; n=int(round(a/math.tau*8))%8
            if z<.9 and source!='Features':
                j=min(2,max(0,int((.9-z)/2.65))); weights(i,{'Tentacle'+str(n)+'_'+str(j):1})
            else:
                rim=max(0,min(1,(math.hypot(x,y)-1.0)/2.3)); weights(i,{'Body':1-rim,'Rim'+str(n):rim})
        elif kind=='Squid' and z<0:
            n=int(round((math.atan2(y,x)%math.tau)/math.tau*8))%8; j=min(2,max(0,int(-z/3.5)))
            weights(i,{'Arm'+str(n)+'_'+str(j):1})
        elif kind not in ('Squid','Jelly') and source=='Fins': weights(i,{'Fin':1})
        else: weights(i,{'Body':1})
    motion=[]
    for b in arm.bones:
        m=motions[b.name]; local=b.matrix_local.to_3x3().inverted()
        axis=local@Vector(m.pop('axisWorld')); slide=local@Vector(m.pop('slideWorld'))
        m['frequency']=round(m['frequency']*4)/4
        m.update(name=b.name,axis=list(axis),slide=list(slide)); motion.append(m)
    envelope=0
    for v in mesh.vertices:
        worst=0
        for influence in v.groups:
            if influence.weight < .00001: continue
            b=arm.bones[obj.vertex_groups[influence.group].name]; extra=0
            while b:
                m=next(m for m in motion if m['name']==b.name)
                extra+=2*math.sin(abs(m['amplitude'])/2)*(v.co-b.head_local).length+Vector(m['slide']).length
                b=b.parent
            worst=max(worst,extra)
        envelope=max(envelope,v.co.length+worst)
    # Author the same cycle in Blender, as well as its compact procedural runtime recipe.
    for frame in range(1,122,4):
        t=(frame-1)/30
        for m in motion:
            p=rig.pose.bones[m['name']]; a=math.sin(t*math.tau*m['frequency']+m['phase'])
            p.rotation_mode='AXIS_ANGLE'; p.rotation_axis_angle=(a*m['amplitude'],*m['axis'])
            p.location=Vector(m['slide'])*a
            p.keyframe_insert('rotation_axis_angle',frame=frame); p.keyframe_insert('location',frame=frame)
    bpy.context.scene.frame_set(1)
    bpy.context.view_layer.objects.active=rig
    for o in bpy.context.selected_objects: o.select_set(False)
    obj.select_set(True); rig.select_set(True)
    bpy.ops.export_scene.gltf(filepath=str(OUT/(name+'.glb')),use_selection=True,export_format='GLB',export_yup=True,export_animations=True,export_animation_mode='ACTIVE_ACTIONS')
    bpy.ops.export_scene.fbx(filepath=str(OUT/(name+'.fbx')),use_selection=True,object_types={'MESH','ARMATURE'},add_leaf_bones=False,
                             path_mode='COPY',embed_textures=True,bake_anim=True,bake_anim_use_all_actions=False)
    return {'name':name,'kind':kind,'vertices':len(verts),'triangles':len(faces),'bones':len(bones),'radius':envelope+.3,'motion':motion}

def main():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    scene=bpy.context.scene; scene.name='Ocean Depths Animated Wildlife'; scene.render.fps=30; scene.frame_end=121
    sea=json.loads((BASE/'sea-life-geometry.json').read_text(encoding='utf-8'))
    kit=json.loads((BASE/'LocationKit/location-kit-geometry.json').read_text(encoding='utf-8'))
    manifest=[]
    for name in (['YellowTang'] if PROOF else ['YellowTang','Clownfish','BlueTang','Butterflyfish','SilverSprat','MantaRay','ReefJellyfish','AbyssSquid','Anglerfish','GoldenSeahorse']):
        groups=sea.get(name) or kit.get(name) or sea['YellowTang']
        kind='Fish' if name in ['YellowTang','Clownfish','BlueTang','Butterflyfish','SilverSprat'] else {'MantaRay':'Manta','ReefJellyfish':'Jelly','AbyssSquid':'Squid'}.get(name,'Hover')
        manifest.append(build(name,groups,kind))
    (OUT/'rig-manifest.json').write_text(json.dumps(manifest,indent=2),encoding='utf-8',newline='')
    bpy.context.preferences.filepaths.save_version=0
    bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'animated-wildlife.blend'))
    print('WILDLIFE_READY',[(m['name'],m['bones']) for m in manifest])

if __name__=='__main__': main()
