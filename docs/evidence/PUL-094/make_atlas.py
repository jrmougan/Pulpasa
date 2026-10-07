"""Build opaque original signage atlas using the repository's existing icon masks."""
from pathlib import Path
from PIL import Image, ImageDraw
root=Path.cwd(); out=root/'docs/evidence/PUL-094'
image=Image.new('RGB',(512,512),'#F4EFE6');draw=ImageDraw.Draw(image)
for i,color in enumerate(['#1D3557','#F4EFE6','#D6361F','#8F1A14','#F7F4EC','#F2C230','#F2D56B']):
    draw.rectangle((i*64,0,i*64+63,63),fill=color)
for kind,col,row in [('sweet',0,1),('hot',1,1),('salt',2,1),('oil',3,1),('potato',0,2)]:
    tile=Image.new('RGB',(128,128),'#F4EFE6')
    icon=Image.open(root/f'art/concepts/estaciones/icon_{kind}.png').convert('RGBA')
    icon.thumbnail((108,108))
    tile.paste(Image.new('RGB',icon.size,'#1D3557'),((128-icon.width)//2,(128-icon.height)//2),icon.getchannel('A'))
    if kind=='hot':
        flame=Image.open(root/'art/concepts/estaciones/icon_fire.png').convert('RGBA');flame.thumbnail((52,58))
        tile.paste(Image.new('RGB',flame.size,'#1D3557'),(76,0),flame.getchannel('A'))
    image.paste(tile,(col*128,row*128))
image.save(out/'sign_atlas.png')
