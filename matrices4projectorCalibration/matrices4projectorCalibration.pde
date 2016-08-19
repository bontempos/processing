/*PROJECTOR CALIBRATION BASED ON USER EVALUATION
  USAGE: upload an obj file.
         get 6 3D points coordinates from this object in a specific sequence and set it on setup()
         aim projetor to object replica (physical object must match the obj file correspondence)
         with mouse cursor, click on the 6 correspondent points you set up for 3D points.
         after projector is calibrated, points will be shown on object.
         you can draw planes or lines connecting this points.
         you can project a point in any real world point giving its 3D position to this function:
         getProjectedCoord( new PVector(X,Y,Z), matrixP);
         if you can track the points using a camera, 3D scanner, motors, you can create dynamic projection mapping.
  
  TODO: at this moment I need to draw every fragment using the new Matrix found after callibration. It is like building a new shader.
  This is stupid, since I just need to update the current processing projection matrix and use the native shader. But HOW? (see commented code below)
  
  change all PVectors types by double[][] or float[][]
  
  this version does not consider lens radial distotion <-needs implementation
  
  //Anderson Sudario 2016/08/19
  
*/

PShape objFile;

PMatrix3D p = new PMatrix3D();

void setup() {
  //size(400, 300, P3D); 
  fullScreen(P3D);
  startOpenCV();
  objFile = loadShape("box10.obj");
  //set these values before start.
  p3d[0].set(1, 1, 0);
  p3d[1].set(1, 0, 0);
  p3d[2].set(0, 1, 0);
  p3d[3].set(0, 0, 0);
  p3d[4].set(-1, 1, 0);
  p3d[5].set(-1, 0, 0);
}

void draw() {
  if (calibrationMode) {
    doCalibration();
  } else {
    if(keyPressed){
      updateP2D();
    }
    display();
  }
}

void display() {
  background(0);

  //drawing a single "fragment" mannually:
  beginShape(TRIANGLE);
  fill(#ff0000,100);
  noStroke();
  PVector point2D = getProjectedCoord(p3d[0], matrixP);
  vertex(point2D.x, point2D.y);
  point2D = getProjectedCoord(p3d[1], matrixP);
  vertex(point2D.x, point2D.y);
  point2D = getProjectedCoord(p3d[2], matrixP);
  vertex(point2D.x, point2D.y);
  endShape();
  
  displayInfo();
}

void displayInfo(){
 PVector test = new PVector();

  //this is opencv matrix result
  textSize(12);
  stroke(#00aaaa);
  fill(#00ffff);
  strokeWeight(7);
  for (int i = 0; i < 6; i++) {
    test = getProjectedCoord(p3d[i], matrixP);
    point(test.x, test.y);
    text(i+1, test.x, test.y);
  }

  //this is processing matrix result (same as above, if I divide X,Y by Z)
  stroke(#aaaa00);
  fill(#ffff00);
  strokeWeight(5);
  for (int i = 0; i < 6; i++) {
    p.mult(p3d[i], test);
    point(test.x/test.z, test.y/test.z);
    text(i+1, test.x/test.z, test.y/test.z);
  }

  //this is where mouse was clicked when calibrating.
  stroke(#00aa00);
  fill(#00ff00);
  strokeWeight(5);
  for (int i = 0; i < 6; i++) {
    point(p2dP[i].x, p2dP[i].y);
    text(i+1, p2dP[i].x, p2dP[i].y);
  }
}



/*



//https://github.com/processing/processing/blob/master/core/src/processing/opengl/PGraphicsOpenGL.java//https://github.com/processing/processing/blob/master/core/src/processing/opengl/PGraphicsOpenGL.java
//https://github.com/processing/processing/wiki/Advanced-OpenGL-in-Processing-2.x
//http://www.opengl-tutorial.org/beginners-tutorials/tutorial-3-matrices/
//import com.jogamp.opengl.GL2;  

//PGraphicsOpenGL pg = (PGraphicsOpenGL)g;
//PGL pgl = beginPGL();  
//GL2 gl2 = ((PJOGL)pgl).gl.getGL2();


//camera(170.0, 100, map(mouseX, 0, width, -2200, 2200), 150.0, 150.0, 0.0, 
  //  0.0, 1.0, 0.0);

  pg = (PGraphicsOpenGL) g;
  //PGL pgl = beginPGL(); 
  
  
  
  //public PMatrix3D projection;
  //public PMatrix3D camera;
  //public PMatrix3D cameraInv;
  //public PMatrix3D modelview;
  //public PMatrix3D modelviewInv;
  //public PMatrix3D projmodelview;

  
  pg.projection.print();
  pg.camera.print();
  pg.modelview.print();
  //endPGL(); 

  //setMatrix(p);
  //p.invert();
  PMatrix3D n = new PMatrix3D(
    (float)matrixP.get(0, 0)[0], (float)matrixP.get(0, 1)[0], (float)matrixP.get(0, 2)[0], (float)matrixP.get(0, 3)[0], 
    (float)matrixP.get(1, 0)[0], (float)matrixP.get(1, 1)[0], (float)matrixP.get(1, 2)[0], (float)matrixP.get(1, 3)[0], 
    (float)matrixP.get(2, 0)[0], (float)matrixP.get(2, 1)[0], (float)matrixP.get(2, 2)[0], (float)matrixP.get(2, 3)[0], 
    0, 0, 0, 1);
  
  
  //n.apply(pg.modelview);
  //pg.camera.set(n);
  //applyMatrix(n);
  //box(50);
  //translate(150, 150, 0);

  //box(50);
  //scale(5);
  //rotateY(PI/4);
  //shape(objFile, 0, 0);
  //map(mouseX,0,width,-200,200)
*/