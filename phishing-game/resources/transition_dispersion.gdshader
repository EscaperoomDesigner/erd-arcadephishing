// Pixel Block Transition Shader
// Phase 1 (progress 0.0 -> 0.5): random pixels fill in from outside inward
// Phase 2 (progress 0.5 -> 1.0): random pixels clear from center outward

shader_type canvas_item;

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform vec2 screen_size = vec2(640.0, 512.0);
uniform float block_size : hint_range(1.0, 32.0) = 4.0;

// Deterministic per-block random value [0, 1]
float hash(vec2 block_id) {
	vec2 p = fract(block_id * vec2(0.1031, 0.1030));
	p += dot(p, p.yx + 33.33);
	return fract((p.x + p.y) * p.x);
}

void fragment() {
	// Snap all pixels in the same block to the same block ID
	vec2 pixel = UV * screen_size;
	vec2 block_id = floor(pixel / block_size);
	vec2 block_center = (block_id + 0.5) * block_size;
	vec2 block_uv = block_center / screen_size;

	// Per-block random value
	float r = hash(block_id);

	// Aspect-corrected distance from screen center [0=center, 1=corner]
	vec2 centered = block_uv - 0.5;
	float aspect = screen_size.x / screen_size.y;
	centered.y /= aspect;
	float max_dist = length(vec2(0.5, 0.5 / aspect));
	float dist = clamp(length(centered) / max_dist, 0.0, 1.0);

	bool is_black;

	if (progress <= 0.5) {
		// Phase 1: pixels fill in, outer first
		// Outer blocks (dist=1) get low thresholds (activate early),
		// inner blocks (dist=0) get high thresholds (activate late).
		// 70% driven by distance, 30% random scatter.
		float threshold = (1.0 - dist) * 0.7 + r * 0.3;
		float p = progress * 2.0;
		is_black = p >= threshold;
	} else {
		// Phase 2: pixels clear, inner first
		// Inner blocks (dist=0) get low thresholds (clear early),
		// outer blocks (dist=1) get high thresholds (clear late).
		float threshold = dist * 0.7 + r * 0.3;
		float p = (progress - 0.5) * 2.0;
		is_black = p < threshold;
	}

	if (is_black) {
		COLOR = vec4(0.0, 0.0, 0.0, 1.0);
	} else {
		discard;
	}
}
