shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

varying vec4 custom_pbr;

void vertex() {
	// INSTANCE_CUSTOM: r = roughness, g = metallic, b = specular, a = emission_energy
	custom_pbr = INSTANCE_CUSTOM;
}

void fragment() {
	ALBEDO = COLOR.rgb;
	ROUGHNESS = custom_pbr.r;
	METALLIC = custom_pbr.g;
	SPECULAR = custom_pbr.b;
	if (custom_pbr.a > 0.01) {
		EMISSION = COLOR.rgb * custom_pbr.a;
	}
}
