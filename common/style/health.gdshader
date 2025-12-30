shader_type canvas_item;

uniform float speed = 10.0;
uniform int frames = 6;
uniform vec3 color: source_color;

void fragment() {
	float frame = float(int(TIME * speed) % frames);
	COLOR = texture(TEXTURE, UV + vec2(0.0, 0.0 + frame * 1.0 / float(frames)));
	if (COLOR == vec4(1.0, 1.0, 1.0, 1.0)) {
		COLOR = vec4(color, 1.0);
	}
}
