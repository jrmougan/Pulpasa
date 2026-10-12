# PUL-137: rects de contador de PUL-136 (variante actual) frente a la zona de botones de D27
# (anclada a la safe area) y a los discos en fila. Uso: python3 zone_d27.py docs/evidence/PUL-136
import json,sys,math
base=sys.argv[1]
def circ(r,c,rad):
    x,y,w,h=r; cx=min(max(c[0],x),x+w); cy=min(max(c[1],y),y+h)
    return math.hypot(c[0]-cx,c[1]-cy)<rad
for res,(W,H) in {'2340x1080':(2340,1080),'1920x1080':(1920,1080),'800x370':(800,370)}.items():
    d=json.load(open(f'{base}/{res}-medidas.json')); k=H/1080
    for sr,sb in [(0,0),(132,63)]:
        zx=W-(sr+390)*k; zy=H-(sb+240)*k
        act=(W-(sr+138)*k,H-(sb+138)*k); sw=(W-(sr+312)*k,H-(sb+108)*k)
        for st,v in d['stands'].items():
            hits=[];disc=[];over=0
            for slot,m in v['actual'].items():
                x,y,w,h=m['rect_px']
                if x+w>zx and y+h>zy: hits.append(slot[-2:]); over=max(over,y+h-zy)
                if circ(m['rect_px'],act,102*k) or circ(m['rect_px'],sw,72*k): disc.append(slot[-2:])
            print(res,f'safe {sr}/{sb}',st[:4],st.split(',')[1][:5],'zone',round(zx,1),round(zy,1),'hits',hits,'over',round(over,1),'discs',disc)
