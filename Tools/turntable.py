import bpy, sys, math, mathutils
argv=sys.argv[sys.argv.index('--')+1:]; src,out=argv[0],argv[1]
if src.endswith('.blend'): bpy.ops.wm.open_mainfile(filepath=src)
else:
    bpy.ops.wm.read_factory_settings(use_empty=True); bpy.ops.import_scene.gltf(filepath=src)
objs=[o for o in bpy.context.scene.objects if o.type=='MESH']
pts=[o.matrix_world@mathutils.Vector(c) for o in objs for c in o.bound_box]
mn=mathutils.Vector([min(p[i] for p in pts) for i in range(3)]); mx=mathutils.Vector([max(p[i] for p in pts) for i in range(3)])
ctr=(mn+mx)/2; size=max(mx-mn)
sc=bpy.context.scene; sc.render.engine='BLENDER_WORKBENCH'; sc.display.shading.light='STUDIO'; sc.display.shading.color_type='TEXTURE' if '--tex' in argv else 'MATERIAL'
sc.render.resolution_x=sc.render.resolution_y=512; sc.render.film_transparent=False
w=bpy.data.worlds.new('w'); sc.world=w
cam=bpy.data.objects.new('cam',bpy.data.cameras.new('cam')); sc.collection.objects.link(cam); sc.camera=cam
cam.data.type='ORTHO'; cam.data.ortho_scale=size*1.1
for i,az in enumerate([0,90,180,270]):
    a=math.radians(az); d=size*3
    cam.location=ctr+mathutils.Vector((math.sin(a)*-d, math.cos(a)*-d, 0))
    cam.rotation_euler=(ctr-cam.location).to_track_quat('-Z','Y').to_euler()
    sc.render.filepath=f'{out}_{i}.png'; bpy.ops.render.render(write_still=True)
print('DIMS',tuple(round(x,3) for x in mx-mn))
