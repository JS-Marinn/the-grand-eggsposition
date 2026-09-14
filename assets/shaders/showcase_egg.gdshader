shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

varying vec4 custom_pbr;

void vertex() {
	// INSTANCE_CUSTOM: r = roughness, g = metallic, b = specular, a = emission_energy
	custom_pbr = INSTANCE_CUSTOM;
}

// Exact sRGB to Linear RGB conversion matching Godot's internal StandardMaterial3D color pipeline
vec3 srgb_to_linear(vec3 c) {
	return mix(
		pow((c + vec3(0.055)) * (1.0 / 1.055), vec3(2.4)),
		c * (1.0 / 12.92),
		lessThan(c, vec3(0.04045))
	);
}

void fragment() {
	ALBEDO = srgb_to_linear(COLOR.rgb);
	ROUGHNESS = custom_pbr.r;
	METALLIC = custom_pbr.g;
	SPECULAR = custom_pbr.b;
	if (custom_pbr.a > 0.01) {
		EMISSION = ALBEDO * custom_pbr.a;
	}
}


