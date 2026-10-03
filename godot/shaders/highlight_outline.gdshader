shader_type spatial;
// Contorno por inverted hull (sustituye a OutlineHighlighter: malla x1.05 transparente).
// Se aplica como material_overlay: dibuja solo las caras traseras de la malla inflada.
render_mode unshaded, cull_front, shadows_disabled;

uniform vec4 outline_color : source_color = vec4(1.0, 0.85, 0.2, 1.0);
// Crecimiento uniforme desde el origen de la malla (Unity: escala 1.05).
uniform float grow = 0.05;
// Empuje adicional en metros, radial desde el origen de la malla: a diferencia de la normal,
// no abre grietas en las aristas de mallas con normales partidas (cajas).
uniform float width = 0.04;

void vertex() {
	vec3 radial = length(VERTEX) > 0.0001 ? normalize(VERTEX) : NORMAL;
	VERTEX = VERTEX * (1.0 + grow) + radial * width;
}

void fragment() {
	ALBEDO = outline_color.rgb;
}
