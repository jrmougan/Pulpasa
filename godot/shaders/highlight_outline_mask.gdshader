shader_type spatial;
// Mascara del contorno a traves del personaje (D26.6): marca en el stencil la silueta del propio
// objeto, con o sin algo delante, sin pintar nada. La pasada `highlight_outline_xray` solo dibuja
// donde no hay marca, asi que el aro se ve tras el personaje y el objeto no se tine.
render_mode unshaded, cull_back, depth_test_disabled, blend_add, shadows_disabled;
stencil_mode write, compare_always, 1;

void fragment() {
	ALBEDO = vec3(0.0);
}
