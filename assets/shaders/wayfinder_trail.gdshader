shader_type spatial;
render_mode blend_add, cull_disabled, unshaded, depth_draw_never;

uniform vec4 line_color : source_color = vec4(0.20, 0.95, 0.65, 0.92);
uniform float pulse_speed : hint_range(0.0, 10.0) = 3.2;
uniform float dash_frequency : hint_range(0.5, 30.0) = 7.0;
uniform float glow_intensity : hint_range(0.5, 5.0) = 2.4;
uniform float alpha_fade : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	// UV.x: 0.0 (left edge) to 1.0 (right edge)
	// UV.y: 0.0 (player feet) to 1.0 (target showcase)
	
	// Soft parabolic width falloff towards outer edges
	float width_factor = sin(clamp(UV.x, 0.0, 1.0) * 3.14159265);
	width_factor = pow(width_factor, 1.5);
	
	// Forward-flowing luminous wave / energy pulse moving towards target
	float flow = fract(UV.y * dash_frequency - TIME * pulse_speed);
	float pulse = smoothstep(0.0, 0.5, flow) * smoothstep(1.0, 0.5, flow);
	
	// Luminous spine + animated pulse wave
	float spine = pow(width_factor, 3.0) * 0.7;
	float energy = (0.35 + 0.65 * pulse + spine) * width_factor;
	
	// Soft fade-in at player feet and soft taper at target
	float length_fade = smoothstep(0.0, 0.04, UV.y) * smoothstep(1.0, 0.96, UV.y);
	
	ALBEDO = line_color.rgb * glow_intensity;
	ALPHA = line_color.a * energy * length_fade * alpha_fade;
}
