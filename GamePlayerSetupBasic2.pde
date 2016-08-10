//BASIC OF THE BASIC PLAYER CONTROL SETUP
//USE KEYS a, d, and w
//Anderson Sudario 2016/Ago/10

PVector p; //position
PVector v; //velocity
PVector g; //gravity
float m; //mass

boolean LKEY, RKEY;
float lineY;
boolean lineTouch;
float jumpVal = 8;
float walkVal = 0.2;
float runVal = 4;
int walkRunLim = 20;
int walkCounter = 0;
char[] sprites = {'i','j','w','r'};

ArrayList<PVector> touchVel = new ArrayList<PVector>();
//-----------------------------------------------------------------------------------------------------
void setup() {
  size(200, 200);
  p = new PVector(100, 0);
  v = new PVector();
  g = new PVector(0, 1);
  m = 2;
  lineY = 150;
}
//-----------------------------------------------------------------------------------------------------
void draw() {
  background(200);
  update();
  drawGame();
  plotInfo();
}
//-----------------------------------------------------------------------------------------------------
void update() {
  //gravity added, velocity added to position
  v.add(g);
  p.add(v);
  
  //touches ground (lineY)
  if (p.y > lineY) {
    if (!lineTouch) touchVel.add(v.copy()); //vel when touches ground
    float bounciness = 0.5;
    PVector reverse = touchVel.get(touchVel.size()-1).copy();
    reverse.mult(-bounciness / m );
    v.y = reverse.y;
    p.y = lineY;
    lineTouch = true;
  } else {
    lineTouch = false;
  }
  
  // walk keys pressed
  if ( LKEY ) walk(1);
  if ( RKEY ) walk(-1);
   
  // X movement deceleration
  if (abs(v.x) > 0.1) {
    v.x *= 0.9;
  } else {
    v.x = 0;
  }
}
//-----------------------------------------------------------------------------------------------------
void walk(int direction) {
  walkCounter++;
  if (walkCounter > walkRunLim) {
    v.x =  direction * runVal;
  } else {
    v.x +=  direction *  walkVal;
  }
}
//-----------------------------------------------------------------------------------------------------
void drawGame(){
  strokeWeight(1);
  line(0, lineY, width, lineY); //bg
  strokeWeight(10);
  point(p.x, p.y); //player
}
//-----------------------------------------------------------------------------------------------------
void plotInfo(){
    textSize(10);
  text("v:" + v.x + "," + v.y, 10, lineY + 15);
  text("p:" + p.x + "," + p.y, 10, lineY + 30);
  if (touchVel.size() > 0) {
    int j = 0;
    for (int i = touchVel.size()-1; i >= 0; i--) {
      PVector t = touchVel.get(i);
      textSize(8);
      text(t.x + "," + t.y, 150, 10 + j*10);
      j++;
    }
  }
}
//-----------------------------------------------------------------------------------------------------
void keyPressed() {
  if (key == 'w' && lineTouch) v.y = -8;
  if (key == 'd') LKEY = true;
  if (key == 'a') RKEY = true;
}
//-----------------------------------------------------------------------------------------------------
void keyReleased() {
  if (key == 'd') {
    LKEY = false;
    walkCounter = 0;
  }
  if (key == 'a') {
    RKEY = false;
    walkCounter = 0;
  }
}