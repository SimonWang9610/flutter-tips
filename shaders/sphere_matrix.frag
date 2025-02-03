#version 460 core
precision mediump float;

#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uSize;
uniform mat4 uRotation;


vec2 flutterOffsetToSphereUV(vec2 offset) {
    vec2 center = vec2(0.5, 0.5);

    float x = (offset.x - center.x) * 2.0;
    float y = (offset.y - center.y) * 2.0;
    float z = sqrt(1.0 - x * x - y * y);

    vec3 c = vec3(x, y, z);

    c = (uRotation * vec4(c, 1.0)).xyz;

    float u = atan(c.x, c.z) / 3.1415927 + 0.5;
    float v = asin(c.y) / 3.1415927 + 0.5;

    return vec2(u, v);
}

vec2 geoToUV(vec2 geo) {
    float latRad = geo.x * 3.1415927/180.0;
    float lonRad = geo.y * 3.1415927/180.0;

    float x = sin(latRad);
    float y = cos(latRad) * cos(lonRad);
    float z = cos(latRad) * sin(lonRad);

    vec3 c = vec3(x, y, z);

    c = (uRotation * vec4(c, 1.0)).xyz;

    float u = atan(c.x, c.z) / 3.1415927 + 0.5;
    float v = asin(c.y) / 3.1415927 + 0.5;

    return vec2(u, v);
}

out vec4 fragColor;

void main() {
    vec2 uv = FlutterFragCoord().xy / uSize;
    vec2 sphereUVCoords = flutterOffsetToSphereUV(uv);
    vec4 color = texture(uTexture, sphereUVCoords);

    fragColor = color;

}