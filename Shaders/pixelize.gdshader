shader_type spatial;

const int pixel_size = 6;
uniform sampler2D screen_texture : hint_screen_texture, filter_nearest;
void fragment() {
	float x = float(int(FRAGCOORD.x) % pixel_size);
	float y = float(int(FRAGCOORD.y) % pixel_size);

	x = FRAGCOORD.x + floor(float(pixel_size) / 2.0) - x;
	y = FRAGCOORD.y + floor(float(pixel_size) / 2.0) - y;

	ALBEDO = texture(screen_texture, vec2(x,y) / VIEWPORT_SIZE).xyz;
}