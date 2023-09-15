#version 300 es

// This is a fragment shader. If you've opened this file first, please
// open and read lambert.vert.glsl before reading on.
// Unlike the vertex shader, the fragment shader actually does compute
// the shading of geometry. For every pixel in your program's output
// screen, the fragment shader is run for every bit of geometry that
// particular pixel overlaps. By implicitly interpolating the position
// data passed into the fragment shader by the vertex shader, the fragment shader
// can compute what color to apply to its pixel based on things like vertex
// position, light position, and vertex color.
precision highp float;

uniform vec4 u_Color; // The color with which to render this instance of geometry.

uniform vec4 u_SecondaryColor;

uniform float u_Time;

uniform mat4 u_Model; 

uniform float u_Pixellation; 

uniform float u_ShapeType;

// These are the interpolated values out of the rasterizer, so you can't know
// their specific values without knowing the vertices that contributed to them
in vec4 fs_Pos;
in vec4 fs_Nor;
in vec4 fs_LightVec;
in vec4 fs_Col;

out vec4 out_Col; // This is the final output color that you will see on your
                  // screen for the pixel that is currently being processed.


vec2 random2(vec2 p) {
    return fract(sin(
                     vec2(dot(p, vec2(127.1, 311.7)),
                          dot(p, vec2(269.5, 183.3)))
                     )* 43758.5453);
}


vec3 random3(vec3 p) {
    return fract(sin(vec3(dot(p, vec3(127.1, 311.7, 1)),
                                    dot(p, vec3(269.5, 183.3, 1)),
                                    dot(p, vec3(420.6, 631.2, 1)))
                                    ) * 43758.5453);
}


float noise3D(vec3 p) {
    vec3 noise = sin(vec3(p.x * 127.1f, p.y * 269.5f, p.z * 631.2f));
    noise = noise * 43758.5453f;
    noise = fract(noise);
    return length(noise);
}

float noise2D(vec2 p) {
    vec2 noise = sin(vec2(p.x * 127.1f, p.y * 269.5f));
    noise = noise * 43758.5453f;
    noise = fract(noise);
    return length(noise);
}


float interpNoise2D(float x, float y) {
    int intX = int(floor(x));
    float fractX = fract(x);
    int intY = int(floor(y));
    float fractY = fract(y);

    float v1 = noise2D(vec2(intX, intY));
    float v2 = noise2D(vec2(intX + 1, intY));
    float v3 = noise2D(vec2(intX, intY + 1));
    float v4 = noise2D(vec2(intX + 1, intY + 1));

    float i1 = mix(v1, v2, fractX);
    float i2 = mix(v3, v4, fractX);
    return mix(i1, i2, fractY);
}

float interpNoise3D(float x,float y, float z) {

    int intX = int(floor(x));
    float fractX = fract(x);
    int intY = int(floor(y));
    float fractY = fract(y);
    int intZ = int(floor(z));
    float fractZ = fract(z);

    float v1 = noise3D(vec3(intX, intY, intZ));
    float v2 = noise3D(vec3(intX + 1, intY, intZ));
    float v3 = noise3D(vec3(intX, intY + 1, intZ));
    float v4 = noise3D(vec3(intX + 1, intY + 1, intZ));

    float v5 = noise3D(vec3(intX, intY, intZ + 1));
    float v6 = noise3D(vec3(intX + 1, intY, intZ + 1));
    float v7 = noise3D(vec3(intX, intY + 1, intZ + 1));
    float v8 = noise3D(vec3(intX + 1, intY + 1, intZ + 1));

    float i1 = mix(v1, v2, fractX);
    float i2 = mix(v3, v4, fractX);
    float i3 = mix(v5, v6, fractX);
    float i4 = mix(v7, v8, fractX);

    float zi1 = mix(i1, i3, fractZ);
    float zi2 = mix(i2, i4, fractZ);

    return mix(zi1, zi2, fractY);
}



float fbm(vec3 v) {
    float total = 0.0f;
    float persistence = 1.1f;
    int octaves = 15;
    float freq = 0.8f;
    float amp = 0.5f;

    for(int i = 1; i <= octaves; i++) {
        total += interpNoise3D(v.x * freq,
                               v.y * freq,
                               v.z * freq) * amp;
        freq = freq * 1.2f;
        amp = amp * persistence;
    }
    return total;
}


float WorleyNoise(vec3 uv, float t) {
    uv = 0.01f *u_Time + 2.f * uv + t * fbm(0.01f * uv) * 0.01 * (sin(1000.f * t) + cos(5000.f * 2.f * t + 0.5)); // Now the space is 10x10 instead of 1x1. Change this to any number you want.
    vec3 uvInt = floor(uv);
    vec3 uvFract = fract(uv);
    float minDist1 = 1.0f; // Minimum distance initialized to max.
    float minDist2 = 1.0f; 
    for(int y = -1; y <= 1; ++y) {
        for(int x = -1; x <= 1; ++x) {
            for(int z = -1; z <= 1; ++z) {
                vec3 neighbor = vec3(float(x), float(y), float(z)); // Direction in which neighbor cell lies
                vec3 point = random3(uvInt + neighbor); // Get the Voronoi centerpoint for the neighboring cell
                vec3 diff = neighbor + point - uvFract; // Distance between fragment coord and neighbor’s Voronoi point
                float dist = length(diff);
                if(dist < minDist2) {
                    if(dist < minDist1) {
                        minDist1 = dist;
                    } else {
                        minDist2 = dist; 
                    }
                }
            }      
        }
    }

    minDist1 += (smoothstep(0.f, 1.f, minDist1 - minDist2));

    return minDist1; 
}

vec3 coordsOnSphere() {
    vec4 worldOrigin = u_Model * vec4(0., 0., 0., 1.);
    float sphereRad = 3.0f;
    vec4 distFromOrigin = fs_Pos - worldOrigin;
    return vec3(sphereRad * normalize(distFromOrigin));
}



vec4 getVertexWiggleOscilation(vec4 positionOnModel, float time) {
    return 100.f * (positionOnModel * 0.07 * length(positionOnModel.xyz * 0.2 * time)) + 0.5f;
}


void main()
{
    // Material base color (before shading)
    vec4 diffuseColor = u_Color;

    //Time scalar (matches the growth scalar)
    float t = ((sin((u_Time - 1.f * 3.14f/5.f) * 0.03) + 1.0f)/2.0f);

    // Clamps location if it's pixellated 
    vec4 pos = fs_Pos;  
    float pixel = u_Pixellation;    
    if(u_ShapeType == 2.f) { //Remove pixel effect for sphere (it looks weird)
        pixel = 128.f;    
    }
    float x = floor(pos.x * pixel)/pixel;
    float y = floor(pos.y * pixel)/pixel;
    float z = floor(pos.z * pixel)/pixel;
        
    //First pass big waves
    vec4 highlightColor = u_SecondaryColor *  WorleyNoise(vec3(x, y, z), t);
    
    // Glow more when object contracts
    highlightColor *= 0.5f * length(getVertexWiggleOscilation(pos, t));
    
    //Additional flicker effect
    highlightColor.xyz += 0.1 * random3(vec3(0.2 * t)) * t; 
    diffuseColor.xyz += highlightColor.xyz;
        

    // Calculate the diffuse term for Lambert shading
    float diffuseTerm = dot(normalize(fs_Nor), normalize(fs_LightVec));
    // Avoid negative lighting values
    diffuseTerm = clamp(diffuseTerm, 0.f, 1.f);

    float ambientTerm = 0.3f;

    float lightIntensity = diffuseTerm + ambientTerm;   //Add a small float value to the color multiplier
                                                            //to simulate ambient lighting. This ensures that faces that are not
                                                            //lit by our point light are not completely black.

    // Compute final shaded color    
    out_Col = vec4(diffuseColor.rgb * lightIntensity, diffuseColor.a);
        
}
