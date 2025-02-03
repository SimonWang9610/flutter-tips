#version 460 core

#include <flutter/runtime_effect.glsl>

uniform vec2 uResolution;
uniform vec3 uRotation;
uniform sampler2D uTexture;

out vec4 fragColor;

const float PI = 3.14159265359;
const float RADIUS = 0.8;  // Matching the point sphere radius

vec3 rotateX(vec3 p, float angle) {
    float s = sin(angle);
    float c = cos(angle);
    return vec3(
        p.x,
        p.y * c - p.z * s,
        p.y * s + p.z * c
    );
}

vec3 rotateY(vec3 p, float angle) {
    float s = sin(angle);
    float c = cos(angle);
    return vec3(
        p.x * c + p.z * s,
        p.y,
        -p.x * s + p.z * c
    );
}

void main() {
    // Normalize coordinates to match CustomPainter's coordinate system
    vec2 uv = (FlutterFragCoord().xy / uResolution.xy) * 2.0 - 1.0;
    uv.x *= uResolution.x / uResolution.y;

    // Ray setup matching CustomPainter's view
    vec3 ro = vec3(0.0, 0.0, -2.0);
    vec3 rd = normalize(vec3(uv, 1.0));
    
    // Apply rotations in same order as CustomPainter
    rd = rotateY(rd, uRotation.y);
    rd = rotateX(rd, uRotation.x);

    // Sphere intersection
    float b = 2.0 * dot(ro, rd);
    float c = dot(ro, ro) - RADIUS * RADIUS;
    float h = b * b - 4.0 * c;
    
    if (h < 0.0) {
        fragColor = vec4(0.0, 0.0, 0.0, 0.0);
        return;
    }

    float t = (-b - sqrt(h)) / 2.0;
    
    if (t < 0.0) {
        fragColor = vec4(0.0, 0.0, 0.0, 0.0);
        return;
    }

    // Calculate position and normal
    vec3 pos = ro + t * rd;
    vec3 normal = normalize(pos);

    // UV mapping matching point sphere coordinates
    float u = 0.5 + atan(normal.z, normal.x) / (2.0 * PI);
    float v = 0.5 - asin(normal.y) / PI;
    
    vec4 texColor = texture(uTexture, vec2(u, v));
    
    // Lighting to match point visibility
    vec3 lightDir = normalize(vec3(1.0, 0.5, -1.0));
    float diff = max(dot(normal, lightDir), 0.0);
    float ambient = 0.2;
    
    fragColor = texColor * (diff + ambient);
}