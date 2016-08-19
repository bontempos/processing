//This tab is for opencv and matrix operations

import gab.opencv.*;
import org.opencv.core.Mat;
import org.opencv.core.CvType;
import org.opencv.core.Core;
OpenCV opencv;
Mat matrixA, matrixR;
Mat matrixP = null;
boolean calibrationMode = true;
boolean printMatrices = true;
//PVector projectorCenter = new PVector(); 
int detectedPoint;
int maxCpoints = 6;
PVector [] p3d = new PVector[maxCpoints]; //known 3D points
PVector [] p2dP = new PVector[maxCpoints];//manually selected 3D correspondences by projector plane
//PVector [] p2dC = new PVector[maxCpoints];//manually selected 3D correspondences by camera plane (not used)
boolean[] updatingP2D = new boolean[maxCpoints]; // correct p2d position (hold keys 1 to 6 and move mouse to update)


void startOpenCV() {
  opencv = new OpenCV(this, width, height);
  for (int i = 0; i < maxCpoints; i++) {
    p3d[i] = new PVector();
  }
}


void buildProjecionMatrix() {
  matrixA = makeMatrixA(p2dP);
  matrixR = makeMatrixR(p2dP);
  matrixP = makeProjectionMatrix(matrixA, matrixR);
}


Mat makeMatrixA(PVector [] p2d) {
  //this will make the matrix A based on the co-related points btw space and projector
  double[] tmpAc = new double[maxCpoints * 11 * 2]; 
  int j = 0;
  for (int i = 0; i < maxCpoints; i++) {
    float X, Y, Z, u, v;
    println("p3d["+i+"]: ", p3d[i]);
    X = p3d[i].x;
    Y = p3d[i].y;
    Z = p3d[i].z;
    u = p2d[i].x;
    v = p2d[i].y;
    //inserting vars for Projector u
    double[] Cu = {X, Y, Z, 1, 0, 0, 0, 0, -X*u, -Y*u, -Z*u};
    for (int k = 0; k < Cu.length; k++) {
      tmpAc[j] = Cu[k];
      j++;
    }
    //inserting vars for Projector v
    double[] Cv = { 0, 0, 0, 0, X, Y, Z, 1, -X*v, -Y*v, -Z*v};
    for (int k = 0; k < Cv.length; k++) { 
      tmpAc[j] = Cv[k];
      j++;
    }
  }
  //formating result maxCpoints*2 rows 11 cols
  int row = 0, col = 0;
  Mat m = new Mat(maxCpoints*2, 11, CvType.CV_64F);
  m.put( row, col, tmpAc );
  j=0;
  if (printMatrices) {
    println("----------------------RESULT MATRIX matrixA--------------------");
    for (int i = 0; i < maxCpoints*2; i++) { //rows
      for (int q = 0; q < 11; q ++) { //colums
        double[] t =  m.get(i, q) ;
        float []tt = {(float)t[0]};
        print( tt[0] + " | "  );
      }
      println("");
    }
  }
  return m;
}

Mat makeMatrixR(PVector [] p2d) {
  int j = 0;
  double [] tmp = new double[maxCpoints*2]; //this is  u and v from projector

  for (int i = 0; i < maxCpoints; i++) {
    tmp[j] =  p2d[i].x;
    j++;
    tmp[j] =  p2d[i].y;
    j++;
  }
  Mat m = new Mat(maxCpoints*2, 1, CvType.CV_64F);
  m.put( 0, 0, tmp );
  if (printMatrices) {
    println("----------------------RESULT MATRIX matrixR--------------------");
    for (int i = 0; i < maxCpoints*2; i++) { //rows
      double[] t =  m.get(i, 0);
      float []tt = {(float)t[0]};
      println( tt[0] );
    }
  }
  return m;
}


Mat makeProjectionMatrix(Mat ac, Mat rc) {
  Mat m = new Mat();
  //below is this equation P = ( A transpose * A ).inv() * ( A transpose * R ):
  Mat tmp1 = new Mat(); 
  Mat tmp2 = new Mat(); 
  Core.gemm(ac.t(), ac, 1, new Mat(), 0, tmp1); //Ac transp * A  , result in tmp1
  Core.gemm(ac.t(), rc, 1, new Mat(), 0, tmp2); //Ac transp * Rc  , result in tmp2
  Core.gemm(tmp1.inv(1), tmp2, 1, new Mat(), 0, m); //tmp1 inv * tmp2, result in C;

  //adding value to equalize row and column then reshape
  Mat z = new Mat(1, 1, CvType.CV_64F); //creates a 1x1 matrix
  z.put(0, 0, 1); //inserts the value "1" at position (0,0) of matrix z.
  m.push_back(z); //inserts z in last position in C
  m = m.reshape(1, 3); //reshape(int channel, int rows)

  if (printMatrices) {
    println("----------------------RESULT PROJECTION MATRIX --------------------");
    for (int i = 0; i < 3; i++) {
      for (int j = 0; j < 4; j ++) {
        double[] t =  m.get(i, j) ;
        float []tt = {(float)t[0]};
        print("C"+(i+1)+""+(j+1)+":"+ tt[0] +"    " );
      }
      println("");
    }
  }
  return m;
}



PVector getProjectedCoord(PVector s, Mat projMatrix) {
  //returns a 2D PVector based on a givel 3D PVector point
  double [] tmp = new double[4]; //X,Y,Z,1
  tmp[0] =  s.x;
  tmp[1] =  s.y;
  tmp[2] =  s.z;
  tmp[3] =  1;

  Mat m = new Mat(4, 1, CvType.CV_64F);
  m.put( 0, 0, tmp );

  Mat tmp1 = new Mat(); 
  PVector p = new PVector();
  Core.gemm(projMatrix, m, 1, new Mat(), 0, tmp1);

  double []xd = tmp1.get(0, 0) ;
  double []yd = tmp1.get(1, 0) ;
  double []zd = tmp1.get(2, 0) ;

  p.x = (float)xd[0] / (float)zd[0]; 
  p.y = (float)yd[0] / (float)zd[0]; 
  return p;
}


//MATRIX ROTATION
PVector rot(PVector v1, PVector v2, float angle) {
  //v1 vector to rotate
  //v2 mask ex:(0,0,1)  or  (1,0,0)...
  //angle to rotate
  float a = radians(angle);
  PVector result = new PVector(0, 0, 0);

  if (v2.x == 1 && v2.y == 0 && v2.z == 0) {
    PVector [] rx = {
      new PVector(1, 0, 0), 
      new PVector(0, cos(a), -sin(a)), 
      new PVector(0, sin(a), cos(a))
    };
    result.x = v1.dot(rx[0]);
    result.y = v1.dot(rx[1]);
    result.z = v1.dot(rx[2]);
  } else if (v2.x == 0 && v2.y == 1 && v2.z == 0) {
    PVector [] ry = {
      new PVector(cos(a), 0, sin(a)), 
      new PVector(0, 1, 0), 
      new PVector(-sin(a), 0, cos(a))
    };
    result.x = v1.dot(ry[0]);
    result.y = v1.dot(ry[1]);
    result.z = v1.dot(ry[2]);
  } else if (v2.x == 0 && v2.y == 0 && v2.z == 1) {
    PVector [] rz = {
      new PVector(cos(a), -sin(a), 0), 
      new PVector(sin(a), cos(a), 0), 
      new PVector(0, 0, 1)
    };
    result.x = v1.dot(rz[0]);
    result.y = v1.dot(rz[1]);
    result.z = v1.dot(rz[2]);
  }
  return result;
}

void doCalibration() {
  background(0);
  drawCursor();
  drawArea();
  if (detectedPoint == maxCpoints) {
    detectedPoint = 0;
    calibrationMode = false;
    buildProjecionMatrix();
    buildTestMatrix();
  }
}


void buildTestMatrix() {
  if ( matrixP != null) {
    p = new PMatrix3D(
      (float)matrixP.get(0, 0)[0], (float)matrixP.get(0, 1)[0], (float)matrixP.get(0, 2)[0], (float)matrixP.get(0, 3)[0], 
      (float)matrixP.get(1, 0)[0], (float)matrixP.get(1, 1)[0], (float)matrixP.get(1, 2)[0], (float)matrixP.get(1, 3)[0], 
      (float)matrixP.get(2, 0)[0], (float)matrixP.get(2, 1)[0], (float)matrixP.get(2, 2)[0], (float)matrixP.get(2, 3)[0], 
      0, 0, 0, 1);
    p.print();
  }
}

void mouseClicked() {
  if (calibrationMode) {
    //store variables before building matrix
    //PVector currenPoint = new PVector(); //<----- GIVEN 3D POINT to relate to camera/projector projection plane
    p2dP[detectedPoint] = new PVector(mouseX, mouseY);
    //p3d[detectedPoint] = new PVector(currenPoint.x, currenPoint.y, currenPoint.z); //commented because it is set manually on setup
    detectedPoint++;
  }
}

void keyPressed() {
  if (key=='1' || key=='2' || key=='3' || key=='4' || key=='5' || key=='6') {
    updatingP2D[(key - '0') - 1] = true;
  }
}

void keyReleased() {
  if (key=='1' || key=='2' || key=='3' || key=='4' || key=='5' || key=='6') {
    updatingP2D[(key - '0') - 1] = false;
  }
}

void updateP2D() {
  for (int i = 0; i < maxCpoints; i++) {
    if (updatingP2D[i]) {
      p2dP[i] = new PVector( mouseX, mouseY );
      buildProjecionMatrix();
      buildTestMatrix();
    }
  }
}

void drawCursor() {
  int c = #00ff00;
  int mouseSpeed = abs((mouseX-pmouseX + mouseY - pmouseY ) /2);
  stroke(c);
  strokeWeight(1);
  line(mouseX, 0, mouseX, height);
  line(0, mouseY, width, mouseY);
  fill(c);
  textSize(15);
  text(  detectedPoint +": " + mouseX +","+ mouseY, mouseX + 10, mouseY+ 10);
}

void drawArea() {
  strokeWeight(2);
  stroke(#ff0000);
  noFill();
  rect(0, 0, width, height);
}