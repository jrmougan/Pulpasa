"""Deterministic Montserrat signage and UI silhouettes; no third-party imagery."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
ROOT = Path(__file__).resolve().parents[3]
OUT = ROOT / 'docs/evidence/PUL-095'
NAVY, PAPER, RED = '#1D3557', '#F4EFE6', '#C8402F'
FONT = '/usr/share/fonts/julietaula-montserrat-fonts/Montserrat-Bold.otf'
atlas = Image.open(ROOT/'godot/assets/models/items/box/box_box_atlas_albedo.png').convert('RGB')
d = ImageDraw.Draw(atlas)
for i, letter in enumerate('SML'):
 x = i*128
 d.rectangle((x,384,x+127,511),fill=NAVY)
 d.rounded_rectangle((x+6,390,x+121,505),radius=12,fill=PAPER)
 d.text((x+64,449),letter,font=ImageFont.truetype(FONT,108),anchor='mm',fill=NAVY)
atlas.save(OUT/'tray_atlas.png')
orm=Image.open(ROOT/'godot/assets/models/items/box/box_box_atlas_orm.png').convert('RGB')
ImageDraw.Draw(orm).rectangle((0,384,511,511),fill=(255,220,0))
orm.save(OUT/'tray_orm.png')
c=Image.new('RGB',(512,512),NAVY)
c.paste(Image.open(ROOT/'godot/assets/models/furniture/counters/counter_1m_counters_atlas.png').crop((0,0,256,256)),(0,0))
ImageDraw.Draw(c).rectangle((0,300,255,511),fill=PAPER)
c.save(OUT/'counter_atlas.png')
ui=ROOT/'godot/assets/textures/ui/box_sizes'; ui.mkdir(parents=True,exist_ok=True)
for size,letter in zip(('small','medium','large'),'SML'):
 im=Image.new('RGBA',(768,768)); d=ImageDraw.Draw(im)
 bounds={'small':(100,100,668,668),'medium':(30,172,738,596),'large':(30,105,738,663)}[size]
 if size=='large': d.rounded_rectangle(bounds,radius=60,fill=RED,outline=NAVY,width=27)
 else: d.ellipse(bounds,fill=RED,outline=NAVY,width=27)
 b=tuple(v+(52 if i<2 else -52) for i,v in enumerate(bounds))
 if size=='large': d.rounded_rectangle(b,radius=38,fill=PAPER)
 else: d.ellipse(b,fill=PAPER)
 d.text((384,390),letter,font=ImageFont.truetype(FONT,330),anchor='mm',fill=NAVY)
 im.resize((256,256),Image.Resampling.LANCZOS).save(ui/(size+'.png'))
