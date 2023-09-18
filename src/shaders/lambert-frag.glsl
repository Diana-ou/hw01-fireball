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

uniform vec4 u_CameraPos; 

// These are the interpolated values out of the rasterizer, so you can't know
// their specific values without knowing the vertices that contributed to them
in vec4 fs_Pos;
in vec4 fs_Nor;
in vec4 fs_LightVec;
in vec4 fs_Col;
in float fs_isEye;
in float fs_isMouth;



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


float hash(float p) { p = fract(p * 0.011); p *= p + 7.5; p *= p + p; return fract(p); }

float noise3D(vec3 x) {
    const vec3 step = vec3(110, 241, 171);
    vec3 i = floor(x);
    vec3 f = fract(x);
    float n = dot(i, step);
    vec3 u = f * f * (3.0 - 2.0 * f);
    return mix(mix(mix( hash(n + dot(step, vec3(0, 0, 0))), hash(n + dot(step, vec3(1, 0, 0))), u.x),
                   mix( hash(n + dot(step, vec3(0, 1, 0))), hash(n + dot(step, vec3(1, 1, 0))), u.x), u.y),
               mix(mix( hash(n + dot(step, vec3(0, 0, 1))), hash(n + dot(step, vec3(1, 0, 1))), u.x),
                   mix( hash(n + dot(step, vec3(0, 1, 1))), hash(n + dot(step, vec3(1, 1, 1))), u.x), u.y), u.z);
}

float fbm(vec3 x) {
    x *= 10.f;
	float v = 0.0;
	float a = 0.3;
	vec3 shift = vec3(100);
	for (int i = 0; i < 10; ++i) {
		v += a * noise3D(x);
		x = x * 2.0 + shift;
		a *= 0.3;
	}
	return v;
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

vec4 worldOrigin() {
    return u_Model * vec4(0., 0., 0., 1.);
}


void main()
{
    // Material base color (before shading)
    vec4 diffuseColor = fs_Col;

    //Time scalar (matches the growth scalar)
    float t = ((sin((1.6f * u_Time - 1.f * 3.14f/5.f) * 0.03) + 1.0f)/2.0f);

    vec4 pos = fs_Pos;  
    //First pass big waves
    vec4 highlightColor = 0.3f * vec4(fs_Col.x + 0.1f, fs_Col.y + 0.5f, fs_Col.z + 0.1f, 1.f);
    
    // Glow more when object contracts
    highlightColor *= 0.5f * length(getVertexWiggleOscilation(pos, t));
    float multiplier = 1.f - 0.6f * pow(length(fs_Pos - worldOrigin() - vec4(0.f, -0.1f, 0.f, 0.f)), 2.5f);
    highlightColor += multiplier * highlightColor;
    
    //Additional flicker effect
    highlightColor.xyz += 0.1 * vec3(fbm(vec3(0.6 * t))); 
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

    if(fs_isEye > 0.5f) {
        out_Col = vec4(1.f);
        float leftPupil = pow(18.f * (fs_Pos.x + 0.25f), 2.f) + pow(16.f * (fs_Pos.y + 0.1f), 2.f) + pow(5.f * (fs_Pos.z - 1.1f), 2.f);
        float rightPupil = pow(18.f * (fs_Pos.x - 0.34f), 2.f) + pow(16.f * (fs_Pos.y + 0.07f), 2.f) + pow(5.f * (fs_Pos.z - 1.1f), 2.f);
        if(leftPupil < 1.f || rightPupil < 1.f) {
        out_Col = vec4(0.2, 0.2, 0.2, 1.f);
        }  
    } else if(fs_isMouth > 0.5f) {
             out_Col = vec4(0.2, 0.2, 0.2, 1.f);
        }

}
