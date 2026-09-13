shader_type spatial;
render_mode blend_add, depth_draw_never, cull_back, unshaded;

uniform vec4 hologram_color : source_color = vec4(0.2, 1.0, 0.4, 0.85);
uniform float fresnel_power : hint_range(0.5, 6.0) = 2.4;
uniform float scanline_frequency : hint_range(10.0, 150.0) = 60.0;
uniform float scanline_speed : hint_range(0.0, 10.0) = 2.0;
uniform float pulse_speed : hint_range(0.0, 10.0) = 3.5;
uniform float inner_alpha : hint_range(0.0, 1.0) = 0.22;

void fragment() {
	// Fresnel edge glow (bright outline silhouette)
	float normal_view_dot = clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	float fresnel = pow(1.0 - normal_view_dot, fresnel_power);

	// Animated holographic scanline pattern
	float scanline = sin((VERTEX.y * scanline_frequency) - (TIME * scanline_speed)) * 0.15 + 0.85;

	// Organic idle breathing pulse
	float pulse = 0.88 + 0.12 * sin(TIME * pulse_speed);

	// Translucent core with bright glowing contour
	float edge_intensity = fresnel * 0.78 + inner_alpha;
	float alpha = clamp(edge_intensity * scanline * pulse * hologram_color.a, 0.0, 1.0);

	ALBEDO = hologram_color.rgb * (1.0 + fresnel * 0.7);
	ALPHA = alpha;
}
