shader_type canvas_item;

void fragment() {
	vec4 color = texture(TEXTURE, UV + vec2(.005 * TIME, -.08 * TIME));
	COLOR = color;
}