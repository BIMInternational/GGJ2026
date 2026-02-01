shader_type canvas_item;

// Sandstorm effect uniforms
uniform float wind_speed : hint_range(0.1, 2.0) = 0.5;
uniform float wind_direction : hint_range(-1.0, 1.0) = 1.0; // -1 = left, 1 = right
uniform float haze_intensity : hint_range(0.0, 0.5) = 0.15;
uniform float dust_density : hint_range(0.0, 1.0) = 0.3;
uniform float dust_size : hint_range(1.0, 20.0) = 8.0;

// Color tinting
uniform vec4 haze_color : source_color = vec4(0.85, 0.75, 0.55, 1.0);  // Sandy beige
uniform vec4 dust_color : source_color = vec4(0.9, 0.8, 0.6, 1.0);     // Light sand

// Noise functions
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

// Fractal brownian motion for haze
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

// Dust particle function - creates scattered bright spots
float dust_particles(vec2 uv, float time) {
    float particles = 0.0;

    // Layer 1 - small fast particles
    vec2 dust_uv1 = uv * dust_size + vec2(time * wind_direction * 2.0, time * 0.3);
    float p1 = noise(dust_uv1);
    p1 = smoothstep(0.75, 0.85, p1);

    // Layer 2 - medium particles
    vec2 dust_uv2 = uv * dust_size * 0.6 + vec2(time * wind_direction * 1.5, time * 0.2);
    float p2 = noise(dust_uv2 + 100.0);
    p2 = smoothstep(0.78, 0.88, p2);

    // Layer 3 - larger slower particles
    vec2 dust_uv3 = uv * dust_size * 0.3 + vec2(time * wind_direction * 0.8, time * 0.1);
    float p3 = noise(dust_uv3 + 200.0);
    p3 = smoothstep(0.8, 0.9, p3);

    particles = p1 * 0.4 + p2 * 0.35 + p3 * 0.25;
    return particles;
}

void fragment() {
    vec2 uv = UV;
    float time = TIME * wind_speed;

    // Wind direction vector
    vec2 wind = vec2(wind_direction, 0.15);

    // --- Haze Layer ---
    // Moving atmospheric haze
    vec2 haze_uv = uv * 2.0 + wind * time * 0.3;
    float haze1 = fbm(haze_uv);
    float haze2 = fbm(haze_uv * 1.5 + vec2(50.0, 30.0) - wind * time * 0.2);
    float haze = (haze1 + haze2) * 0.5;

    // Subtle variation in haze density
    haze = haze * 0.7 + 0.3;

    // --- Dust Particles ---
    float dust = dust_particles(uv, time);

    // --- Combine Effects ---
    // Base haze tint
    vec3 final_color = haze_color.rgb;

    // Add dust highlights
    final_color = mix(final_color, dust_color.rgb, dust * dust_density);

    // Calculate alpha - subtle overlay
    float alpha = haze_intensity * haze;
    alpha += dust * dust_density * 0.15;

    // Clamp to keep it subtle
    alpha = clamp(alpha, 0.0, 0.4);

    COLOR = vec4(final_color, alpha);
}
