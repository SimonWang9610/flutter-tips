#version 460 core
precision mediump float;

#include <flutter/runtime_effect.glsl>

uniform vec2 uResolution;
uniform float uRotation;  // Rotation angle in radians
uniform float uScale;     // Zoom scale
uniform vec2 uShift;
uniform sampler2D uTexture;

// Convert screen coordinates to spherical UV mapping with rotation and scale
vec2 sphereUV(vec2 uv) {
    float x = (uv.x - 0.5) * 2.0 * uScale;
    float y = (uv.y - 0.5) * 2.0 * uScale;
    float z = sqrt(1.0 - x * x - y * y);

    // Rotate around Y-axis
    float newX = x * cos(uRotation) - z * sin(uRotation);
    float newZ = x * sin(uRotation) + z * cos(uRotation);

    // Convert to latitude and longitude
    float u = atan(newX, newZ) / 3.1415927 + 0.5;
    float v = asin(y) / 3.1415927 + 0.5;

    return vec2(u, v);
}

out vec4 fragColor;

void main() {
    vec2 uv = (FlutterFragCoord().xy - uShift)  / uResolution;
    vec2 sphereUVCoords = sphereUV(uv);
    
    vec4 color = texture(uTexture, sphereUVCoords);

    fragColor = color;
}
