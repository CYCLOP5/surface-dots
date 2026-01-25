#version 320 es
precision highp float;

in vec2 v_texcoord;
uniform sampler2D tex;
out vec4 fragColor;

// 4x4 Bayer Matrix
float getBayer(vec2 pos) {
    int x = int(mod(pos.x, 4.0));
    int y = int(mod(pos.y, 4.0));
    const mat4 bayer = mat4(
        0.0, 12.0,  3.0, 15.0,
        8.0,  4.0, 11.0,  7.0,
        2.0, 14.0,  1.0, 13.0,
        10.0,  6.0,  9.0,  5.0
    );
    // Normalized 0.0 - 1.0
    return bayer[x][y] / 16.0;
}

// High frequency noise for paper texture
float hash(vec2 p) {
    return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void main() {
    vec4 pixColor = texture(tex, v_texcoord);
    
    // Luma Conversion
    float gray = dot(pixColor.rgb, vec3(0.299, 0.587, 0.114));
    
    // Gentle Gamma 
    gray = pow(gray, 1.15);
    
    // Contrast
    gray = smoothstep(0.1, 0.9, gray);
    
    // Selective Texture Application
    vec2 screenPos = gl_FragCoord.xy;
    
    // Noise and dither
    float paperGrain = (hash(screenPos) - 0.5) * 0.03;
    float bayerValue = getBayer(screenPos);
    
    // MASKING
    float textureMask = smoothstep(0.4, 0.9, gray);
    
    // Apply grain only to paper
    gray += paperGrain * textureMask;
    
    // Apply dithering only to paper
    float ditherStrength = 0.06;
    gray += (bayerValue - 0.5) * ditherStrength * textureMask;

    // Final Clamp
    gray = clamp(gray, 0.0, 1.0);
    
    // Paper: Warm Kindle-style
    vec3 paperColor = vec3(0.96, 0.94, 0.88); 
    // Ink: Deeper gray
    vec3 inkColor   = vec3(0.12, 0.12, 0.14);
    
    vec3 finalColor = mix(inkColor, paperColor, gray);
    
    fragColor = vec4(finalColor, pixColor.a);
}