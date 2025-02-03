#version 460 core
precision mediump float;

#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uSize;
uniform float uRotationX;
uniform float uRotationY;
uniform float uRotationZ;
uniform float uScale;


vec3 rotate(vec3 cp) {
    float x = cp.x;
    float y = cp.y;
    float z = cp.z;

    // Rotate around X-axis
    float newY = y * cos(uRotationX) - z * sin(uRotationX);
    float newZ = y * sin(uRotationX) + z * cos(uRotationX);

    // Rotate around Y-axis
    float newX = x * cos(uRotationY) - newZ * sin(uRotationY);
    newZ = x * sin(uRotationY) + newZ * cos(uRotationY);

    // Rotate around Z-axis
    float newX2 = newX * cos(uRotationZ) - newY * sin(uRotationZ);
    float newY2 = newX * sin(uRotationZ) + newY * cos(uRotationZ);

    return vec3(newX2, newY2, newZ);
}

vec2 sphereUV(vec2 uv) {
    float x = (uv.x - 0.5) * 2.0 * uScale;
    float y = (uv.y - 0.5) * 2.0 * uScale;
    float z = sqrt(1.0 - x * x - y * y);

    vec3 p = rotate(vec3(x, y, z));

    // Convert to latitude and longitude
    float u = atan(p.x, p.z) / 3.1415927 + 0.5;
    float v = asin(p.y) / 3.1415927 + 0.5;
    return vec2(u, v);
}



out vec4 fragColor;

void main() {
    vec2 uv = FlutterFragCoord().xy / uSize;
    vec2 sphereUVCoords = sphereUV(uv);
    
    vec4 color = texture(uTexture, sphereUVCoords);

    fragColor = color;


}