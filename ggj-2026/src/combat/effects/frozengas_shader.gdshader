shader_type canvas_item;

// Gas effect uniforms
uniform float gas_speed : hint_range(0.1, 3.0) = 0.8;
uniform float gas_density : hint_range(0.5, 2.0) = 1.2;
uniform float noise_scale : hint_range(1.0, 8.0) = 2.5;
uniform float swirl_strength : hint_range(0.0, 1.0) = 0.3;

// Gas colors
uniform vec4 color_core : source_color = vec4(0.4, 0.9, 0.3, 0.7);       // Bright green center
uniform vec4 color_mid : source_color = vec4(0.3, 0.7, 0.2, 0.5);        // Medium green
uniform vec4 color_outer : source_color = vec4(0.2, 0.5, 0.15, 0.3);     // Darker green
uniform vec4 color_edge : source_color = vec4(0.1, 0.3, 0.1, 0.0);       // Faded edge

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

// Fractal brownian motion for cloudy look
float fbm(vec2 p) {
    float value = 0.0;
    float amplitude = 0.5;
    float frequency = 1.0;

    for (int i = 0; i < 5; i++) {
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
    float time = TIME * gas_speed;

    // Distance from center
    float dist = length(uv);

    // Angle for swirling motion
    float angle = atan(uv.y, uv.x);

    // Swirling distortion
    float swirl = swirl_strength * (1.0 - dist * 2.0);
    angle += swirl * sin(time + dist * 6.0);

    // Reconstruct UV with swirl
    vec2 swirled_uv = vec2(cos(angle), sin(angle)) * dist;

    // Multiple layers of noise for cloudy effect
    float cloud1 = fbm(swirled_uv * noise_scale + vec2(time * 0.3, time * 0.2));
    float cloud2 = fbm(swirled_uv * noise_scale * 1.5 - vec2(time * 0.2, time * 0.4));
    float cloud3 = fbm(swirled_uv * noise_scale * 0.7 + vec2(time * 0.1, -time * 0.15));

    // Combine cloud layers
    float clouds = (cloud1 + cloud2 * 0.7 + cloud3 * 0.5) / 2.2;

    // Pulsing effect
    float pulse = sin(time * 2.0) * 0.1 + 1.0;

    // Gas density based on distance and clouds
    float gas = clouds * (1.0 - smoothstep(0.0, 0.45 * pulse, dist));
    gas = clamp(gas * gas_density, 0.0, 1.0);

    // Color gradient based on gas density
    vec4 gas_color;
    if (gas > 0.7) {
        gas_color = mix(color_mid, color_core, (gas - 0.7) / 0.3);
    } else if (gas > 0.4) {
        gas_color = mix(color_outer, color_mid, (gas - 0.4) / 0.3);
    } else if (gas > 0.15) {
        gas_color = mix(color_edge, color_outer, (gas - 0.15) / 0.25);
    } else {
        gas_color = color_edge * (gas / 0.15);
    }

    // Soft circular mask
    float mask = 1.0 - smoothstep(0.3, 0.5, dist);

    // Final alpha with wispy edges
    float alpha = gas * mask * gas_color.a;

    COLOR = vec4(gas_color.rgb, alpha);
}
