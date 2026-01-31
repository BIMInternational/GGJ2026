shader_type canvas_item;

// Fire effect uniforms
uniform float fire_speed : hint_range(0.5, 5.0) = 2.5;
uniform float fire_intensity : hint_range(0.5, 3.0) = 1.8;
uniform float noise_scale : hint_range(1.0, 10.0) = 3.0;
uniform float pulse_strength : hint_range(0.0, 0.5) = 0.15;

// Fire colors
uniform vec4 color_core : source_color = vec4(1.0, 1.0, 0.9, 1.0);      // White/yellow center
uniform vec4 color_mid : source_color = vec4(1.0, 0.7, 0.2, 1.0);       // Orange
uniform vec4 color_outer : source_color = vec4(1.0, 0.3, 0.0, 1.0);     // Red-orange
uniform vec4 color_edge : source_color = vec4(0.6, 0.1, 0.0, 0.0);      // Dark red/transparent

// Noise function
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

// Fractal brownian motion
float fbm(vec2 p) {
    float value = 0.0;
    float amplitude = 0.5;
    float frequency = 1.0;

    for (int i = 0; i < 4; i++) {
        value += amplitude * noise(p * frequency);
        amplitude *= 0.5;
        frequency *= 2.0;
    }

    return value;
}

void fragment() {
    // Center UV coordinates (-0.5 to 0.5)
    vec2 uv = UV - 0.5;

    // Time-based animation
    float time = TIME * fire_speed;

    // Distance from center (for radial fireball)
    float dist = length(uv);

    // Angle for radial noise
    float angle = atan(uv.y, uv.x);

    // Animated noise distortion (radial)
    float radial_noise = fbm(vec2(angle * 2.0 + time * 0.5, dist * noise_scale + time));
    float distortion = radial_noise * pulse_strength;

    // Pulsing radius
    float pulse = sin(time * 3.0) * 0.03 + 1.0;

    // Distorted distance for fire edge
    float fire_dist = dist - distortion;

    // Fire intensity: strongest at center, fading outward
    float fire = 1.0 - smoothstep(0.0, 0.4 * pulse, fire_dist);

    // Add turbulent edges
    float edge_noise = fbm(vec2(angle * 4.0 + time, dist * noise_scale * 2.0 - time * 1.5));
    fire += edge_noise * 0.3 * (1.0 - dist * 2.0);
    fire = clamp(fire * fire_intensity, 0.0, 1.0);

    // Color gradient based on fire intensity (core to edge)
    vec4 fire_color;
    if (fire > 0.85) {
        fire_color = mix(color_mid, color_core, (fire - 0.85) / 0.15);
    } else if (fire > 0.6) {
        fire_color = mix(color_outer, color_mid, (fire - 0.6) / 0.25);
    } else if (fire > 0.3) {
        fire_color = mix(color_edge, color_outer, (fire - 0.3) / 0.3);
    } else {
        fire_color = color_edge * (fire / 0.3);
    }

    // Soft circular mask
    float mask = 1.0 - smoothstep(0.35, 0.5, dist);

    // Final alpha
    float alpha = fire * mask;

    COLOR = vec4(fire_color.rgb, alpha);
}
