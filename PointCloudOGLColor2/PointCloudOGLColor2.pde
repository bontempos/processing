// Based on PointCloudOGL example
// Added color per vertex based on RGB video pixels
// Anderson Sudario 2016/Jul/19
/*

#ifdef GL_ES
precision mediump float;
precision mediump int;
#endif

varying vec4 vertColor;

//input color
//uniform vec4 fragColor;

void main() {

  //outputColor
  gl_FragColor = vertColor; //changed
}
*/

import java.nio.*;
import com.jogamp.common.nio.Buffers;
import org.openkinect.freenect.*;
import org.openkinect.processing.*;

// Kinect Library object
Kinect kinect;

// Angle for rotation
float a = PI;

//openGL
PGL pgl;
PShader sh;

//vertex
int  vertLoc;
int  vertLocId;
//colors
int  colorLoc;
int  colorLocId;
float []colors = new float[640 * 480 * 4]; 

void setup() {
  // Rendering in P3D
  size(800, 600, P3D);
  kinect = new Kinect(this);
  kinect.initDepth();
  kinect.initVideo();
  kinect.enableMirror(true); 

  //load shaders
  sh = loadShader("frag.glsl", "vert.glsl"); //only one change in frag.glsl
  PGL pgl = beginPGL();

  IntBuffer intBuffer = IntBuffer.allocate(2);
  pgl.genBuffers(2, intBuffer);

  //memory location of the VBO
  vertLocId = intBuffer.get(0);
  colorLocId = intBuffer.get(1);
  endPGL();
}


void buildColors() {
  int textureOffsetY = kinect.width* 35 ; //int(map(mouseY, 0, height, 0, 100));//kinect.width * 100;
  //println(int(map(mouseY, 0, height, 0, 100)));
  for (int i = 0; i < kinect.width*kinect.height - textureOffsetY; i+=1) { //skip if wanted

    color c = kinect.getVideoImage().pixels[i+textureOffsetY];
    //float[] f = RGBAToOpenGL( 255, 255, 255, 255);
    colors[i*4]     = (c >> 16 & 0xff) /100f; 
    colors[i*4 + 1] = (c >> 8 & 0xff) /100f;
    colors[i*4 + 2] = (c >> 0 & 0xff) /100f;
    colors[i*4 + 3] = 1;
  }
}


void draw() {

  background(0);

  //image(kinect.getDepthImage(), 0, 0, 320, 240); 
  pushMatrix();
  translate(width/2, height/2, 600);
  scale(150);
  rotateY(a);


  int vertData = kinect.width * kinect.height;
  FloatBuffer depthPositions =  kinect.getDephToWorldPositions();

  buildColors();
  FloatBuffer colorBuffer = Buffers.newDirectFloatBuffer(640 * 480 * 4); //allocateDirectFloatBuffer(640 * 480 * 4);
  colorBuffer.put(colors, 0, 640 * 480 * 4);
  colorBuffer.rewind();

  pgl = beginPGL();
  sh.bind();

  vertLoc  = pgl.getAttribLocation(sh.glProgram, "vertex");
  colorLoc  = pgl.getAttribLocation(sh.glProgram, "color");

  pgl.enableVertexAttribArray(vertLoc);
  pgl.enableVertexAttribArray(colorLoc);

  pgl.bindBuffer(PGL.ARRAY_BUFFER, vertLocId);
  pgl.bufferData(PGL.ARRAY_BUFFER, Float.BYTES * vertData *3, depthPositions, PGL.DYNAMIC_DRAW);
  pgl.vertexAttribPointer(vertLoc, 3, PGL.FLOAT, false, Float.BYTES * 3, 0);

  final int colorStride  =  4 * Float.BYTES;
  final int colorOffset  =  0 * Float.BYTES;

  pgl.bindBuffer(PGL.ARRAY_BUFFER, colorLocId);
  pgl.bufferData(PGL.ARRAY_BUFFER, Float.BYTES * colors.length, colorBuffer, PGL.DYNAMIC_DRAW);
  pgl.vertexAttribPointer(colorLoc, 4, PGL.FLOAT, false, colorStride, colorOffset);

  pgl.bindBuffer(PGL.ARRAY_BUFFER, 0);

  //draw the XYZ depth camera points
  pgl.drawArrays(PGL.POINTS, 0, vertData);

  //clean up the vertex buffers
  pgl.disableVertexAttribArray(vertLoc);
  pgl.disableVertexAttribArray(colorLoc);

  sh.unbind();
  endPGL();

  popMatrix();

  fill(255, 0, 0);
  text(frameRate, 50, 50);

  // Rotate
  a += sin(millis()/1000.0) / 500.0;
}

FloatBuffer allocateDirectFloatBuffer(int n) {
  return ByteBuffer.allocateDirect(n * Float.BYTES).order(ByteOrder.nativeOrder()).asFloatBuffer();
}

//float[] RGBAToOpenGL(int r1, int g1, int b1, int a1) {
//  float[] tmp = new float[4];
//  tmp[0] = r1/255f;
//  tmp[1] = g1/255f;
//  tmp[2] = b1/255f;
//  tmp[3] = a1/255f;
//  return tmp;
//}