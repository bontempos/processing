// Thomas Sanchez Lengeling
// openGL Point Cloud Example.

// https://github.com/shiffman/OpenKinect-for-Processing
// http://shiffman.net/p5/kinect/

// modified to work with processing website's official library version
// got information from https://gist.github.com/JakubValtar/b194e42dfa079a75649c
// Anderson Sudario 2016/Jul/19

import java.nio.*;
import org.openkinect.freenect.*;
import org.openkinect.processing.*;

// Kinect Library object
Kinect kinect;

// Angle for rotation
float a = PI;

//openGL
PGL pgl;
PShader sh;

int  vertLoc;
int  vertLocId;
//int  colorLoc;

void setup() {
  // Rendering in P3D
  size(800, 600, P3D);
  kinect = new Kinect(this);
  kinect.enableMirror(true); //added
  kinect.initDepth();
  
  //load shaders
  sh = loadShader("frag.glsl", "vert.glsl");
  PGL pgl = beginPGL();

  IntBuffer intBuffer = IntBuffer.allocate(1);
  pgl.genBuffers(1, intBuffer);

  //memory location of the VBO
  vertLocId = intBuffer.get(0);

  endPGL();
}

void draw() {

  background(0);
  
  image(kinect.getDepthImage(), 0, 0, 320, 240); //why this is not mirrored nobody knows

  pushMatrix();
  translate(width/2, height/2, 600);
  scale(150);
  rotateY(a);
  
  
  int vertData = kinect.width * kinect.height;
   
  FloatBuffer depthPositions =  kinect.getDephToWorldPositions();

  pgl = beginPGL();
  sh.bind();
  
  vertLoc  = pgl.getAttribLocation(sh.glProgram, "vertex");
  
  //color for ALL POINTS of the point cloud
  sh.set("fragColor", 1.0f, 1.0f, 1.0f, 1.0f);

  pgl.enableVertexAttribArray(vertLoc);

  pgl.bindBuffer(PGL.ARRAY_BUFFER, vertLocId);
  pgl.bufferData(PGL.ARRAY_BUFFER, Float.BYTES * vertData *3, depthPositions, PGL.DYNAMIC_DRAW);
  pgl.vertexAttribPointer(vertLoc, 3, PGL.FLOAT, false, Float.BYTES * 3, 0);

  pgl.bindBuffer(PGL.ARRAY_BUFFER, 0);

  //draw the XYZ depth camera points
  pgl.drawArrays(PGL.POINTS, 0, vertData);

  //clean up the vertex buffers
  pgl.disableVertexAttribArray(vertLoc);

  sh.unbind();
  endPGL();

  popMatrix();
  
  fill(255, 0, 0);
  text(frameRate, 50, 50);

  // Rotate
  // a += 0.015f;
}