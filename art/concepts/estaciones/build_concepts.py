"""PUL-091 original Blender concept kit; run from repository root, Blender CLI only.
No production blend is written. Render camera is 38 degrees below horizontal,
matching level_01; native sheet preserves 1080/12.74 px/m. Detail renders are labelled.
"""
import bpy, math, json, sys
from pathlib import Path
from mathutils import Vector
ROOT=Path.cwd(); OUT=ROOT/'art/concepts/estaciones'
MODE=sys.argv[sys.argv.index('--')+1] if '--' in sys.argv else 'A'
bpy.ops.object.select_all(action='SELECT'); bpy.ops.object.delete(use_global=False)
with bpy.data.libraries.load(str(ROOT/'art/blender/_materials_v2.blend'),link=True) as (src,dst):
 dst.materials=[n for n in src.materials if n.startswith('mat_')]
M={m.name:m for m in dst.materials}
# One original atlas for all signs (solid swatches + typography), no new library variants.
colors=['#1D3557','#F4EFE6','#C8402F','#D6361F','#8F1A14','#F7F4EC','#F2C230','#F2D56B','#3F7CC8','#4FA05A']
im=bpy.data.images.new('PUL091_sign_atlas',width=10,height=1)
def lin(v): return v/12.92 if v<=0.04045 else ((v+0.055)/1.055)**2.4
pixels=[]
for h in colors: pixels += [lin(int(h[i:i+2],16)/255) for i in (1,3,5)]+[1]
im.pixels=pixels; im.pack()
for i,n in enumerate(['navy','paper','red','sweet','hot','salt','oil','potato','blue','green']):
 mat=bpy.data.materials.new('atlas_'+n);mat.use_nodes=True
 nodes=mat.node_tree.nodes; bs=nodes.get('Principled BSDF');bs.inputs['Roughness'].default_value=.85
 tex=nodes.new('ShaderNodeTexImage');tex.image=im;tex.interpolation='Closest'
 xyz=nodes.new('ShaderNodeCombineXYZ');xyz.inputs[0].default_value=(i+.5)/10;xyz.inputs[1].default_value=.5
 mat.node_tree.links.new(xyz.outputs[0],tex.inputs[0]);mat.node_tree.links.new(tex.outputs['Color'],bs.inputs['Base Color']); M[n]=mat
C=None

def add(o,n,mat):
 o.name=n
 for c in list(o.users_collection): c.objects.unlink(o)
 C.objects.link(o)
 o.data.materials.append(M[mat]);return o

def cube(n,p,s,mat,bevel=.025):
 bpy.ops.mesh.primitive_cube_add(size=1,location=p);o=add(bpy.context.object,n,mat);o.dimensions=s
 bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
 if bevel:
  mod=o.modifiers.new('soft_edges','BEVEL');mod.width=bevel;mod.segments=2
  o.modifiers.new('weighted_normals','WEIGHTED_NORMAL')
 return o

def cyl(n,p,r,h,mat,vertices=24):
 bpy.ops.mesh.primitive_cylinder_add(vertices=vertices,radius=r,depth=h,location=p);return add(bpy.context.object,n,mat)

def text(n,p,body,size,mat='navy',flat=True):
 d=bpy.data.curves.new(n,'FONT');d.body=body;d.size=size;d.align_x='CENTER';d.align_y='CENTER';d.extrude=0
 o=bpy.data.objects.new(n,d);C.objects.link(o);o.location=p;d.materials.append(M[mat])
 # All concept labels share the camera basis: local X right, local Y screen-up.
 # Lift toward the camera as well: the tilted glyphs previously intersected their
 # vertical backing plates, clipping S/M/digits into apparently mirrored fragments.
 o.rotation_euler=(math.radians(52),0,0)
 o.location += Vector((0,-math.sin(math.radians(52)),math.cos(math.radians(52)))) * (size*.8+.02)
 return o

def icon(p,kind,size=.15,billboard=False,dark=False):
 key='icon_'+kind+('_dark' if dark else '_light')
 if key not in M:
  m=bpy.data.materials.new(key);m.use_nodes=True
  bs=m.node_tree.nodes.get('Principled BSDF');bs.inputs['Base Color'].default_value=(.012,.036,.095,1) if dark else (.90,.87,.81,1)
  bs.inputs['Roughness'].default_value=.85
  t=m.node_tree.nodes.new('ShaderNodeTexImage');t.image=bpy.data.images.load(str(OUT/('icon_'+kind+'.png')),check_existing=True);t.image.pack()
  m.node_tree.links.new(t.outputs['Alpha'],bs.inputs['Alpha']);M[key]=m
 bpy.ops.mesh.primitive_plane_add(size=size,location=p);o=add(bpy.context.object,'canonical_'+kind,key)
 if billboard:o.rotation_euler=(math.radians(52),0,0)
 return o

def mark(p,w=.65,d=.45):
 x,y,z=p
 if MODE=='A':
  cube('landing_contrast',(x,y,z-.01),(w+.06,d+.06,.01),'paper',.02)
  for side in [-1,1]:
   for end in [-1,1]:
    cube('landing_corner',(x+side*w/2,y+end*d/2,z),(.16,.035,.008),'navy',0)
    cube('landing_corner',(x+side*w/2,y+end*(d/2-.06),z),(.035,.15,.008),'navy',0)
 else:
  cube('landing_back',(x,y+d/2,z),(w,.06,.012),'paper',.015)
  for side in [-1,1]:cube('landing_side',(x+side*w/2,y,z),(.06,d,.012),'paper',.015)
 text('placement_arrow',(x,y-d/2-.15,z+.015),'^',.18)

def base(width=4,depth=1.1):
 cube('steel_top',(0,0,1.04),(width,depth,.12),'mat_steel_brushed_top')
 cube('navy_fascia',(0,-depth/2,.84),(width,.045,.25),'navy')
 cube('lower_shelf',(0,0,.24),(width-.14,depth-.1,.06),'mat_steel_brushed_mid')
 for x in [-width/2+.08,width/2-.08]:
  for y in [-depth/2+.1,depth/2-.1]:cube('leg',(x,y,.51),(.08,.08,1),'mat_steel_brushed_mid',.012)

def tray(x,y,z,size='M',fill=0,show_label=True):
 w={'S':.34,'M':.42,'L':.50}[size];d=.34 if size=='S' else .32 if size=='M' else .38
 if size!='L':
  o=cyl('tray_'+size,(x,y,z+.035),w/2,.07,'mat_plastic_red',32);o.scale.y=d/w
  o=cyl('liner',(x,y,z+.072),w/2-.027,.01,'mat_food_tray_liner',32);o.scale.y=d/w
 else:
  cube('tray_L',(x,y,z+.035),(w,d,.07),'mat_plastic_red',.035)
  cube('liner',(x,y,z+.075),(w-.07,d-.07,.012),'mat_food_tray_liner',.025)
  for side in [-1,1]:cube('handle',(x+side*.255,y,z+.045),(.08,.18,.04),'mat_plastic_red',.015)
 # Size letters repeat on a small lug, avoid filling and billboard row.
 if MODE=='A':
  if show_label:text('size_lug',(x,y-d/2+.045,z+.085),size,.095)
 else:
  for i in range({'S':1,'M':2,'L':3}[size]):
   cube('size_notch',(x-.06+i*.06,y-d/2+.04,z+.085),(.025,.055,.008),'navy',0)
 for i in range(int(fill*9)):
  xx=x+(i%3-1)*w*.19;yy=y+(i//3-1)*d*.19
  cyl('octopus_piece',(xx,yy,z+.105),.045,.045,'mat_food_octopus_pieces',12)
  cyl('cut_face',(xx,yy,z+.129),.032,.006,'mat_food_octopus_raw',12)
 if fill==1:
  for dx,dy in [(-.07,.045),(.075,-.035)]:
   o=cyl('cachelo_topping',(x+dx,y+dy,z+.15),.048,.048,'mat_food_potato_cooked',7);o.scale.x=1.2
 return w

def badge(x,y,z,kind,hot=False):
 # Billboard concept discs remain circular; rim for salt as in current contract.
 o=cyl('badge_'+kind,(x,y,z),.141,.006,'navy',32);o.rotation_euler=(math.radians(52),0,0)
 o=cyl('badge_colour',(x,y-.008,z+.006),.129,.008,kind,32);o.rotation_euler=(math.radians(52),0,0)
 # Readable proxy glyphs; canonical SVG mapping is documented for production.
 icon((x,y-.023,z+.016),kind,.17,True,kind in ['salt','oil','potato'])
 if kind=='hot':icon((x+.052,y-.039,z+.065),'fire',.085,True)

def station():
 base()
 for i,kind in enumerate(['sweet','hot','salt','oil']):
  x=[-1.25,-.35,.95,1.75][i];y=-.38
  if kind=='oil':
   cyl('oil_bottle',(x,y,1.2),.095,.20,kind);cube('oil_spout',(x+.09,y,1.315),(.18,.035,.025),'mat_steel_dark',.005)
  elif kind=='salt':
   o=cyl('salt_shaker',(x,y,1.18),.13,.16,kind,16);cyl('salt_cap',(x,y,1.275),.13,.025,'mat_steel_dark',16)
  elif kind=='hot':
   cyl('hot_tin',(x,y,1.2),.10,.20,kind,12);cube('hot_tab',(x,y,1.315),(.06,.13,.025),'paper',.006)
  else:cyl('sweet_tin',(x,y,1.19),.12,.18,kind)
  # Pulse target sits on top toward operator: concept face, no new collider.
  if MODE=='A':
   cyl('press_ring',(x,y+.01,1.32),.10,.014,'paper');icon((x,y,1.333),kind,.14,False,True)
   if kind=='hot':icon((x+.065,y-.06,1.338),'fire',.08,False,True)
  else:
   cube('press_paddle',(x,y-.06,1.31),(.23,.18,.025),'paper',.02);icon((x,y-.065,1.328),kind,.14,False,True)
   if kind=='hot':icon((x+.075,y-.12,1.333),'fire',.08,False,True)
  cube('ingredient_label',(x,-.579,.87),(.37,.025,.19),kind,.02)
  text('front_label',(x,-.605,.89),['DOCE','PIC.','SAL','ACEITE'][i],.065,'navy' if kind in ['salt','oil'] else 'paper',False)
 # Back/pass side tray remains visibly separated.
 mark((.3,.26,1.112),.70,.40)
 cyl('clay_bowl',(-1.77,.08,1.19),.22,.16,'mat_clay');cyl('bowl_inner',(-1.77,.08,1.275),.18,.015,'mat_food_potato_cooked')
 for dx,dy in [(-.07,0),(.06,.05),(.04,-.07)]:
  o=cyl('cachelo',(-1.77+dx,.08+dy,1.30),.067,.055,'mat_food_potato_cooked',8)
 if MODE=='B':
  for dx in [-.23,.23]:cube('bowl_grip',(-1.77+dx,.08,1.25),(.10,.15,.06),'mat_clay',.025)
  cube('bowl_label',(-1.77,-.13,1.29),(.23,.15,.025),'paper',.015)
  icon((-1.77,-.13,1.305),'potato',.13,False,True)
 else:
  cyl('bowl_button',(-1.77,-.19,1.24),.095,.015,'paper')
  icon((-1.77,-.19,1.252),'potato',.13,False,True)
 text('pass_side',(0,.48,1.117),'DEIXAR',.12)
 for x in [-1.3,1.3]:text('operator_arrow',(x,-.74,.025),'^',.32)
 if MODE=='B':
  for x in [-1.99,1.99]:cube('side_return',(x,0,.90),(.035,1.04,.16),'paper',.01)

def trays():
 for r,f in enumerate([0,.5,1]):
  for c,s in enumerate(['S','M','L']):
   x=(c-1)*1.5;y=(1-r)*1.15
   tray(x,y,.08,s,f)
   if r==2:
    for j,k in enumerate(['hot','salt','oil','potato']):badge(x+(j-1.5)*.32,y+.15,.57,k)
   if r==1:
    cube('progress_track',(x,y+.12,.39),(.48,.065,.025),'navy',.01)
    cube('progress_fill',(x-.12,y+.12,.408),(.24,.047,.008),'paper',0)
   if MODE=='B' and r==2:
    cube('conditional_badge_bracket',(x,y+.15,.405),(1.23,.035,.02),'navy',.006)
    text('conditional_full',(x,y-.35,.12),'=',.16)

def rack():
 base(1.8,1.1)
 for i,s in enumerate(['S','M','L']):
  x=(i-1)*.55
  # Buried trays do not project duplicate labels over the visible top tray.
  for j in range(4):tray(x,-.10,1.11+j*.04,s,show_label=j==3)
  if MODE=='A':
   cube('size_panel',(x,-.59,.83),(.42,.03,.26),'paper',.025);text('rack_size',(x,-.62,.85),s,.20,'navy',False)
  else:
   cube('leaned_sample_back',(x,.29,1.35),(.42,.08,.45),'navy',.025)
   text('rack_size',(x,.23,1.41),s,.23,'paper',False)
  cube('stack_guide',(x+.24,-.05,1.22),(.025,.55,.20),'mat_steel_brushed_mid',.01)

def counters():
 base(3,1)
 for i in [-1,0,1]:mark((i,0,1.112),.66,.62)
 tray(0,0,1.13,'M',.5);tray(1,0,1.13,'L',1)
 if MODE=='B':
  for i in [-1,0,1]:cube('slot_front_tag',(i,-.525,.86),(.24,.025,.14),'paper',.015)

def kiosks():
 for i in range(4):
  start=set(C.objects);x=(i-1.5)*1.8
  cube('kiosk_body',(0,0,.64),(1.35,.53,1.28),'mat_steel_dark')
  cube('kiosk_top',(0,0,1.30),(1.44,.58,.07),'mat_steel_brushed_top')
  mark((0,0,1.35),.65,.36)
  for xx in [-.61,.61]:cube('awning_post',(xx,.16,1.6),(.05,.05,.64),'mat_steel_brushed_mid',.01)
  for stripe in range(7):cube('awning_stripe',(-.63+stripe*.21,.06,1.91),(.21,.70,.10),'mat_canvas_paper' if stripe%2 else 'mat_canvas_stand_'+str(i+1),.018)
  # Stable kiosk number and dynamic order ID are physically distinct.
  if MODE=='A':
   cube('order_backplate',(0,-.325,1.99),(.82,.04,.32),'paper',.035)
   text('dynamic_order',(0,-.36,2.02),'#'+str(17+i),.21,'navy',False)
  else:
   cube('order_flag',(.48,.04,2.15),(.68,.08,.38),'paper',.035)
   text('dynamic_order',(.48,-.015,2.18),'#'+str(17+i),.21,'navy',False)
  o=cyl('number_disc',(0,-.293,.87),.21,.025,'paper');o.rotation_euler=(math.pi/2,0,0)
  text('stable_number',(0,-.33,.90),str(i+1),.29,'navy',False)
  cube('tpv',(.47,-.03,1.40),(.24,.20,.12),'mat_steel_dark',.02)
  for o in set(C.objects)-start:o.location.x+=x

families={'station':station,'trays':trays,'rack':rack,'counters':counters,'kiosks':kiosks}
collections={}
for key,fn in families.items():
 C=bpy.data.collections.new(key);bpy.context.scene.collection.children.link(C);collections[key]=C;fn()
C=bpy.data.collections.new('studio');bpy.context.scene.collection.children.link(C)
cube('floor',(0,0,-.08),(200,200,.1),'mat_food_tray_liner',0)
scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.samples=8
scene.cycles.use_denoising=True
scene.render.resolution_x=1920;scene.render.resolution_y=1080;scene.render.resolution_percentage=100
scene.world.color=(.32,.32,.32);scene.view_settings.view_transform='Standard'
bpy.ops.object.light_add(type='AREA',location=(-3,-4,8));light=bpy.context.object;light.data.energy=1300;light.data.shape='DISK';light.data.size=6
bpy.ops.object.camera_add();cam=bpy.context.object;cam.data.type='ORTHO';cam.rotation_euler=(math.radians(52),0,0);scene.camera=cam

def point(center,scale):
 cam.location=Vector(center)+Vector((0,-math.sin(math.radians(52))*14,math.cos(math.radians(52))*14));cam.data.ortho_scale=scale

def render(name):
 scene.render.filepath=str(OUT/name);bpy.ops.render.render(write_still=True)
# Evaluated counts include all repeated pieces, fonts converted only for counting.
counts={}
dg=bpy.context.evaluated_depsgraph_get()
for key,col in collections.items():
 total=0
 for o in col.objects:
  if o.type in ['MESH','FONT']:
   ev=o.evaluated_get(dg);mesh=ev.to_mesh();mesh.calc_loop_triangles();total+=len(mesh.loop_triangles);ev.to_mesh_clear()
 counts[key]=total
(OUT/('budget_'+MODE+'.json')).write_text(json.dumps(counts,indent=2))
for key,col in collections.items():
 for k,c in collections.items():c.hide_render=k!=key
 point((0,0,.9 if key!='trays' else .1),{'station':5.3,'trays':6.0,'rack':3.5,'counters':4.3,'kiosks':8.0}[key])
 render(MODE+'_'+key+'.png')
# Native game-scale overview: translate each complete family, no object scaling.
positions={'station':(-2.8,2.4,0),'rack':(3.1,2.4,0),'trays':(-3.8,-1,0),'counters':(1,-1,0),'kiosks':(0,-5,0)}
for k,c in collections.items():
 c.hide_render=False
 for o in c.objects:o.location+=Vector(positions[k])
point((0,-1,.5),12.74*1920/1080)
render(MODE+'_native_1080.png')
bpy.context.preferences.filepaths.save_version=0
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/('direction_'+MODE+'.blend')))
# Resolve relative linkage only after the new file has a real location.
for lib in bpy.data.libraries:lib.filepath=bpy.path.relpath(str(ROOT/'art/blender/_materials_v2.blend'))
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/('direction_'+MODE+'.blend')))
