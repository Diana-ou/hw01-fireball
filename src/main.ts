import {vec3, vec4} from 'gl-matrix';
import Icosphere from './geometry/Icosphere';
import * as DAT from 'dat.gui';
import OpenGLRenderer from './rendering/gl/OpenGLRenderer';
import Drawable from './rendering/gl/Drawable';
import Camera from './Camera';
import {setGL} from './globals';
import ShaderProgram, {Shader} from './rendering/gl/ShaderProgram';

let calciferBody: Icosphere;
let calciferLeftEye: Icosphere;
let time : number = 0; 

// Define an object with application parameters and button callbacks
// This will be referred to by dat.GUI's functions that add GUI elements.
const controls = {
  speed: 1, //Control for how pixellated things are
  intensity: 1, //Control for how pixellated things are
  color : [255, 0, 0, 1], // Control for base color
  'Reset to Defaults': resetToDefaults, // A function pointer, essentially

};

function loadScene() {
  calciferBody = new Icosphere(vec3.fromValues(0, 0, 0), 1, 7, vec4.fromValues(250.0/256.0, 60.0/256.0, 16.0/256.0, 1));
  calciferBody.create();
}

function resetToDefaults() {

}

function main() {
   // Add controls to the gui
    const gui = new DAT.GUI();
   gui.add(controls, 'speed', 0, 1.5).step(0.1);
   gui.add(controls, 'intensity', 0, 8).step(1);
   gui.addColor(controls, 'color');
   //gui.add(controls, 'Load Scene');

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

    calciferBody.color = vec4.fromValues(controls.color[0]/255, controls.color[1]/255, controls.color[2]/255, 1);

    renderer.clear();
      renderer.render(camera, lambert, [calciferBody], time, vec4.fromValues(1, 0, 0, 1), vec4.fromValues(0, 1, 0, 1))
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

  // Start the render loop
  tick();
}

main();
