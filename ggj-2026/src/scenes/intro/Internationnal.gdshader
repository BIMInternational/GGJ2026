shader_type canvas_item;

// --- PARAMÈTRES ---
uniform vec4 shine_color : source_color = vec4(1.0, 1.0, 1.0, 1.0); // Couleur (blanc)
uniform float shine_speed : hint_range(0.0, 10.0) = 2.0;            // Vitesse du mouvement
uniform float shine_slope : hint_range(-2.0, 2.0) = 0.2;            // L'inclinaison (Biais)
uniform float shine_width : hint_range(0.01, 1.0) = 0.15;           // Largeur de la barre
uniform float pause_duration : hint_range(0.0, 5.0) = 2.0;          // Pause entre deux passages
uniform float progress : hint_range(0.0, 1.0) = 0.0;                // Progression manuelle (0 = début, 1 = fin)
uniform float alpha : hint_range(0.0, 1.0) = 1.0;                   // Opacité globale du sprite

void fragment() {
    vec4 texture_color = texture(TEXTURE, UV);
    
    // Garder la transparence de l'image (ne pas dessiner sur le fond transparent)
    if (texture_color.a == 0.0) {
        discard;
    }

    // --- LOGIQUE DU MOUVEMENT ---
    // Utilise le progress (0.0 à 1.0) pour contrôler la position du rayon
    // On mappe le progress de -1.0 à 2.0 pour que le rayon traverse tout l'écran
    float time_pos = mix(-1.0, 2.0, progress);

    // On calcule la position du "rayon" en biais
    // Si slope = 0.0, la barre est verticale. 
    // Si slope = 0.2, elle est légèrement penchée.
    float current_shape_pos = UV.x - (UV.y * shine_slope);

    // Calcul de la barre lumineuse
    // On vérifie si la position actuelle du pixel est à l'intérieur de la zone active du rayon
    float shine = step(time_pos, current_shape_pos) * step(current_shape_pos, time_pos + shine_width);
    
    // Ajout d'un petit adoucissement sur les bords (optionnel, pour faire moins "pixel dur")
    float dist = abs(current_shape_pos - (time_pos + shine_width / 2.0));
    float glow = 1.0 - smoothstep(0.0, shine_width / 2.0, dist);

    // Application de l'effet
    vec3 final_color = mix(texture_color.rgb, shine_color.rgb, glow * shine_color.a);
    
    COLOR = vec4(final_color, texture_color.a * alpha);
}