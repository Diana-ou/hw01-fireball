import {vec3, vec4} from 'gl-matrix';
import Icosphere from './geometry/Icosphere';
import Square from './geometry/Square';
//import Cube from './geometry/Cube';
import Cube from './geometry/Cube';
import OpenGLRenderer from './rendering/gl/OpenGLRenderer';
import Drawable from './rendering/gl/Drawable';
import Camera from './Camera';
import {setGL} from './globals';
import ShaderProgram, {Shader} from './rendering/gl/ShaderProgram';

let calciferBody: Icosphere;
let calciferLeftEye: Icosphere;
let square: Square;

let cube: Cube;
let prevTesselations: number = 5;

let time : number = 0; 

function loadScene() {
  calciferBody = new Icosphere(vec3.fromValues(0, 0, 0), 1, 7, vec4.fromValues(1, 0, 0, 1));
  calciferBody.create();

  calciferLeftEye = new Icosphere(vec3.fromValues(-0.4, 0, 1.0), 0.15, 7, vec4.fromValues(1, 1, 1, 1));
  calciferLeftEye.create();

  square = new Square(vec3.fromValues(0, 0, 0));
  square.create();
  cube = new Cube(vec3.fromValues(0, 0, 0));
  cube.create();
  
}

function main() {
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
    time += 1; 
    camera.update();
    gl.viewport(0, 0, window.innerWidth, window.innerHeight);
    renderer.clear();

  
      renderer.render(camera, lambert, [calciferBody], time, vec4.fromValues(1, 0, 0, 1), vec4.fromValues(0, 1, 0, 1))
    

    // Tell the browser to call `tick` again whenever it renders a new frame
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
