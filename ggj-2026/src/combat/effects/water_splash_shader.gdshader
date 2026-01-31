shader_type canvas_item;

// Water puddle effect - flat elliptical shape
uniform float splash_speed : hint_range(0.5, 3.0) = 1.2;
uniform float puddle_squash : hint_range(0.2, 0.6) = 0.35;
uniform float edge_wobble : hint_range(0.0, 0.15) = 0.08;
uniform float fade_progress : hint_range(0.0, 1.0) = 0.0;

// Puddle colors
uniform vec4 color_center : source_color = vec4(0.5, 0.75, 1.0, 0.7);
uniform vec4 color_edge : source_color = vec4(0.2, 0.5, 0.9, 0.0);

// Simple hash for edge variation
float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

void fragment() {
    vec2 uv = UV - 0.5;
    float time = TIME * splash_speed;

    // Elliptical puddle shape (squashed vertically for top-down view)
    vec2 puddle_uv = vec2(uv.x, uv.y / puddle_squash);
    float dist = length(puddle_uv);

    // Irregular edge using noise
    float angle = atan(puddle_uv.y, puddle_uv.x);
    float edge_noise = noise(vec2(angle * 3.0 + time * 0.2, 1.0)) * edge_wobble;

    // Base puddle shape with wobbly edge
    float puddle = 1.0 - smoothstep(0.3 - edge_noise, 0.45, dist);

    // Subtle ripple effect (elliptical)
    float ripple = sin((dist * 12.0) - time * 2.5) * 0.5 + 0.5;
    ripple *= (1.0 - dist * 1.5) * 0.15;

    // Color gradient from center to edge
    float color_blend = 1.0 - smoothstep(0.0, 0.4, dist);
    vec4 puddle_color = mix(color_edge, color_center, color_blend);

    // Add subtle ripple brightness
    puddle_color.rgb += vec3(ripple * 0.3);

    // Specular highlight (off-center for depth)
    vec2 highlight_uv = vec2(uv.x - 0.08, (uv.y + 0.05) / puddle_squash);
    float highlight = 1.0 - smoothstep(0.0, 0.12, length(highlight_uv));
    puddle_color.rgb += vec3(highlight * 0.25 * puddle);

    // Fade out over lifetime
    float alpha = puddle * (1.0 - fade_progress);

    COLOR = vec4(puddle_color.rgb, alpha * puddle_color.a);
}
