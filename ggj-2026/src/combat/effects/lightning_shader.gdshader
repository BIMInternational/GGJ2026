shader_type canvas_item;

// Lightning/Electric effect
uniform float electric_speed : hint_range(1.0, 10.0) = 5.0;
uniform float bolt_intensity : hint_range(0.0, 1.0) = 0.7;
uniform float flicker_strength : hint_range(0.0, 1.0) = 0.4;
uniform float bolt_count : hint_range(3.0, 8.0) = 5.0;

// Electric colors
uniform vec4 color_core : source_color = vec4(1.0, 1.0, 1.0, 1.0);        // White hot center
uniform vec4 color_inner : source_color = vec4(0.8, 0.95, 1.0, 0.9);      // Light cyan
uniform vec4 color_bolt : source_color = vec4(0.4, 0.7, 1.0, 0.8);        // Electric blue
uniform vec4 color_glow : source_color = vec4(0.2, 0.4, 0.9, 0.0);        // Outer glow

// Hash functions
float hash(float n) {
    return fract(sin(n) * 43758.5453);
}

float hash2(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

// Noise for bolt variation
float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    float a = hash2(i);
    float b = hash2(i + vec2(1.0, 0.0));
    float c = hash2(i + vec2(0.0, 1.0));
    float d = hash2(i + vec2(1.0, 1.0));
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

// Generate a lightning bolt along a direction
float lightning_bolt(vec2 uv, float angle, float time, float seed) {
    // Rotate UV to bolt direction
    float c = cos(angle);
    float s = sin(angle);
    vec2 rotated = vec2(uv.x * c - uv.y * s, uv.x * s + uv.y * c);

    // Only draw bolt going outward (positive x in rotated space)
    if (rotated.x < 0.05) return 0.0;

    // Bolt path with jagged noise
    float bolt_time = time * 3.0 + seed * 10.0;
    float jagged = noise(vec2(rotated.x * 8.0 + bolt_time, seed * 5.0)) - 0.5;
    jagged += noise(vec2(rotated.x * 16.0 - bolt_time * 0.7, seed * 7.0)) * 0.5 - 0.25;

    // Distance from bolt center line
    float bolt_width = 0.03 + (1.0 - rotated.x) * 0.02;
    float dist_from_bolt = abs(rotated.y - jagged * 0.15);

    // Bolt intensity (brighter at center, fades outward)
    float bolt = 1.0 - smoothstep(0.0, bolt_width, dist_from_bolt);
    bolt *= smoothstep(0.5, 0.1, rotated.x); // Fade at end
    bolt *= smoothstep(0.05, 0.12, rotated.x); // Fade at start

    // Random flicker per bolt
    float flicker = hash(seed + floor(time * 15.0)) * flicker_strength + (1.0 - flicker_strength);
    bolt *= flicker;

    return bolt;
}

void fragment() {
    vec2 uv = UV - 0.5;
    float dist = length(uv);
    float time = TIME * electric_speed;

    // Core electric ball
    float core = 1.0 - smoothstep(0.0, 0.15, dist);
    float inner = 1.0 - smoothstep(0.1, 0.25, dist);

    // Pulsing core
    float pulse = sin(time * 4.0) * 0.1 + 0.9;
    core *= pulse;

    // Generate multiple lightning bolts
    float bolts = 0.0;
    for (float i = 0.0; i < 8.0; i++) {
        if (i >= bolt_count) break;

        // Each bolt at different angle, with time-based rotation
        float angle = (i / bolt_count) * 6.28318 + time * 0.3 + hash(i) * 2.0;
        float bolt = lightning_bolt(uv, angle, time, i);
        bolts = max(bolts, bolt);
    }
    bolts *= bolt_intensity;

    // Electric arc flicker (overall)
    float global_flicker = 0.85 + hash(floor(time * 20.0)) * 0.15;

    // Color composition
    vec4 final_color = vec4(0.0);

    // Outer glow
    float glow = 1.0 - smoothstep(0.2, 0.5, dist);
    glow *= 0.4 * global_flicker;
    final_color = mix(final_color, color_glow, glow);

    // Lightning bolts
    final_color = mix(final_color, color_bolt, bolts * global_flicker);

    // Inner ball
    final_color = mix(final_color, color_inner, inner * global_flicker);

    // Hot core
    final_color = mix(final_color, color_core, core);

    // Add electric shimmer to bolts
    float shimmer = noise(uv * 20.0 + time * 5.0) * bolts * 0.3;
    final_color.rgb += vec3(shimmer);

    // Alpha based on all elements
    float alpha = max(max(core, inner * 0.9), max(bolts * 0.8, glow * 0.5));
    alpha *= global_flicker;

    // Soft circular mask for outer bounds
    float mask = 1.0 - smoothstep(0.4, 0.5, dist);

    COLOR = vec4(final_color.rgb, alpha * mask);
}
