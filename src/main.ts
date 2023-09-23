import {vec3, vec4} from 'gl-matrix';
import Icosphere from './geometry/Icosphere';
import * as DAT from 'dat.gui';
import OpenGLRenderer from './rendering/gl/OpenGLRenderer';
import Drawable from './rendering/gl/Drawable';
import Camera from './Camera';
import {setGL} from './globals';
import ShaderProgram, {Shader} from './rendering/gl/ShaderProgram';

let calciferBody: Icosphere;
let time : number = 0; 

let speedDefault : number = 1;
let intensityDefault : number = 0.3;
let angerDefault : number = 0.05;
let colorDefault : number[] =  [250.0, 60.0, 16.0, 255.0];
let frameDefault : number = 14; 

// Define an object with application parameters and button callbacks
// This will be referred to by dat.GUI's functions that add GUI elements.
const controls = {
  speed: speedDefault, //Control for how fast the time variable is
  intensity: intensityDefault, //Control for how intense things are
  anger: angerDefault, //Control for how angry your boy is!!!
  color : colorDefault, // Control for base color
  frameRate : frameDefault,
  'Reset to Defaults': resetToDefaults, // Resets controls to deefault values
};

function loadScene() {
  calciferBody = new Icosphere(vec3.fromValues(0, 0, 0), 1, 7, vec4.fromValues(250.0/256.0, 60.0/256.0, 16.0/256.0, 1));
  calciferBody.create();
}

function resetToDefaults() {
  controls.speed = speedDefault;
  controls.intensity = intensityDefault; 
  controls.anger = angerDefault;
  controls.color = colorDefault;
}

function main() {
   // Add controls to the gui
    const gui = new DAT.GUI();
   gui.add(controls, 'speed', 0.5, 1.5).step(0.1);
   gui.add(controls, 'intensity', 0.1, 0.5).step(0.01);
   gui.add(controls, 'anger', 0.05, 0.2).step(0.01);
   gui.add(controls, 'frameRate', 1, 14).step(1);
   gui.addColor(controls, 'color');
   gui.add(controls, 'Reset to Defaults');

  // get canvas and webgl context
  const canvas = <HTMLCanvasElement> document.getElementById('canvas');
  const gl = <WebGL2RenderingContext> canvas.getContext('webgl2');
  if (!gl) {
    alert('WebGL 2 not supported!');
  }
  // `setGL` is a function imported above which sets the value of `gl` in the `globals.ts` module.
  // Later, we can import `gl` from `globals.ts` to access it
  setGL(gl);

  // Initial call to load scene
  loadScene();

  const camera = new Camera(vec3.fromValues(0, 0, 5), vec3.fromValues(0, 0, 0));
  const renderer = new OpenGLRenderer(canvas);
  renderer.setClearColor(0.2, 0.2, 0.2, 1);
  gl.enable(gl.DEPTH_TEST);

  const lambert = new ShaderProgram([
    new Shader(gl.VERTEX_SHADER, require('./shaders/lambert-vert.glsl')),
    new Shader(gl.FRAGMENT_SHADER, require('./shaders/lambert-frag.glsl')),
  ]);

  // This function will be called every frame
  function tick() {
    time += 1 * controls.speed; 
    
    camera.update();
    gl.viewport(0, 0, window.innerWidth, window.innerHeight);

    //Getting colors if the value changes
    let newColor : vec4 = vec4.fromValues(controls.color[0]/255, controls.color[1]/255, controls.color[2]/255, 1);
    if(calciferBody.color[0] != newColor[0] && calciferBody.color[1] != newColor[1] && calciferBody.color[2] != newColor[2]) {
      calciferBody = new Icosphere(vec3.fromValues(0, 0, 0), 1, 7, newColor);
      calciferBody.create();
    }
    
    let worldOrigin : vec3 = vec3.fromValues(0, 0, 0);

    let num = 15 - controls.frameRate;
    let choppytime : number = num * Math.floor(time/num);
    // Render call
    renderer.clear();
      renderer.render(camera, lambert, [calciferBody], choppytime, -controls.intensity, 0.35 - controls.anger, worldOrigin);
      requestAnimationFrame(tick);
  }

  window.addEventListener('resize', function() {
    renderer.setSize(window.innerWidth, window.innerHeight);
    camera.setAspectRatio(window.innerWidth / window.innerHeight);
    camera.updateProjectionMatrix();
  }, false);

  renderer.setSize(window.innerWidth, window.innerHeight);
  camera.setAspectRatio(window.innerWidth / window.innerHeight);
  camera.updateProjectionMatrix();

  // Start the render loops
  tick();
}

main();
