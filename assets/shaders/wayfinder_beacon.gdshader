shader_type spatial;
render_mode blend_add, cull_disabled, unshaded, depth_draw_never;

uniform vec4 beacon_color : source_color = vec4(0.20, 0.95, 0.65, 0.92);
uniform float glow_intensity : hint_range(0.5, 5.0) = 2.4;
uniform float alpha_fade : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	vec2 c = UV - vec2(0.5);
	float dist = length(c) * 2.0;
	
	// Expanding ripple rings and rotating reticle
	float ring1 = smoothstep(0.08, 0.0, abs(dist - 0.75 + 0.18 * sin(TIME * 3.0)));
	float ring2 = smoothstep(0.06, 0.0, abs(dist - 0.45 + 0.12 * sin(TIME * 3.0 + 1.5)));
	float center_glow = smoothstep(0.35, 0.0, dist) * (0.6 + 0.4 * sin(TIME * 4.0));
	
	// Crosshair ticks
	float angle = atan(c.y, c.x);
	float ticks = abs(sin(angle * 4.0));
	float tick_mask = smoothstep(0.95, 1.0, ticks) * smoothstep(0.85, 0.55, dist) * smoothstep(0.35, 0.55, dist);
	
	float total = ring1 * 0.8 + ring2 * 0.6 + center_glow + tick_mask * 0.9;
	
	ALBEDO = beacon_color.rgb * glow_intensity;
	ALPHA = beacon_color.a * clamp(total, 0.0, 1.0) * alpha_fade;
}
