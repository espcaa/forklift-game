shader_type spatial;
render_mode unshaded;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform float vignette_strength : hint_range(0.0, 2.0) = 0.8;
uniform float speed_mult = 0.0;
uniform float saturation = 1.5; // 1.0 = original, >1 = more saturated

void fragment() {
    vec2 uv = SCREEN_UV;
    float dist = distance(uv, vec2(0.5));
    float vignette = 1.0 - smoothstep(0.4, vignette_strength + 0.6, dist);

    vec4 col = texture(SCREEN_TEXTURE, SCREEN_UV);
    
    // Boost brightness
    col.rgb *= 1.2 * speed_mult;

    // Increase saturation (simple method)
    float gray = dot(col.rgb, vec3(0.299, 0.587, 0.114));
    col.rgb = mix(vec3(gray), col.rgb, saturation);

    // Apply vignette
    col.rgb *= vignette;

    ALBEDO = col.rgb;
}

