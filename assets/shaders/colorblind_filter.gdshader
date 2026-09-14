shader_type canvas_item;

// Fullscreen Colorblind & Accessibility Filter for The Grand Eggsposition
// Uses standard Brettel / Vienot simulation matrices for color vision deficiencies
// with adjustable intensity slider (0.0 to 1.0).

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform int mode : hint_range(0, 4) = 0; // 0: Normal, 1: Protanopia, 2: Deuteranopia, 3: Tritanopia, 4: Achromatopsia
uniform float intensity : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	vec4 c = texture(screen_texture, SCREEN_UV);
	vec3 sim = c.rgb;

	if (mode == 1) {
		// Protanopia (L-cone weakness / red-blindness)
		sim.r = 0.56667 * c.r + 0.43333 * c.g;
		sim.g = 0.55833 * c.r + 0.44167 * c.g;
		sim.b = 0.24167 * c.g + 0.75833 * c.b;
	} else if (mode == 2) {
		// Deuteranopia (M-cone weakness / green-blindness)
		sim.r = 0.625 * c.r + 0.375 * c.g;
		sim.g = 0.700 * c.r + 0.300 * c.g;
		sim.b = 0.300 * c.g + 0.700 * c.b;
	} else if (mode == 3) {
		// Tritanopia (S-cone weakness / blue-blindness)
		sim.r = 0.950 * c.r + 0.050 * c.g;
		sim.g = 0.43333 * c.g + 0.56667 * c.b;
		sim.b = 0.475 * c.g + 0.525 * c.b;
	} else if (mode == 4) {
		// Achromatopsia (Monochromacy / Grayscale luminance)
		float lum = dot(c.rgb, vec3(0.299, 0.587, 0.114));
		sim = vec3(lum);
	}

	sim = mix(c.rgb, sim, clamp(intensity, 0.0, 1.0));
	COLOR = vec4(clamp(sim, 0.0, 1.0), c.a);
}
