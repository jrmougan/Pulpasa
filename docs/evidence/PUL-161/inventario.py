# Estimación de ancho: chars * k * font. k=0.62 (mixto), 0.72 (mayúsculas). Escritorio 1280x720: 1 u = 1 px.
# Móvil 2340x1080 (canvas_items, expand): 1 u = 1,5 px; fuente efectiva = max(fuente, 24 u) (36 px, ui_profile_mobile.tres).
# avail: ancho útil (u) del contenedor; wrap=True -> se parte en líneas, se informa nº de líneas.
import math
R = []
MOBILE_HIDDEN={'MENU_LOCAL_2P','MENU_EXIT','MENU_MODE','HUD_SHIFT','HUD_TIME_LEFT','HUD_REVENUE','HUD_ACTIVE_CHARACTER','HUD_DEVICE_CONNECTED','tr("Salir") (PC)','PAUSE_DEVICE_DISCONNECTED'}
MOBILE_AVAIL={'Tickets':224,'HUD':131}
def r(scr, src, key, es, gl, font, avail, wrap=False, sample=None):
    mob=None if key in MOBILE_HIDDEN else MOBILE_AVAIL.get(scr,avail)
    R.append((scr, src, key, es, gl, font, avail, wrap, sample, mob))
MM="ui/menus/main_menu.gd"; MP="ui/menus/menu_panel.gd"; PM="ui/menus/pause_menu.gd"; GO="ui/menus/game_over.gd"
HUD="ui/hud/hud.gd"; OT="ui/tickets/order_ticket.gd"; RC="data/config/round_config.tres"
LA="features/lenguaje-acciones.md"; TB="features/tutorial-breve.md"
# Menú
r("Menú","ui/menus/main_menu.tscn:46","— (marca D21)","PULPASA","PULPASA",34,440)
r("Menú",MM+":8","MENU_TAGLINE","Pulpo á feira · Romerías gallegas","Polbo á feira · Romarías galegas",20,480)
r("Menú",MM+":5","MENU_PLAY","Individual","Individual",22,440)
r("Menú",MM+":6","MENU_LOCAL_2P","Local 2P","Local 2X",22,440)
r("Menú",MM+":7","MENU_EXIT","Salir","Saír",22,440)
r("Menú",MM+":9","MENU_MODE","Individual: un personaje · Local 2P: dos jugadores","Individual: un personaxe · Local 2X: dous xogadores",16,480)
r("Menú",MM+":10","MENU_LEVEL_UNAVAILABLE","La cocina todavía no está disponible. Vuelve pronto.","A cociña aínda non está dispoñible. Volve pronto.",18,460,True)
r("Menú",MM+":11","MENU_LOAD_FAILED","No se pudo abrir la cocina. Inténtalo de nuevo.","Non se puido abrir a cociña. Téntao de novo.",18,460,True)
r("Menú","ui/menus/menu_panel.tscn:59","— (lema D22)","FRANQUICIA GALEGA DE POLBO","FRANQUICIA GALEGA DE POLBO",15,456,True)
# Pausa
r("Pausa",PM+":16","tr(\"Pausa\")","Pausa","Pausa",34,456,True)
r("Pausa",PM+":17","tr(texto)","La romería puede esperar un momento.","A romaría pode agardar un momento.",20,456,True)
r("Pausa",PM+":16","tr(\"Reanudar\")","Reanudar","Continuar",22,456)
r("Pausa",PM+":24","tr(\"Reiniciar\")","Reiniciar","Reiniciar",22,456)
r("Pausa",MP+":22","tr(\"Salir\") (PC)","Salir","Saír",22,456)
r("Pausa",PM+":95","PAUSE_DEVICE_DISCONNECTED","Mando de J%d desconectado","Mando do X%d desconectado",22,456,True,"Mando de J2 desconectado|Mando do X2 desconectado")
# Resultados
r("Resultados",GO+":17","tr(\"Turno terminado\")","Turno terminado","Quenda rematada",34,456,True)
r("Resultados",GO+":17","tr(\"Reintentar\")","Reintentar","Tentar de novo",22,456)
r("Resultados",GO+":48","tr(\"Recaudación: %d €\")","Recaudación: %d €","Recadación: %d €",20,456,True,"Recaudación: 999 €|Recadación: 999 €")
for i,(es,gl) in enumerate([("Pulpeiro ineficiente","Polbeiro ineficiente"),("Pulpeiro aceptable","Polbeiro aceptable"),("Pulpeiro eficiente","Polbeiro eficiente"),("!Pulpeiro lexendario!","¡Polbeiro lendario!")]):
    r("Resultados",RC+":41 [%d]"%i,"performance_texts[%d] (tr(literal))"%i,es,gl,20,456,True)
# HUD
r("HUD",HUD+":37","HUD_SHIFT","Turno","Quenda",16,152)
r("HUD",HUD+":38","HUD_TIME_LEFT","Tiempo restante","Tempo restante",13,152)
r("HUD",HUD+":39","HUD_REVENUE","Recaudación","Recadación",13,152)
r("HUD",HUD+":81","HUD_ACTIVE_CHARACTER","Controlas: P%d","Controlas: P%d",15,152,False,"Controlas: P1|Controlas: P1")
r("HUD",HUD+":88","HUD_DEVICE_CONNECTED","J%d conectado","X%d conectado",15,152,False,"J2 conectado|X2 conectado")
r("HUD",HUD+":102","HUD_SECONDS_FORMAT","%.1fs","%.1f s",24,152,False,"300.0s|300,0 s")
r("HUD",HUD+":103","HUD_REVENUE_FORMAT","%d €","%d €",24,152,False,"999 €|999 €")
# Tickets
r("Tickets",OT+":30","TICKET_TITLE","Comanda","Comanda",16,180)
r("Tickets",OT+":43","TICKET_ID_FORMAT","#%d","#%d",20,180,False,"#99|#99")
r("Tickets",OT+":76 y :92 (format_clock)","— (formato)","%02d:%02d","%02d:%02d",30,180,False,"01:30|01:30")
r("Tickets","ui/tickets/order_ticket.tscn:105 (Ghost, fondo del reloj)","— (decorado)","88:88","88:88",30,180)
for k,es,gl,f in [("RECIPE_A_FEIRA","Á feira","Á feira","a_feira"),("RECIPE_PICANTE","Picante","Picante","picante"),("RECIPE_CON_CACHELOS","Con cachelos","Con cachelos","con_cachelos"),("RECIPE_BRAVO_CACHELOS","Bravo cachelos","Bravo cachelos","bravo_cachelos")]:
    r("Tickets","data/recipes/%s.tres:8"%f,k,es,gl,19,180)
for k,es,gl,f in [("SEASONING_SWEET_DRESSING","Aliño dulce","Aliño doce","sweet_dressing"),("SEASONING_HOT_DRESSING","Aliño picante","Aliño picante","hot_dressing"),("SEASONING_CACHELOS","Cachelos","Cachelos","cachelos")]:
    r("Tickets","data/seasonings/%s.tres:8 (solo si falta el icono)"%f,k,es,gl,18,180)
# Táctil
r("Táctil",MP+":22","tr(\"Menú\") (perfil MOBILE)","Menú","Menú",22,456)
r("Táctil",MM+":5 (único botón en MOBILE)","MENU_PLAY","Individual","Individual",22,440)
# Prompts (rótulos D26; hoy solo iconos en action_icons.tres)
for k,es,gl in [("PICK_UP","COGER","COLLER"),("DROP","SOLTAR","DEIXAR"),("COOK","COCER","COCER"),("CUT","CORTAR","CORTAR"),("SEASON_SWEET","ALIÑAR DULCE","ALIÑAR DOCE"),("SEASON_HOT","ALIÑAR PICANTE","ALIÑAR PICANTE"),("CACHELOS","CACHELOS","CACHELOS"),("TRASH","TIRAR","BOTAR")]:
    r("Prompts",LA+" §Verbos (sin implementar)","VERB_"+k,es,gl,24,456)
for k,es,gl in [("BOX_NOT_FULL","caja a medias","caixa a medias"),("BUSY","ocupado","ocupado"),("EMPTY","vacío","baleiro"),("FULL","lleno","cheo"),("ALREADY","ya aplicado","xa aplicado"),("ALREADY_HAS","ya lleva","xa leva"),("RAW","sin cocer","sen cocer")]:
    r("Prompts",LA+" §Motivos (sin implementar)","REASON_"+k,es,gl,24,456)
r("Prompts","entities/items/box.gd:191 (Label3D)","— (formato)","%d/%d","%d/%d",24,456,False,"6/6|6/6")
r("Prompts","entities/stations/order_stand.gd:173 (Label3D)","— (formato)","#%d","#%d",24,456,False,"#9|#9")
# Tutorial (propuesta de texto; diseño en PUL-162)
for k,es,gl in [("TUTORIAL_STEP_PICK_UP","Coge un pulpo de la nevera.","Colle un polbo da neveira."),
 ("TUTORIAL_STEP_COOK","Mételo en la olla para cocerlo.","Méteo na pota para cocelo."),
 ("TUTORIAL_STEP_CUT","Córtalo sobre una caja: 6 pulsaciones (o mantén pulsado).","Córtao sobre unha caixa: 6 pulsacións (ou mantén premido)."),
 ("TUTORIAL_STEP_SEASON","Aliña la caja llena con el aliño dulce.","Aliña a caixa chea co aliño doce."),
 ("TUTORIAL_SEASON_REPLACE","¿Picante? Pulsa el dulce y lo sustituye.","Picante? Preme o doce e substitúeo."),
 ("TUTORIAL_TRASH_HINT","Lo que salga mal, al cubo.","O que saia mal, ao lixo."),
 ("TUTORIAL_STEP_DELIVER","Entra con la caja correcta en la zona del puesto.","Entra coa caixa correcta na zona do posto."),
 ("TUTORIAL_STEP_COOPERATE","Cooperad: uno cuece y el otro corta.","Cooperade: un coce e o outro corta."),
 ("TUTORIAL_STEP_SWITCH","Cambia de personaje con el botón.","Cambia de personaxe co botón."),
 ("TUTORIAL_SKIP","Saltar","Omitir")]:
    r("Tutorial",TB+" (sin implementar; PUL-162)",k,es,gl,24,456,True)

def caps(s): return s.upper()==s and any(c.isalpha() for c in s)
def width(s,font): return len(s)*(0.70 if caps(s) else 0.60)*font
def verdict(s,font,avail,wrap):
    w=width(s,font)
    if w<=avail: return "%d/%d u · cabe"%(round(w),avail)
    if wrap: return "%d/%d u · %d líneas"%(round(w),avail,math.ceil(w/avail))
    return "%d/%d u · **riesgo**"%(round(w),avail)
PROP={"Pausa":"PAUSE_TITLE","La romería puede esperar un momento.":"PAUSE_DESCRIPTION","Reanudar":"PAUSE_RESUME","Reiniciar":"PAUSE_RESTART","Salir":"MENU_EXIT","Turno terminado":"RESULTS_TITLE","Reintentar":"RESULTS_RETRY","Recaudación: %d €":"RESULTS_REVENUE","Menú":"MENU_BACK"}
NOTR={"PULPASA","FRANQUICIA GALEGA DE POLBO","#%d","%d/%d","%d €","%02d:%02d","88:88"}
print("| # | Pantalla | Origen | Clave hoy | Clave propuesta | Castellano | Lon. es | Gallego (propuesta) | Lon. gl | 1280×720 (gl) | 2340×1080 (gl) |")
print("|---|---|---|---|---|---|---|---|---|---|---|")
from collections import Counter; C=Counter(); KEYS=[]
for i,(scr,src,key,es,gl,font,avail,wrap,sample,mobav) in enumerate(R,1):
    se,sg=(sample.split("|") if sample else (es,gl))
    m=max(font,24)
    worst=sg if width(sg,font)>=width(se,font) else se
    d=verdict(worst,font,avail,wrap); mob='oculta en MOBILE' if mobav is None else verdict(worst,m,mobav,wrap)
    C[scr]+=1
    if es in NOTR: pk="— (no se traduce)"
    elif key.startswith("performance_texts"): pk="PERFORMANCE_%s"%key[18]
    elif es in PROP and key.startswith("tr("): pk=PROP[es]
    elif key.startswith("—"): pk="— (no se traduce)"
    else: pk=key.split(" ")[0]
    print("| %d | %s | `%s` | `%s` | `%s` | %s | %d | %s | %d | %s | %s |"%(i,scr,src,key,pk,es,len(se),gl,len(sg),d,mob))
    if not pk.startswith("—"): KEYS.append(pk)
print(); print(dict(C), sum(C.values()), "traducibles:", len(KEYS), "claves únicas:", len(set(KEYS)), "repetidas:", sorted(k for k in set(KEYS) if KEYS.count(k)>1))
