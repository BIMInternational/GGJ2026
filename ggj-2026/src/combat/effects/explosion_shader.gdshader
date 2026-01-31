shader_type canvas_item;

// Nuke explosion effect
uniform float explosion_speed : hint_range(0.5, 3.0) = 1.2;
uniform float shockwave_strength : hint_range(0.0, 1.0) = 0.6;
uniform float turbulence : hint_range(0.0, 0.3) = 0.15;
uniform float mushroom_height : hint_range(0.0, 0.4) = 0.25;
uniform float intensity : hint_range(0.5, 2.0) = 1.2;

// Explosion colors
uniform vec4 color_flash : source_color = vec4(1.0, 1.0, 0.95, 1.0);      // White flash
uniform vec4 color_core : source_color = vec4(1.0, 0.9, 0.4, 1.0);        // Yellow hot
uniform vec4 color_fire : source_color = vec4(1.0, 0.5, 0.1, 0.9);        // Orange fire
uniform vec4 color_smoke : source_color = vec4(0.4, 0.2, 0.1, 0.7);       // Dark smoke
uniform vec4 color_shockwave : source_color = vec4(1.0, 0.8, 0.5, 0.5);   // Shockwave ring

// Hash functions
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

// Fractal noise for fire turbulence
float fbm(vec2 p) {
    float value = 0.0;
    float amplitude = 0.5;
    value += amplitude * noise(p); p *= 2.0; amplitude *= 0.5;
    value += amplitude * noise(p); p *= 2.0; amplitude *= 0.5;
    value += amplitude * noise(p);
    return value;
}

void fragment() {
    vec2 uv = UV - 0.5;
    float time = TIME * explosion_speed;
    float dist = length(uv);
    float angle = atan(uv.y, uv.x);

    // Turbulent edge distortion
    float turb = fbm(vec2(angle * 3.0 + time, dist * 5.0 - time * 2.0)) * turbulence;

    // === MUSHROOM CLOUD SHAPE ===
    // Stem (vertical column rising up)
    float stem_width = 0.08 + uv.y * 0.05; // Wider at top
    float stem = smoothstep(stem_width, stem_width - 0.03, abs(uv.x));
    stem *= smoothstep(-0.1, 0.0, uv.y); // Only above center
    stem *= smoothstep(mushroom_height + 0.15, mushroom_height, uv.y); // Fade into cap

    // Cap (wide top part)
    vec2 cap_center = vec2(0.0, mushroom_height);
    float cap_dist = length(uv - cap_center);
    float cap_squash = length(vec2(uv.x * 0.7, (uv.y - mushroom_height) * 1.5)); // Elliptical
    float cap = 1.0 - smoothstep(0.15 - turb, 0.25, cap_squash);
    cap *= smoothstep(mushroom_height - 0.1, mushroom_height, uv.y); // Only at top

    // Combine mushroom shape
    float mushroom = max(stem * 0.7, cap);

    // === FIREBALL (lower central explosion) ===
    float fireball_dist = length(uv + vec2(0.0, 0.05)); // Slightly lower
    float fireball = 1.0 - smoothstep(0.0, 0.3 - turb, fireball_dist);

    // === SHOCKWAVE RING ===
    float wave_radius = fract(time * 0.4) * 0.6;
    float wave_width = 0.04;
    float shockwave = smoothstep(wave_radius - wave_width, wave_radius, dist);
    shockwave *= 1.0 - smoothstep(wave_radius, wave_radius + wave_width, dist);
    shockwave *= (1.0 - fract(time * 0.4)) * shockwave_strength; // Fade as it expands
    shockwave *= smoothstep(0.5, 0.2, dist); // Don't show at very edge

    // === COLOR COMPOSITION ===
    vec4 final_color = vec4(0.0);

    // Layer 1: Dark smoke (outer mushroom)
    float smoke_mask = max(mushroom, fireball * 0.5);
    smoke_mask *= fbm(uv * 8.0 + time) * 0.5 + 0.5; // Billowing
    final_color = mix(final_color, color_smoke, smoke_mask * 0.6);

    // Layer 2: Orange fire
    float fire_mask = fireball * 0.8 + mushroom * 0.4;
    fire_mask += fbm(uv * 6.0 - vec2(0.0, time * 2.0)) * 0.3; // Rising flames
    fire_mask = clamp(fire_mask, 0.0, 1.0);
    final_color = mix(final_color, color_fire, fire_mask);

    // Layer 3: Hot core
    float core_mask = 1.0 - smoothstep(0.0, 0.15, fireball_dist);
    core_mask += cap * 0.3; // Hot cap too
    final_color = mix(final_color, color_core, core_mask * intensity);

    // Layer 4: Central flash
    float flash = 1.0 - smoothstep(0.0, 0.08, dist);
    flash *= 1.0 + sin(time * 10.0) * 0.1; // Pulsing
    final_color = mix(final_color, color_flash, flash);

    // Layer 5: Shockwave ring
    final_color = mix(final_color, color_shockwave, shockwave);

    // Add glow around fireball
    float glow = 1.0 - smoothstep(0.2, 0.45, dist);
    glow *= 0.3;
    final_color.rgb += color_fire.rgb * glow;

    // === ALPHA ===
    float alpha = max(max(fireball, mushroom * 0.9), shockwave);
    alpha = clamp(alpha * intensity, 0.0, 1.0);

    // Soft outer mask
    float mask = 1.0 - smoothstep(0.4, 0.5, dist);

    COLOR = vec4(final_color.rgb, alpha * mask);
}
