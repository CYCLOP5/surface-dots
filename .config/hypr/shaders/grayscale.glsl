#version 320 es
precision highp float;
in vec2 v_texcoord;
uniform sampler2D tex;
out vec4 fragColor;

// 4x4 Bayer Matrix for ordered dithering
float getBayer(vec2 pos) {
    int x = int(mod(pos.x, 4.0));
    int y = int(mod(pos.y, 4.0));
    
    if (x == 0) {
        if (y == 0) return 0.0/16.0; if (y == 1) return 12.0/16.0; if (y == 2) return 3.0/16.0; return 15.0/16.0;
    } else if (x == 1) {
        if (y == 0) return 8.0/16.0; if (y == 1) return 4.0/16.0; if (y == 2) return 11.0/16.0; return 7.0/16.0;
    } else if (x == 2) {
        if (y == 0) return 2.0/16.0; if (y == 1) return 14.0/16.0; if (y == 2) return 1.0/16.0; return 13.0/16.0;
    } else {
        if (y == 0) return 10.0/16.0; if (y == 1) return 6.0/16.0; if (y == 2) return 9.0/16.0; return 5.0/16.0;
    }
    return 0.5;
}

// Simple noise for subtle texture
float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void main() {
    vec4 pixColor = texture(tex, v_texcoord);
    
    // Luma Conversion
    float gray = dot(pixColor.rgb, vec3(0.299, 0.587, 0.114));
    
    // E-ink gamma curve
    gray = pow(gray, 1.5);
    
    // Gentle S-curve
    gray = smoothstep(0.05, 0.95, gray);
    
    // Very fine, barely visible paper grain
    vec2 screenPos = gl_FragCoord.xy;
    float paperGrain = (hash(screenPos * 0.5) - 0.5) * 0.015;
    gray += paperGrain;
    
    // Very light dithering only to mid-tones
    float bayerValue = getBayer(gl_FragCoord.xy);
    float midtoneRange = 1.0 - abs(gray - 0.5) * 2.0;
    float ditherStrength = 0.03 * smoothstep(0.2, 0.6, midtoneRange);
    gray += (bayerValue - 0.5) * ditherStrength;
    
    gray = clamp(gray, 0.0, 1.0);
    
    
    // E-inkish colors
    // Paper: warm, slightly yellow-beige
    // Ink: soft black with slight warmth
    vec3 paperColor = vec3(0.96, 0.94, 0.87);  
    vec3 inkColor   = vec3(0.10, 0.10, 0.11);  
    
    float inkAmount = 1.0 - gray;
    inkAmount = pow(inkAmount, 0.9); // Slight curve
    
    vec3 finalColor = mix(paperColor, inkColor, inkAmount);
    
    fragColor = vec4(finalColor, pixColor.a);
}