precision mediump float;

uniform sampler2D uTexture;  // Sphere texture
uniform vec2 uResolution;    // Screen size
uniform float uRotation;     // Rotation around Y-axis
uniform float uScale;        // Zoom scale
uniform vec2 uStart;         // Start lat/lng in radians
uniform vec2 uEnd;           // End lat/lng in radians
uniform float uProgress;     // Animation progress (0.0 to 1.0)

// Convert lat/lng to 3D unit sphere coordinates
vec3 latLngToSphere(vec2 latLng) {
    float phi = latLng.x; // Latitude in radians
    float theta = latLng.y; // Longitude in radians

    float x = cos(phi) * cos(theta);
    float y = sin(phi);
    float z = cos(phi) * sin(theta);

    // Apply rotation around Y-axis
    float xRot = x * cos(uRotation) - z * sin(uRotation);
    float zRot = x * sin(uRotation) + z * cos(uRotation);

    return vec3(xRot, y, zRot);
}

// Compute great-circle interpolation (SLERP)
vec3 greatCircleInterpolation(vec3 start, vec3 end, float t) {
    float omega = acos(dot(start, end));
    float sinOmega = sin(omega);

    float w1 = sin((1.0 - t) * omega) / sinOmega;
    float w2 = sin(t * omega) / sinOmega;

    return normalize(start * w1 + end * w2);
}

void main() {
    vec2 uv = gl_FragCoord.xy / uResolution;
    
    // Convert start and end lat/lng to 3D
    vec3 start3D = latLngToSphere(uStart);
    vec3 end3D = latLngToSphere(uEnd);

    // Interpolate points along the great-circle path
    vec3 pathPoint = greatCircleInterpolation(start3D, end3D, uProgress);

    // Project 3D sphere onto 2D screen
    float depthFactor = 0.5;
    float screenX = pathPoint.x / (1.0 - pathPoint.z * depthFactor);
    float screenY = pathPoint.y / (1.0 - pathPoint.z * depthFactor);

    vec2 projectedUV = vec2(screenX, screenY) * uScale + vec2(0.5, 0.5);

    // Sample texture
    vec4 color = texture2D(uTexture, projectedUV);
    
    // Draw animated line effect
    float distance = length(projectedUV - uv);
    if (distance < 0.005) {
        color = mix(color, vec4(1.0, 0.0, 0.0, 1.0), 0.8); // Red line
    }

    gl_FragColor = color;
}
