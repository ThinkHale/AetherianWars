# Blender: clean a Hunyuan3D body, project the reference views as colour, bake to a low-poly UV texture, export FBX for Mixamo.
import bpy, bmesh, sys, numpy as np, mathutils
argv=sys.argv[sys.argv.index('--')+1:]; src,views,out=argv[0],argv[1],argv[2]
HEIGHT=1.8; TARGET_TRIS=40000; TEX=2048
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=src)
meshes=[o for o in bpy.context.scene.objects if o.type=='MESH']
bpy.ops.object.select_all(action='DESELECT')
for o in meshes: o.select_set(True)
bpy.context.view_layer.objects.active=meshes[0]
if len(meshes)>1: bpy.ops.object.join()
hi=bpy.context.view_layer.objects.active; hi.name='Gaius_hi'
bpy.ops.object.parent_clear(type='CLEAR_KEEP_TRANSFORM')
bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
for o in list(bpy.context.scene.objects):
    if o.type!='MESH': bpy.data.objects.remove(o)
# Drop floaters: keep only islands with >1% of the faces.
bm=bmesh.new(); bm.from_mesh(hi.data)
bmesh.ops.remove_doubles(bm,verts=bm.verts,dist=1e-5)
seen=set(); islands=[]
for f in bm.faces:
    if f.index in seen: continue
    stack=[f]; isl=[]; seen.add(f.index)
    while stack:
        g=stack.pop(); isl.append(g)
        for e in g.edges:
            for h in e.link_faces:
                if h.index not in seen: seen.add(h.index); stack.append(h)
    islands.append(isl)
n=len(bm.faces); drop=[f for isl in islands if len(isl)<0.01*n for f in isl]
bmesh.ops.delete(bm,geom=drop,context='FACES'); bmesh.ops.recalc_face_normals(bm,faces=bm.faces)
bm.to_mesh(hi.data); bm.free(); print('islands',len(islands),'dropped faces',len(drop))
# Normalise: feet on z=0, centred, 1.8 m tall.
co=np.array([v.co[:] for v in hi.data.vertices]); mn,mx=co.min(0),co.max(0)
s=HEIGHT/(mx[2]-mn[2]); off=np.array([(mn[0]+mx[0])/2,(mn[1]+mx[1])/2,mn[2]])
co=(co-off)*s
hi.data.vertices.foreach_set('co',co.ravel()); hi.data.update()
mn,mx=co.min(0),co.max(0)
# Project the views as vertex colours (blend weights from normals).
def load(name):
    bi=bpy.data.images.load(f'{views}/{name}.png'); W,H=bi.size
    px=np.empty(W*H*4,np.float32); bi.pixels.foreach_get(px)
    im=px.reshape(H,W,4)[::-1,:,:3]   # Blender stores bottom row first
    bg=np.median(np.concatenate([im[:8].reshape(-1,3),im[:,:8].reshape(-1,3),im[:,-8:].reshape(-1,3)]),0)
    fg=np.abs(im-bg).sum(2)>0.12
    rows=np.where(fg.sum(1)>2)[0]; cols=np.where(fg.sum(0)>2)[0]
    # Shrink the mask a few px so silhouette fringe counts as background.
    k=4; e=fg.copy()
    for dy in range(-k,k+1,2):
        for dx in range(-k,k+1,2): e&=np.roll(np.roll(fg,dy,0),dx,1)
    lin=np.where(im<=0.04045,im/12.92,((im+0.055)/1.055)**2.4)   # bake target is sRGB, emission is linear
    return np.dstack([lin,e]),(cols[0],cols[-1],rows[0],rows[-1])
def sample(view,u,v):  # u,v in 0..1 across the figure's bbox, v=0 at feet
    im,(c0,c1,r0,r1)=view; H,W,_=im.shape
    x=np.clip((c0+u*(c1-c0)).astype(int),0,W-1); y=np.clip((r1-v*(r1-r0)).astype(int),0,H-1)
    return im[y,x]
F,B,L=load('front'),load('back'),load('side')
hi.data.calc_normals_split() if hasattr(hi.data,'calc_normals_split') else None
nrm=np.array([v.normal[:] for v in hi.data.vertices])
x,y,z=co[:,0],co[:,1],co[:,2]; vz=(z-mn[2])/(mx[2]-mn[2])
ux=(x-mn[0])/(mx[0]-mn[0]); uy=(y-mn[1])/(mx[1]-mn[1])
cf=sample(F,ux,vz); cb=sample(B,1-ux,vz); cs=sample(L,uy,vz)   # side camera at +X: screen-right = +Y; mirrored for -X
w=np.stack([np.clip(-nrm[:,1],0,1),np.clip(nrm[:,1],0,1),np.abs(nrm[:,0])],1)**3
w=w*np.stack([cf[:,3],cb[:,3],cs[:,3]],1)+1e-4*np.stack([np.ones(len(w))*(-nrm[:,1]>0),np.ones(len(w))*(nrm[:,1]>=0),np.ones(len(w))],1)
cf,cb,cs=cf[:,:3],cb[:,:3],cs[:,:3]
col=(cf*w[:,0:1]+cb*w[:,1:2]+cs*w[:,2:3])/w.sum(1,keepdims=True)
ca=hi.data.color_attributes.new('proj','FLOAT_COLOR','POINT')
ca.data.foreach_set('color',np.concatenate([col,np.ones((len(col),1))],1).ravel())
# Low poly copy.
lo=hi.copy(); lo.data=hi.data.copy(); lo.name='Gaius'; bpy.context.scene.collection.objects.link(lo)
for a in list(lo.data.color_attributes): lo.data.color_attributes.remove(a)
bpy.context.view_layer.objects.active=lo
m=lo.modifiers.new('dec','DECIMATE'); m.ratio=TARGET_TRIS/len(hi.data.polygons); bpy.ops.object.modifier_apply(modifier='dec')
bpy.ops.object.select_all(action='DESELECT'); lo.select_set(True)
bpy.ops.object.mode_set(mode='EDIT'); bpy.ops.mesh.select_all(action='SELECT')
bpy.ops.uv.smart_project(angle_limit=1.15,island_margin=0.004); bpy.ops.object.mode_set(mode='OBJECT')
bpy.ops.object.shade_smooth()
print('lo tris',sum(len(p.vertices)-2 for p in lo.data.polygons))
# Materials: hi emits vertex colour; lo gets the baked image.
mh=bpy.data.materials.new('proj'); mh.use_nodes=True; nt=mh.node_tree; nt.nodes.clear()
a=nt.nodes.new('ShaderNodeVertexColor'); a.layer_name='proj'; e=nt.nodes.new('ShaderNodeEmission'); o=nt.nodes.new('ShaderNodeOutputMaterial')
nt.links.new(a.outputs[0],e.inputs[0]); nt.links.new(e.outputs[0],o.inputs[0]); hi.data.materials.clear(); hi.data.materials.append(mh)
img=bpy.data.images.new('Gaius_albedo',TEX,TEX); img.filepath_raw=f'{out}/Gaius_albedo.png'; img.file_format='PNG'
ml=bpy.data.materials.new('Gaius'); ml.use_nodes=True; nt=ml.node_tree
t=nt.nodes.new('ShaderNodeTexImage'); t.image=img; nt.nodes.active=t
p=nt.nodes['Principled BSDF']; nt.links.new(t.outputs[0],p.inputs['Base Color']); p.inputs['Roughness'].default_value=0.7
lo.data.materials.clear(); lo.data.materials.append(ml)
sc=bpy.context.scene; sc.render.engine='CYCLES'; sc.cycles.samples=1; sc.cycles.device='CPU'
bpy.ops.object.select_all(action='DESELECT'); hi.select_set(True); lo.select_set(True); bpy.context.view_layer.objects.active=lo
bpy.ops.object.bake(type='EMIT',use_selected_to_active=True,cage_extrusion=0.02,max_ray_distance=0.05,margin=8)
img.save()
bpy.data.objects.remove(hi)
bpy.ops.wm.save_as_mainfile(filepath=f'{out}/Gaius_clean.blend')
bpy.ops.object.select_all(action='DESELECT'); lo.select_set(True)
bpy.ops.export_scene.fbx(filepath=f'{out}/Gaius_for_mixamo.fbx',use_selection=True,path_mode='COPY',embed_textures=True,apply_unit_scale=True,mesh_smooth_type='FACE')
print('DONE')
