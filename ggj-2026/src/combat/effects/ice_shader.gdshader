shader_type canvas_item;

// Ice effect uniforms
uniform float ice_speed : hint_range(0.1, 2.0) = 0.6;
uniform float shimmer_intensity : hint_range(0.0, 1.0) = 0.4;
uniform float frost_amount : hint_range(0.0, 1.0) = 0.5;
uniform float crystal_scale : hint_range(1.0, 8.0) = 4.0;

// Ice colors
uniform vec4 color_core : source_color = vec4(0.85, 0.95, 1.0, 0.9);     // White/light blue center
uniform vec4 color_mid : source_color = vec4(0.5, 0.8, 1.0, 0.8);        // Light cyan
uniform vec4 color_outer : source_color = vec4(0.3, 0.6, 0.9, 0.6);      // Blue
uniform vec4 color_edge : source_color = vec4(0.2, 0.4, 0.7, 0.0);       // Dark blue/transparent

// Simple hash for noise
float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

// Value noise
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

// Lightweight FBM (3 octaves to save resources)
float fbm(vec2 p) {
    float value = 0.0;
    float amplitude = 0.5;
    value += amplitude * noise(p);
    amplitude *= 0.5;
    value += amplitude * noise(p * 2.0);
    amplitude *= 0.5;
    value += amplitude * noise(p * 4.0);
    return value;
}

// Crystalline facet pattern
float crystal_pattern(vec2 uv, float time) {
    // Create angular facets using noise
    float angle = atan(uv.y, uv.x);
    float dist = length(uv);

    // Faceted edges
    float facets = noise(vec2(angle * 6.0, dist * crystal_scale));
    facets = pow(facets, 0.8);

    // Subtle movement
    float shimmer = noise(vec2(angle * 8.0 + time * 2.0, dist * 10.0 + time));
    shimmer = pow(shimmer, 3.0) * shimmer_intensity;

    return facets * 0.3 + shimmer;
}

// Frost mist effect (lightweight)
float frost_mist(vec2 uv, float time) {
    // Slow drifting mist
    vec2 mist_uv = uv * 3.0 + vec2(time * 0.3, time * 0.2);
    float mist = fbm(mist_uv);

    // Fade mist toward edges
    float dist = length(uv);
    mist *= smoothstep(0.5, 0.2, dist);

    return mist * frost_amount;
}

void fragment() {
    vec2 uv = UV - 0.5;
    float time = TIME * ice_speed;
    float dist = length(uv);

    // Base ice shape
    float ice = 1.0 - smoothstep(0.0, 0.45, dist);

    // Add crystal facets
    float crystals = crystal_pattern(uv, time);
    ice += crystals * (1.0 - dist * 2.0);
    ice = clamp(ice, 0.0, 1.0);

    // Color gradient
    vec4 ice_color;
    if (ice > 0.8) {
        ice_color = mix(color_mid, color_core, (ice - 0.8) / 0.2);
    } else if (ice > 0.5) {
        ice_color = mix(color_outer, color_mid, (ice - 0.5) / 0.3);
    } else if (ice > 0.2) {
        ice_color = mix(color_edge, color_outer, (ice - 0.2) / 0.3);
    } else {
        ice_color = color_edge * (ice / 0.2);
    }

    // Add subtle frost mist overlay
    float mist = frost_mist(uv, time);
    ice_color.rgb = mix(ice_color.rgb, vec3(0.9, 0.95, 1.0), mist * 0.4);

    // Soft circular mask
    float mask = 1.0 - smoothstep(0.38, 0.5, dist);

    // Reflection highlight (fake specular)
    vec2 highlight_pos = uv - vec2(-0.12, -0.12);
    float highlight = 1.0 - smoothstep(0.0, 0.15, length(highlight_pos));
    highlight *= 0.3 * ice;

    // Final color with highlight
    vec3 final_color = ice_color.rgb + vec3(highlight);

    COLOR = vec4(final_color, ice * mask);
}
