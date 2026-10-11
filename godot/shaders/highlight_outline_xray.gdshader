shader_type spatial;
// Pasada del contorno SIN test de profundidad al 40 % (D26.6): el aro del objetivo se ve a traves
// del personaje. Solo dibuja fuera de la silueta marcada por `highlight_outline_mask`.
render_mode unshaded, cull_front, depth_test_disabled, blend_mix, shadows_disabled;
stencil_mode read, compare_not_equal, 1;

uniform vec4 outline_color : source_color = vec4(1.0, 0.956863, 0.839216, 1.0);
uniform float opacity : hint_range(0.0, 1.0) = 0.4;
uniform float grow = 0.05;
uniform float width = 0.04;

void vertex() {
	vec3 radial = length(VERTEX) > 0.0001 ? normalize(VERTEX) : NORMAL;
	VERTEX = VERTEX * (1.0 + grow) + radial * width;
}

void fragment() {
	ALBEDO = outline_color.rgb;
	ALPHA = opacity;
}
