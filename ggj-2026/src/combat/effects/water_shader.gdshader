shader_type canvas_item;

// Water effect uniforms
uniform float water_speed : hint_range(0.5, 3.0) = 1.5;
uniform float wave_intensity : hint_range(0.0, 1.0) = 0.4;
uniform float ripple_scale : hint_range(1.0, 8.0) = 4.0;
uniform float shine_intensity : hint_range(0.0, 1.0) = 0.5;

// Water colors
uniform vec4 color_core : source_color = vec4(0.7, 0.9, 1.0, 0.9);       // Light blue center
uniform vec4 color_mid : source_color = vec4(0.3, 0.6, 1.0, 0.8);        // Medium blue
uniform vec4 color_outer : source_color = vec4(0.15, 0.4, 0.8, 0.6);     // Darker blue
uniform vec4 color_edge : source_color = vec4(0.1, 0.25, 0.5, 0.0);      // Dark blue/transparent

// Simple hash
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

// Lightweight FBM (3 octaves)
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

void fragment() {
    vec2 uv = UV - 0.5;
    float time = TIME * water_speed;
    float dist = length(uv);

    // Concentric ripple waves
    float ripples = sin((dist * ripple_scale * 10.0) - time * 4.0) * 0.5 + 0.5;
    ripples *= (1.0 - dist * 1.5); // Fade ripples toward edges

    // Flowing noise distortion
    vec2 flow_uv = uv * 3.0 + vec2(time * 0.5, time * 0.3);
    float flow = fbm(flow_uv);

    // Combine for water surface
    float water = 1.0 - smoothstep(0.0, 0.45, dist);
    water += ripples * wave_intensity * 0.3;
    water += flow * 0.15;
    water = clamp(water, 0.0, 1.0);

    // Color gradient
    vec4 water_color;
    if (water > 0.8) {
        water_color = mix(color_mid, color_core, (water - 0.8) / 0.2);
    } else if (water > 0.5) {
        water_color = mix(color_outer, color_mid, (water - 0.5) / 0.3);
    } else if (water > 0.2) {
        water_color = mix(color_edge, color_outer, (water - 0.2) / 0.3);
    } else {
        water_color = color_edge * (water / 0.2);
    }

    // Specular shine highlight
    vec2 shine_pos = uv - vec2(-0.1, -0.1);
    float shine = 1.0 - smoothstep(0.0, 0.12, length(shine_pos));
    shine *= shine_intensity * water;

    // Secondary smaller highlight
    vec2 shine2_pos = uv - vec2(0.08, -0.15);
    float shine2 = 1.0 - smoothstep(0.0, 0.06, length(shine2_pos));
    shine2 *= shine_intensity * 0.5 * water;

    // Soft circular mask
    float mask = 1.0 - smoothstep(0.38, 0.5, dist);

    // Final color
    vec3 final_color = water_color.rgb + vec3(shine + shine2);

    COLOR = vec4(final_color, water * mask);
}
