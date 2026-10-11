shader_type spatial;
// Aro del personaje INACTIVO (D26.6): anillo fino gris y discontinuo (<= 3 px a 1080 de alto).
// La discontinuidad es angular sobre el toro (eje Y): `dashes` tramos, `duty` de ellos visibles.
render_mode unshaded, cull_disabled, shadows_disabled;

uniform vec4 ring_color : source_color = vec4(0.82, 0.82, 0.82, 1.0);
uniform float dashes = 16.0;
uniform float duty : hint_range(0.1, 0.9) = 0.5;

varying vec3 local_position;

void vertex() {
	local_position = VERTEX;
}

void fragment() {
	float turn = atan(local_position.z, local_position.x) / TAU + 0.5;
	if (fract(turn * dashes) > duty) {
		discard;
	}
	ALBEDO = ring_color.rgb;
}
