// Tutorial: https://www.youtube.com/watch?v=E401x98N6iA
shader_type canvas_item;
render_mode unshaded, skip_vertex_transform;

uniform bool disable_shader = false;
uniform vec2 screen_size = vec2(1152.0, 648.0);
uniform bool disable_curvature = false;
uniform float curvature = 2.0;
uniform float scanline_intensity: hint_range(0.0, 1.0) = 0.2;
uniform float vignette_power = 4.0;
uniform float blur = 0.5;
uniform sampler2D screen_texture: hint_screen_texture, filter_linear_mipmap;

vec3 apply_shader(vec2 uv) {
	vec2 centered_uv = uv * 2.0 - 1.0;
	vec3 vignette = vec3(length(pow(abs(centered_uv), vec2(4.0))) / 3.0);

	vec3 screen_color = vec3(0.0);
	if (disable_curvature) {
		vec3 cutoff = vec3(step(abs(centered_uv.x), 1.0) * step(abs(centered_uv.y), 1.0));
		vec3 scanlines = vec3(sin(centered_uv.y * screen_size.y * 8.0) * scanline_intensity + 0.9);
		screen_color = textureLod(screen_texture, (centered_uv + 1.0) / 2.0, blur).rgb * cutoff * scanlines;
	}
	else {
		vec2 uv_offset = centered_uv.yx / curvature;
		vec2 warped_uv = centered_uv + centered_uv * pow(uv_offset, vec2(2.0));
		vec3 cutoff = vec3(step(abs(warped_uv.x), 1.0) * step(abs(warped_uv.y), 1.0));
		vec3 scanlines = vec3(sin(warped_uv.y * screen_size.y * 8.0) * scanline_intensity + 0.9);
		screen_color = textureLod(screen_texture, (warped_uv + 1.0) / 2.0, blur).rgb * cutoff * scanlines;
	}
	screen_color -= vignette * vignette_power;
	return screen_color;
}

void fragment() {
	if (disable_shader) {
		COLOR = texture(screen_texture, SCREEN_UV);
	}
	else {
		COLOR.rgb = apply_shader(SCREEN_UV);
	}
}
