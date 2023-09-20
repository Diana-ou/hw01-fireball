# HW 1: Fireball Noise Project

![](https://github.com/Diana-ou/hw00-intro-base/blob/master/Demo.gif)

[Live Demo Link] (https://diana-ou.github.io/hw01-fireball/)

## Objective
- Implementing different noise and blending functions
- Thinking of more creative mesh deformations 
- (Personal) recreate a cute character I enjoy

## Inspiration
Since the project guidelines was to make a fireball, I decided to make my favorite ball of fire: Calcifer, from Howl's Moving Castle!

## The tools 
On the site, you will have customization with the following controls: 
* Speed: Multiplier for time; modifies all time-reliant functions.
* Intensity: The strength of the flame; Calcifer will be a blue lump when intensity is low, and lively when intensity is high!
* Anger: Makes calcifer's expression angry! What did you do to him??
* Color: Calcifer's base color!

## Implementation details

Noise functions:
* Used worley noise as the backing lava cell shaping & protrusions
* FBM-based perturbation near the top of the flame
* FBM-based flicker

Toolbox functions: 
* Triangle wave for the base of Calcifer's blinking loop
* Squaring to make Calcifer's blinking loop easen in
* Use of smoothstep and mix functions to blend the seam transition from top of flame to bottom of flame.
* Simple sine-based grow/shrinking + in-sync glow

## More Images
![Image](https://github.com/Diana-ou/hw00-intro-base/blob/master/Cube.png)
![Image](https://github.com/Diana-ou/hw00-intro-base/blob/master/Sphere.png)
