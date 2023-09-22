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

uniform float u_Intensity;

uniform vec4 u_CameraPos;

uniform float u_Anger;

uniform vec4 u_WorldOrigin;

in vec4 vs_Pos;             // The array of vertex positions passed to the shader

in vec4 vs_Nor;             // The array of vertex normals passed to the shader

in vec4 vs_Col;             // The array of vertex colors passed to the shader.

out vec4 fs_LightVec;       // The direction in which our virtual light lies, relative to each vertex. This is implicitly passed to the fragment shader.

out vec4 fs_Nor;            // The array of normals that has been transformed by u_ModelInvTr. This is implicitly passed to the fragment shader.
out vec4 fs_Col;            // The color of each vertex. This is implicitly passed to the fragment shader.
out vec4 fs_Pos; 

out float fs_isEye;         //Tells thef fragment shader when to color the eye or mouth
out float fs_isMouth;


const vec4 lightPos = vec4(0, 0, 0, 1); //The position of our virtual light, which is used to compute the shading of
                                        //the geometry in the fragment shader.

// Toolbox & random functions

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

float triangle_wave(float x, float freq, float amplitude, float vShift) {
    return amplitude * abs(fract(x * freq) - 0.5f) + vShift; 
}

//Noise functions

float fbm(vec3 x) {
    x *= 5.f;
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

float mouthFbm(vec3 x) {
    x *= 2.f;
    x += 0.005 * u_Time;
	float v = 0.0;
	float a = 0.25;
	vec3 shift = vec3(100);
	for (int i = 0; i < 10; ++i) {
		v += a * noise3D(x);
		x = x * 2.0 + shift;
		a *= 0.3;
	}
	return v;
}

float gentleWorley(vec3 uv, float t, float numCells) {
    uv = 0.02f * t + numCells * uv; // Now the space is 10x10 instead of 1x1. Change this to any number you want.
    vec3 uvInt = floor(uv);
    vec3 uvFract = fract(uv);
    float minDist1 = 1.0f; // Minimum distance initialized to max.
    for(int y = -1; y <= 1; ++y) {
        for(int x = -1; x <= 1; ++x) {
            for(int z = -1; z <= 1; ++z) {
                vec3 neighbor = vec3(float(x), float(y), float(z)); // Direction in which neighbor cell lies
                vec3 point = random3(uvInt + neighbor); // Get the Voronoi centerpoint for the neighboring cell
                vec3 diff = neighbor + point - uvFract; // Distance between fragment coord and neighbor’s Voronoi point
                float dist = length(diff);
                if(dist < minDist1) {
                        minDist1 = dist;
                }
            }      
        }
    }

    return minDist1; 
}


//Offset of the flames at the top
vec4 flameYOffset(vec4 modelOffset){
    //Time cycle for growing object
    float flameT = u_Time * 0.05;
    float intensity = mix(0., -0.5, 10.f * u_Intensity);

    float vertOffset = gentleWorley(modelOffset.xyz, flameT, 2.f);
    modelOffset.y =  modelOffset.y + vertOffset * intensity;

    modelOffset.y -= 0.8; 
    
    return modelOffset;
   
}

//Calcifer grow function
vec4 getTargetGrowLocation(vec4 positionOnModel) {
    vec4 worldOrigin = u_Model * vec4(0., 0., 0., 1.);
    float sphereRad = 1.0f;
    vec4 distFromOrigin = positionOnModel - worldOrigin;
    return vec4(sphereRad * normalize(distFromOrigin));
}


//Overall flame displacement, includes growing and top flames
vec4 displaceFlame(vec4 modelposition) {
        vec4 worldOrigin = u_Model * u_WorldOrigin;

        //Adding a flame offset around the top of the fire
        float angleFromXZ = dot(vs_Pos - vec4(0.f, 0.f, 0.f, 0.f), vec4(0.f, 1.f, 0.f, 0.f));
        if (angleFromXZ > 0.f) {
            vec4 flameYOffset = flameYOffset(modelposition);
            modelposition = mix(modelposition, flameYOffset, angleFromXZ);
        }

        //Extra worley displacement around surface 
        modelposition.xz += 0.2 * gentleWorley(modelposition.xyz +  fbm(modelposition.xyz), -0.3 * u_Time, 2.f);
        
        //FBM-based perturbation
        modelposition.xz += 0.3f * modelposition.y * fbm(modelposition.xyz - 0.01f * u_Time);
        
        // Displacing the arms 
        vec4 rightArm = vec4(-0.57f, -0.59f, 0.57f, 1.f); //Location of the arms' centerpoint
        vec4 leftArm = vec4(0.57f, -0.59f, 0.57f, 1.f);
        float armWdth = 0.2f; //Desired width of the arms
        
        float len1 = length(vs_Pos - rightArm); //Distance from the arm's centerpoint
        float len2 = length(vs_Pos - leftArm); 

        if(len1 < armWdth || len2 < armWdth) {
            len1 = smoothstep(0.f, 1.f, len1);
            len2 = smoothstep(0.f, 1.f, len2);
            rightArm = modelposition + (armWdth - len1) * 2.f * (rightArm - worldOrigin);
            leftArm = modelposition + (armWdth - len2) * 2.f * (leftArm - worldOrigin);
            modelposition = mix(rightArm, modelposition, len1);
            modelposition = mix(leftArm, modelposition, len2);
        } else { // Otherwise displacing the overall flame 
            modelposition.x += (0.07f * sin(8.f * (-0.008f * u_Time + modelposition.y)));
        }

        //Mild grow cycle
        modelposition+= (0.05 * sin(0.01 * u_Time)) * getTargetGrowLocation(modelposition);

    return modelposition;
}


    // Functions to tell how far a vertex is from a desired eye or mouth
    float leftEye(vec4 modelposition) { return pow(8.1f * modelposition.x + 2.5f, 2.f) + pow(8.1f * (modelposition.y + 0.1f), 2.f) + pow(2.5f * (modelposition.z - 1.1f), 2.f); } 

    float rightEye(vec4 modelposition) { return pow(8.1f * modelposition.x - 3.6f, 2.f) + pow(8.1f * (modelposition.y + 0.07f), 2.f) + pow(2.5f * (modelposition.z - 1.1f), 2.f); } 

    float rightEyelid(vec4 modelposition, float blinkTime) { return pow(3.5f * blinkTime *  (modelposition.x - 0.35f), 2.f) + pow(8.1f * blinkTime * (modelposition.y - u_Anger - 0.03f), 2.f) + pow(2.5f * (modelposition.z - 1.1f), 2.f);}

    float leftEyelid(vec4 modelposition, float blinkTime) { return pow(3.5f * blinkTime * (modelposition.x + 0.2f), 2.f) + pow(8.1f * blinkTime * (modelposition.y - (u_Anger - 0.01f)), 2.f) + pow(2.5f * (modelposition.z - 1.1f), 2.f); }

    float mouth(vec4 modelposition) { 
        float perturbed = mouthFbm(modelposition.xyz);
        float perturbedX = perturbed + modelposition.x;
        float perturbedY = perturbed;
        vec4 perturbedModel = modelposition;
        
        float xMultiplier = 13.f * u_Anger;
        float xShift = -0.1f;

        float yMultiplier = 16.f;
        float yShift = 0.3f + 0.8 * perturbedY * u_Anger;

        float zMultiplier = 1.f;
        float zShift = -1.2f;
        
        return pow(xMultiplier * (perturbedModel.x + xShift), 2.f) + pow(yMultiplier * (perturbedModel.y + yShift), 2.f) + pow(zMultiplier * perturbedModel.z + zShift, 2.f);

        }

    float lowermouth(vec4 modelposition) { 
        float anger = mix(0., 0.06, 10. * (-u_Anger + 0.35));
        return pow(13.f *  u_Anger * (modelposition.x - 0.1f), 2.f) + pow(16.f * (modelposition.y + 0.48f - anger), 2.f) + pow(modelposition.z - 1.2, 2.f);
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

    
    vec4 modelposition = u_Model * vs_Pos + vec4(u_WorldOrigin.xyz, 0.f);   // Temporarily store the transformed vertex positions for use below
    
    //Displace the flame before making the eyes or mouth
    modelposition = displaceFlame(modelposition);
    

    //Check if the model intersects the eye or mouth
    fs_isEye = 0.f;
    fs_isMouth = 0.f; 
    float blinkTime = triangle_wave(pow(sin(0.02 * u_Time), 4.f), 1., 1., 0.05 + 0.1 * u_Anger);
    float leftEye = leftEye(modelposition);
    float rightEye = rightEye(modelposition);
    float leftEyelid = leftEyelid(modelposition, blinkTime);
    float rightEyelid = rightEyelid(modelposition, blinkTime);
    float mouth = mouth(modelposition);
    float lowermouth = lowermouth(modelposition);
    
    if((leftEye < 1.f || rightEye < 1.f) && (leftEyelid >= 1.f && rightEyelid >=1.f)) {
        modelposition += vec4(0.f, 0.f, 0.02f, 0.f);
        fs_isEye = 1.f;
    } else if(mouth < 1.f && lowermouth >= 1.f) {
            float distanceFromNeutral = modelposition.y - 3.f;
            if(distanceFromNeutral < 0.f) {
                distanceFromNeutral = 0.1 * distanceFromNeutral * distanceFromNeutral;
            }
            modelposition -= vec4(0.f, -0.05f * distanceFromNeutral, 0.05f, 0.f);
            fs_isMouth = 1.f;
    } 

    modelposition.y += 0.3 * sin(0.01 * u_Time); //Floating up and down displacement

    fs_LightVec =  u_CameraPos - modelposition;  // Compute the direction in which the light source lies

    gl_Position = u_ViewProj * modelposition;// gl_Position is a built-in variable of OpenGL which is
                                             // used to render the final positions of the geometry's vertices

    fs_Pos = modelposition;
}
