"""Lay out original captures and Blender renders, with explicit scale labels."""
from pathlib import Path
from PIL import Image,ImageDraw,ImageFont,ImageOps
R=Path(__file__).resolve().parents[3];E=R/'docs/evidence/PUL-091';C=R/'art/concepts/estaciones'
font=str(R/'godot/assets/fonts/LiberationSans.ttf')
f=ImageFont.truetype(font,22);big=ImageFont.truetype(font,32);small=ImageFont.truetype(font,18)
base=Image.open(E/'00_nivel_sin_hud.png');states=Image.open(E/'06_estados_controlados.png')
rows=[('station','Condimentos / pase / lados',(735,610,1098,758),base),('trays','S-M-L / vacío-medio-lleno / badges',(650,705,985,892),states),('rack','Rack de bandejas',(310,728,477,898),base),('counters','Encimeras / slots',(1090,621,1490,760),base),('kiosks','Kioscos / número / comanda',(550,893,1280,1044),base)]
board=Image.new('RGB',(2160,2320),'#F4EFE6');d=ImageDraw.Draw(board)
d.text((24,16),'PUL-091 · Lectura de estaciones · propuestas para gate humano',font=big,fill='#1D3557')
for i,t in enumerate(['ACTUAL · Godot (recortes ampliados)','A · Señalética de pase','B · Guías y mandos físicos']):d.text((i*720+20,73),t,font=f,fill='#1D3557')
for r,(key,title,rect,src) in enumerate(rows):
 y=120+r*430;d.text((20,y),title,font=f,fill='#1D3557')
 images=[src.crop(rect),Image.open(C/('A_'+key+'.png')),Image.open(C/('B_'+key+'.png'))]
 for col,im in enumerate(images):
  panel=ImageOps.contain(im,(700,360));board.paste(panel,(col*720+(720-panel.width)//2,y+36+(360-panel.height)//2))
 d.line((15,y+415,2145,y+415),fill='#B9BEC2',width=2)
d.text((20,2280),'Mismo ángulo ortográfico (38° bajo horizontal). Detalles ampliados; escala real en *_native_1080.png. Luz de estudio ≠ Godot.',font=small,fill='#1D3557')
board.save(E/'comparativa_actual_A_B.png')
# Unaltered full capture plus separate numbered pointers: no readability claim from enlargement.
ann=base.copy();d=ImageDraw.Draw(ann)
for n,x,y in [(1,813,679),(2,887,679),(3,998,679),(4,1074,679),(5,765,649),(6,944,644),(7,927,735),(8,431,830),(9,1229,663),(10,792,925)]:
 d.ellipse((x-15,y-15,x+15,y+15),fill='#F4EFE6',outline='#1D3557',width=2);d.text((x-7,y-11),str(n),font=small,fill='#1D3557')
ann.save(E/'auditoria_localizadores.png')
# Preserve native screenshot crops, do not upscale this separate evidence.
for key,title,rect,src in rows:src.crop(rect).save(E/('actual_'+key+'_1x.png'))
