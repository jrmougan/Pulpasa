import bpy,json,math
from pathlib import Path
R=Path.cwd();out={}
for d in ['A','B']:
 p=R/'art/concepts/estaciones'/('direction_'+d+'.blend')
 bpy.ops.wm.open_mainfile(filepath=str(p))
 s=bpy.context.scene
 missing=[]
 for im in bpy.data.images:
  if im.source=='FILE' and not im.packed_file:
   path=Path(bpy.path.abspath(im.filepath,library=im.library))
   if not path.exists():missing.append(str(path))
 assert not missing,missing
 assert s.camera.data.type=='ORTHO'
 assert abs(s.camera.data.ortho_scale-12.74*1920/1080)<.0001
 assert abs(s.camera.rotation_euler.x-math.radians(52))<.0001
 labels=[o for o in s.objects if o.type=='FONT']
 camera_basis=s.camera.matrix_world.to_3x3().normalized()
 for label in labels:
  basis=label.matrix_world.to_3x3().normalized()
  assert all(v>0 for v in label.scale),label.name
  assert basis.determinant()>0,label.name
  assert all(basis.col[i].dot(camera_basis.col[i])>.9999 for i in range(3)),label.name
 assert all(name in bpy.data.collections for name in ['station','trays','rack','counters','kiosks'])
 assert all(Path(bpy.path.abspath(l.filepath)).exists() for l in bpy.data.libraries)
 out[d]={'camera_facing_texts':len(labels),'positive_text_scale':True,'missing_images':missing,'camera_width':s.camera.data.ortho_scale,'camera_rotation_degrees':52,'resolution':[s.render.resolution_x,s.render.resolution_y],'libraries':[l.filepath for l in bpy.data.libraries]}
 # Reopened render ensures native sheet uses valid saved links, not session-only image cache.
 if d=='A':
  s.cycles.samples=4;s.render.filepath=str(R/'docs/evidence/PUL-091/reopen_A.png');bpy.ops.render.render(write_still=True)
(R/'docs/evidence/PUL-091/concept_validation.json').write_text(json.dumps(out,indent=2))
print('PUL091 CONCEPT VALIDATION OK')
