#version 300 es

//This is a vertex shader. While it is called a "shader" due to outdated conventions, this file
//is used to apply matrix transformations to the arrays of vertex data passed to it.
//Since this code is run on your GPU, each vertex is transformed simultaneously.
//If it were run on your CPU, each vertex would have to be processed in a FOR loop, one at a time.
//This simultaneous transformation allows your program to run much faster, especially when rendering
//geometry with millions of vertices.

uniform mat4 u_Model;       // The matrix that defines the transformation of the
                            // object we're rendering. In this assignment,
                            // this will be the result of traversing your scene graph.

uniform mat4 u_ModelInvTr;  // The inverse transpose of the model matrix.
                            // This allows us to transform the object's normals properly
                            // if the object has been non-uniformly scaled.

uniform mat4 u_ViewProj;    // The matrix that defines the camera's transformation.
                            // We've written a static matrix for you to use for HW2,
                            // but in HW3 you'll have to generate one yourself

uniform float u_Time;

uniform float u_ShapeType;

in vec4 vs_Pos;             // The array of vertex positions passed to the shader

in vec4 vs_Nor;             // The array of vertex normals passed to the shader

in vec4 vs_Col;             // The array of vertex colors passed to the shader.

out vec4 fs_Nor;            // The array of normals that has been transformed by u_ModelInvTr. This is implicitly passed to the fragment shader.
out vec4 fs_LightVec;       // The direction in which our virtual light lies, relative to each vertex. This is implicitly passed to the fragment shader.
out vec4 fs_Col;            // The color of each vertex. This is implicitly passed to the fragment shader.
out vec4 fs_Pos; 

const vec4 lightPos = vec4(5, 5, 3, 1); //The position of our virtual light, which is used to compute the shading of
                                        //the geometry in the fragment shader.


vec4 getTargetGrowLocation(vec4 positionOnModel) {
    vec4 worldOrigin = u_Model * vec4(0., 0., 0., 1.);
    float sphereRad = 1.0f;
    vec4 distFromOrigin = positionOnModel - worldOrigin;
    return vec4(sphereRad * normalize(distFromOrigin));
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

vec4 getVertexWiggleOscilation(vec4 positionOnModel, float time) {
    return 2.f * sin(positionOnModel * 0.07 * length(random3(positionOnModel.xyz * 0.2) * time));
}


void main()
{
    fs_Col = vs_Col;                         // Pass the vertex colors to the fragment shader for interpolation

    mat3 invTranspose = mat3(u_ModelInvTr);
    fs_Nor = vec4(invTranspose * vec3(vs_Nor), 0);          // Pass the vertex normals to the fragment shader for interpolation.
                                                            // Transform the geometry's normals by the inverse transpose of the
                                                            // model matrix. This is necessary to ensure the normals remain
                                                            // perpendicular to the surface after the surface is transformed by
                                                            // the model matrix.

    
    vec4 modelposition = u_Model * vs_Pos;   // Temporarily store the transformed vertex positions for use below

    //Projecting out where to scale the object
    vec4 targetGrowLoc = getTargetGrowLocation(modelposition);
    
    //Time cycle for growing object
    float growT = 0.3 * (sin(u_Time * 0.03) + 1.0f)/2.0f;
 
    //Turning on bubbly effect for icosphere
    if(u_ShapeType == 2.f) {
        float vertOffset =  WorleyNoise(modelposition.xyz, growT);
        modelposition.xyz =  modelposition.xyz - 0.2 * vertOffset;
    }

    // Grow logic
    modelposition.xyz = mix(modelposition.xyz, targetGrowLoc.xyz, 0.9f * growT);

    //Vibrating effect
    float pulseT = 0.3 * ((sin((u_Time - 1.f * 3.14f/5.f) * 0.03) + 1.0f)/2.0f);
    modelposition.xy = modelposition.xy + getVertexWiggleOscilation(modelposition, pulseT).xy;
    
    fs_LightVec = lightPos - modelposition;  // Compute the direction in which the light source lies

    gl_Position = u_ViewProj * modelposition;// gl_Position is a built-in variable of OpenGL which is
                                             // used to render the final positions of the geometry's vertices

    
    fs_Pos = modelposition;
}
