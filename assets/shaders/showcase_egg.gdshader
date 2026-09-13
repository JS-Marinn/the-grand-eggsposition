shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

varying vec4 custom_pbr;
varying float local_y;

void vertex() {
	// INSTANCE_CUSTOM: r = roughness, g = metallic, b = specular, a = emission_energy
	custom_pbr = INSTANCE_CUSTOM;
	local_y = VERTEX.y;
}

void fragment() {
	vec3 base_col = COLOR.rgb;
	
	// Stylized vertical gradient: [-0.15, 0.15] -> [0.0, 1.0]
	// Subtly darkens bottom by 8% (grounding into velvet cushion) and brightens top by 6% (soft keylight)
	float h = clamp((local_y + 0.15) / 0.30, 0.0, 1.0);
	vec3 styled_albedo = base_col * mix(0.92, 1.06, h);
	
	// Stylized metal rim sheen (when metallic > 0.5)
	if (custom_pbr.g > 0.5) {
		float fresnel = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
		styled_albedo = mix(styled_albedo, styled_albedo * 1.35, fresnel * 0.45 * custom_pbr.g);
	}
	
	ALBEDO = styled_albedo;
	ROUGHNESS = custom_pbr.r;
	METALLIC = custom_pbr.g;
	SPECULAR = custom_pbr.b;
	if (custom_pbr.a > 0.01) {
		EMISSION = base_col * custom_pbr.a;
	}
}
