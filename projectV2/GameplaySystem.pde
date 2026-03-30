// FSM states
final int STATE_SPAWNING = 0;
final int STATE_SCANNING = 1;
final int STATE_SLOWDOWN = 2;
final int STATE_GAMEOVER = 3;
int gameState = STATE_SPAWNING;

// Shared globals
ArrayList<NetworkObject> objects;
NetworkObject selectedObj = null;

int serverHealth  = 100;
int reputation    = 50;
int threatMeter   = 0;
int slowTimer     = 0;

int packetsPassed = 0;
int virusesBurned = 0;
int packetsBurned = 0;
int powerupsUsed  = 0;

boolean levelEnded = false;
String endTitle    = "";
String endStory    = "";

// Static arrays for movement tracking
float[] trackedX = new float[10];
float[] trackedY = new float[10];
int trackIndex   = 0;

// Stack for scan history
ArrayList<NetworkObject> scanStack = new ArrayList<NetworkObject>();
void stackPush(NetworkObject obj) {
  scanStack.add(obj);
}
NetworkObject stackPop() {
  if (scanStack.size() == 0) return null;
  return scanStack.remove(scanStack.size() - 1);
}

// Images
PImage imgVirus1, imgVirus2, imgVirus3;
PImage imgStar, imgSlow, imgBlast;
PImage imgIncinerator, imgHealth, imgDial;

// Spawning
int lastSpawnTime     = 0;
int baseSpawnInterval = 3000;

// Drag
float dragOffsetX = 0;
float dragOffsetY = 0;

// Scanner
float   scannerX, scannerY, scannerW, scannerH;
boolean isScanning    = false;
int     scanStartTime = 0;
int     scanDuration  = 1500;
float   scanDialAngle = 0;

// Incinerator
float   incinX, incinY, incinW, incinH;
boolean showIncinEffect  = false;
int     incinEffectStart = 0;
int     incinEffectDur   = 800;

// Server zone
float serverZoneX, serverZoneY, serverZoneW, serverZoneH;

// Search bar
String searchInput  = "";
String searchResult = "";

// File output
PrintWriter movementLog;
// INTERFACES
interface Scannable {
  String getScanResult();
  boolean isSafeObject();
}

interface Displayable {
  void display();
  boolean isMouseOver();
}

// ABSTRACT BASE CLASS (Grandparent)
abstract class GameEntity implements Scannable, Displayable {
  float x, y, speed, w, h;
  String id;
  boolean scanned        = false;
  boolean showScanResult = false;
  String  scanResult     = "";

  GameEntity(float sx, float sy) {
    x = sx;
    y = sy;
    speed = random(0.8, 1.6);
  }

  void move(float speedMult) {
    x += speed * speedMult;
    if (frameCount % 10 == 0) {
      y += (noise(x * 0.01, y * 0.01) - 0.5) * 1.5; // noise()
    }
  }

  void trackPosition() {
    trackedX[trackIndex % 10] = x;
    trackedY[trackIndex % 10] = y;
    trackIndex++;
  }

  String getScanResult() {
    return scanResult;
  }
  boolean isSafeObject() {
    if (this instanceof NetworkObject) {
      return ((NetworkObject)this).isSafe;
    }
    return false;
  }

  abstract void display();
  abstract boolean isMouseOver();
}

// PARENT CLASS (NetworkObject)
class NetworkObject extends GameEntity {
  String type;
  String powerType;
  PImage img;

  boolean isSafe = true;

  NetworkObject(String t, String pt, float sx, float sy) {
    super(sx, sy);
    type = t;
    powerType = pt;

    if (type.equals("virus")) {
      int r = (int)random(3);
      img = (r==0) ? imgVirus1 : (r==1) ? imgVirus2 : imgVirus3;
      w=48;
      h=48;
      id = "VIR-" + (int)random(1000, 9999);
    } else if (type.equals("packet")) {
      img = null;
      w=64;
      h=40;
      id = "PKT-" + (int)random(1000, 9999);

      // 60% safe, 40% unsafe
      isSafe = random(1) < 0.6;
    } else {
      img = powerType.equals("slow") ? imgSlow : imgBlast;
      w=44;
      h=44;
      id = "PWR-" + powerType.toUpperCase();
    }
  }

  void display() {
    pushMatrix(); // pushMatrix/popMatrix for 2D transformation
    translate(x, y);

    if (type.equals("packet")) drawPacket();
    else if (img != null) image(img, -w/2, -h/2, w, h);

    if (this == selectedObj) {
      noFill();
      stroke(255, 255, 0);
      strokeWeight(2);
      rect(-w/2-3, -h/2-3, w+6, h+6, 4);
    }
    if (showScanResult) {
      fill(isSafeObject() ? color(0, 255, 100, 160) : color(255, 30, 30, 160));
      noStroke();
      ellipse(w/2, -h/2, 20, 20);
    }

    popMatrix();
  }

  void drawPacket() {
    color bg = scanned
      ? (isSafeObject() ? color(30, 180, 80) : color(180, 30, 30))
      : color(100, 60, 200);
    fill(bg);
    stroke(200, 160, 255);
    strokeWeight(1.5);
    rect(-w/2, -h/2, w, h, 10);
    fill(255);
    textSize(11);
    textAlign(CENTER, CENTER);
    noStroke();
    text(id, 0, 0);
  }

  boolean isMouseOver() {
    return mouseX>x-w/2 && mouseX<x+w/2 &&
      mouseY>y-h/2 && mouseY<y+h/2;
  }
}

// CHILD CLASS (VirusObject)
class VirusObject extends NetworkObject {
  int threatMultiplier;

  VirusObject(float sx, float sy) {
    super("virus", "", sx, sy);
    int r = (int)random(3);
    img = (r==0) ? imgVirus1 : (r==1) ? imgVirus2 : imgVirus3;
    threatMultiplier = (int)random(1, 3);
    w=48;
    h=48;
    id = "VIR-" + (int)random(1000, 9999);
  }

  void display() {
    if (threatMultiplier > 1) {
      pushMatrix(); // pushMatrix for virus glow effect
      translate(x, y);
      noStroke();
      fill(255, 50, 50, 60);
      ellipse(0, 0, w+16, h+16);
      popMatrix();
    }
    super.display();
  }
}

// SETUP
void setupGameplaySystem() {
  objects   = new ArrayList<NetworkObject>();
  scanStack = new ArrayList<NetworkObject>();

  imgVirus1      = loadImage("virus1.png");
  imgVirus2      = loadImage("virus2.png");
  imgVirus3      = loadImage("virus3.png");
  imgStar        = loadImage("star.png");
  imgSlow        = loadImage("slow.png");
  imgBlast       = loadImage("blast.png");
  imgIncinerator = loadImage("incinerator.png");
  imgHealth      = loadImage("health.png");
  imgDial        = loadImage("dial.png");

  scannerX    = width*0.38;
  scannerY    = height*0.72;
  scannerW    = 160;
  scannerH    = 110;
  incinX      = width*0.62;
  incinY      = height*0.72;
  incinW      = 100;
  incinH      = 100;
  serverZoneX = width*0.84;
  serverZoneY = height*0.10;
  serverZoneW = 80;
  serverZoneH = height*0.70;

  movementLog = createWriter("movement_log.txt");
  movementLog.println("ID,X,Y,Type,Time");

  lastSpawnTime = millis();
  gameState     = STATE_SPAWNING;
}

// RESET
void resetGameplaySystem() {
  objects.clear();
  scanStack.clear();
  selectedObj     = null;
  serverHealth    = 100;
  reputation      = 50;
  threatMeter     = 0;
  slowTimer       = 0;
  packetsPassed   = 0;
  virusesBurned   = 0;
  packetsBurned   = 0;
  powerupsUsed    = 0;
  levelEnded      = false;
  isScanning      = false;
  scanDialAngle   = 0;
  showIncinEffect = false;
  trackIndex      = 0;
  lastSpawnTime   = millis();
  gameState       = STATE_SPAWNING;
}

// FSM UPDATE
void updateFSM() {
  switch (gameState) {
  case STATE_SPAWNING:
    if (isScanning)     gameState = STATE_SCANNING;
    if (slowTimer > 0)  gameState = STATE_SLOWDOWN;
    if (levelEnded)     gameState = STATE_GAMEOVER;
    break;
  case STATE_SCANNING:
    if (!isScanning)    gameState = (slowTimer>0) ? STATE_SLOWDOWN : STATE_SPAWNING;
    if (levelEnded)     gameState = STATE_GAMEOVER;
    break;
  case STATE_SLOWDOWN:
    if (slowTimer <= 0) gameState = STATE_SPAWNING;
    if (levelEnded)     gameState = STATE_GAMEOVER;
    break;
  case STATE_GAMEOVER:
    break;
  }
}

// MAIN DRAW
void drawGameplay() {
  background(199, 255, 249);

  updateFSM();

  if (millis() - lastSpawnTime > getSpawnInterval()) {
    spawnObject();
    lastSpawnTime = millis();
  }

  float speedMult = (slowTimer > 0) ? 0.4 : 1.0;

  for (int i = objects.size()-1; i >= 0; i--) { // for loop
    NetworkObject obj = objects.get(i);

    if (obj != selectedObj) {
      obj.move(speedMult);
      obj.trackPosition();
    }

    obj.display();

    if (frameCount % 60 == 0) logObjectPosition(obj);

    if (obj.x > serverZoneX && obj != selectedObj) {
      handleObjectReachedServer(obj);
      objects.remove(i);
    }
  }

  updatePowerupEffects();
  checkLevelState();

  drawServerZone();
  drawScannerAndIncinerator();
  if (showIncinEffect) drawIncinEffect();
  drawIconCounters();
}

// SPAWNING
void spawnObject() {
  float  roll   = random(1);
  String sType  = "packet";
  String sPower = "";

  if      (roll < 0.50) {
    sType = "packet";
  } else if (roll < 0.80) {
    sType = "virus";
  } else {
    sType  = "powerup";
    sPower = (random(1) < 0.5) ? "slow" : "blast";
  }

  float sy = random(height*0.12, height*0.65);
  if (sType.equals("virus")) {
    objects.add(new VirusObject(-50, sy));
  } else {
    objects.add(new NetworkObject(sType, sPower, -50, sy));
  }
}

int getSpawnInterval() {
  int base = baseSpawnInterval;
  if (difficulty != null) {
    if (difficulty.equals("Easy"))   base = 3000;
    if (difficulty.equals("Medium")) base = 2200;
    if (difficulty.equals("Hard"))   base = 1400;
  }
  return max(600, base - threatMeter*12);
}

// FILE I/O
void logObjectPosition(NetworkObject obj) {
  if (movementLog != null) {
    movementLog.println(obj.id+","+nf(obj.x, 1, 1)+","+
      nf(obj.y, 1, 1)+","+obj.type+","+millis());
    movementLog.flush();
  }
}

// Sort algorithm + while loop
float[] getSortedTrackedX() {
  float[] sorted = trackedX.clone(); // static array
  int i = 0;
  while (i < sorted.length - 1) { // while loop
    int j = 0;
    while (j < sorted.length - 1 - i) {
      if (sorted[j] < sorted[j+1]) {
        float temp  = sorted[j];
        sorted[j]   = sorted[j+1];
        sorted[j+1] = temp;
      }
      j++;
    }
    i++;
  }
  return sorted;
}

// MOUSE INTERACTION
void gameMousePressed() {
  // Do not allow selecting another object while scanner is busy
  if (isScanning) {
    return;
  }

  for (int i = objects.size() - 1; i >= 0; i--) {
    NetworkObject obj = objects.get(i);
    if (obj.isMouseOver()) {
      if (obj.type.equals("powerup")) {
        selectedObj = obj;
        activatePowerup(obj);
        if (obj.powerType.equals("blast")) {
          showIncinEffect  = true;
          incinEffectStart = millis();
        }
        objects.remove(i);
        selectedObj = null;
        return;
      }

      selectedObj = obj;
      dragOffsetX = obj.x - mouseX;
      dragOffsetY = obj.y - mouseY;
      return;
    }
  }
}

void gameDragged() {
  if (isScanning) {
    return;
  }
  if (selectedObj != null) {
    selectedObj.x = mouseX + dragOffsetX;
    selectedObj.y = mouseY + dragOffsetY;
  }
}

void gameReleased() {
  if (selectedObj == null) return;

  if (isInZone(selectedObj.x, selectedObj.y, scannerX, scannerY, scannerW, scannerH)) {
    if (!isScanning) {
      isScanning    = true;
      scanStartTime = millis();
      scanDialAngle = 0;
      selectedObj.x = scannerX + scannerW / 2;
      selectedObj.y = scannerY + scannerH / 2;
      stackPush(selectedObj); // stack push
      return;
    }
  } else if (isInZone(selectedObj.x, selectedObj.y, incinX, incinY, incinW, incinH)) {
    if (selectedObj.type.equals("powerup") && selectedObj.powerType.equals("blast")) {
      showIncinEffect  = true;
      incinEffectStart = millis();
    }
    burnSelectedObject();
    isScanning    = false;
    scanDialAngle = 0;
    selectedObj   = null;
  } else if (isInZone(selectedObj.x, selectedObj.y, serverZoneX, serverZoneY, serverZoneW, serverZoneH)) {
    handleObjectReachedServer(selectedObj);
    objects.remove(selectedObj);
    selectedObj   = null;
    isScanning    = false;
    scanDialAngle = 0;
  } else {
    selectedObj = null;
  }
}

void gameKeyPressed() {
}

// SCAN COMPLETION
void checkScanComplete() {
  if (!isScanning || selectedObj==null) return;
  int elapsed = millis()-scanStartTime;
  scanDialAngle = map(elapsed, 0, scanDuration, 0, PI);
  if (elapsed >= scanDuration) {
    String result          = scanSelectedObject();
    selectedObj.scanned        = true;
    selectedObj.scanResult     = result;
    selectedObj.showScanResult = true;
    stackPop(); // stack pop
    isScanning    = false;
    scanDialAngle = 0;
    selectedObj   = null;
  }
}

// SERVER ZONE
void drawServerZone() {
  stroke(0, 180, 80);
  strokeWeight(2);
  noFill();
  rect(serverZoneX, serverZoneY, serverZoneW, serverZoneH, 8);
  fill(0, 160, 60);
  noStroke();
  textSize(11);
  textAlign(CENTER, TOP);
  text("SERVER", serverZoneX+serverZoneW/2, serverZoneY+4);
}
// DRAW: SCANNER + INCINERATOR (V2 dial style)
void drawScannerAndIncinerator() {
  checkScanComplete();

  stroke(180, 100, 255);
  strokeWeight(2);
  noFill();
  rect(scannerX, scannerY, scannerW, scannerH, 12);

  fill(180, 100, 255, 80);
  noStroke();
  ellipse(scannerX+scannerW/2, scannerY+18, 28, 28);
  fill(220, 180, 255);
  textAlign(CENTER, CENTER);
  textSize(14);
  text("O", scannerX+scannerW/2, scannerY+18);

  pushMatrix();
  translate(scannerX+scannerW/2, scannerY+scannerH-28);
  noFill();
  stroke(80);
  strokeWeight(8);
  arc(0, 0, 64, 64, PI, TWO_PI);
  if (isScanning) {
    color arcCol = lerpColor(color(255, 60, 60), color(80, 255, 80), scanDialAngle/PI);
    stroke(arcCol);
    strokeWeight(8);
    arc(0, 0, 64, 64, PI, PI+scanDialAngle);
  }
  popMatrix();

  stroke(255, 100, 0);
  strokeWeight(2);
  noFill();
  rect(incinX, incinY, incinW, incinH, 12);
  image(imgIncinerator, incinX+incinW/2-24, incinY+incinH/2-24, 48, 48);
}

// DRAW: BLAST EFFECT
void drawIncinEffect() {
  int e = millis()-incinEffectStart;
  if (e>incinEffectDur) {
    showIncinEffect=false;
    return;
  }
  float alpha = map(e, 0, incinEffectDur, 220, 0);
  float sz    = map(e, 0, incinEffectDur, 160, 320);
  tint(255, alpha);
  image(imgIncinerator, width/2-sz/2, height/2-sz/2, sz, sz);
  noTint();
}

// DRAW: ICON COUNTERS (V2 hearts/stars + live threat dial)
void drawIconCounters() {
  float px=12, py=height*0.06, sz=30, gap=10;

  int hearts = (int)map(serverHealth, 0, 100, 0, 5);
  for (int i=0; i<5; i++) {
    tint(i<hearts ? 255 : 80);
    image(imgHealth, px+i*(sz+gap), py, sz, sz);
  }
  noTint();

  int stars = (int)map(reputation, 0, 100, 0, 5);
  for (int i=0; i<5; i++) {
    tint(i<stars ? 255 : 80);
    image(imgStar, px+i*(sz+gap), py+sz+8, sz, sz);
  }
  noTint();

  drawThreatDial(px+80, py+(sz+8)*2+20, 28);
}

void drawThreatDial(float cx, float cy, float r) {
  fill(40, 30, 60);
  stroke(120, 80, 180);
  strokeWeight(1);
  ellipse(cx, cy, r*2, r*2);

  noFill();
  strokeWeight(r*0.3);
  stroke(0, 200, 80);
  arc(cx, cy, r*1.4, r*1.4, PI, PI+PI*0.4);
  stroke(255, 200, 0);
  arc(cx, cy, r*1.4, r*1.4, PI+PI*0.4, PI+PI*0.7);
  stroke(255, 50, 50);
  arc(cx, cy, r*1.4, r*1.4, PI+PI*0.7, TWO_PI);

  float angle = map(threatMeter, 0, 100, PI, TWO_PI);
  float nx = cx+cos(angle)*(r*0.7);
  float ny = cy+sin(angle)*(r*0.7);
  stroke(255);
  strokeWeight(2);
  line(cx, cy, nx, ny);

  fill(255);
  noStroke();
  ellipse(cx, cy, 5, 5);
  fill(150);
  textSize(8);
  textAlign(CENTER, TOP);
  text("THREAT", cx, cy+r+2);
}

// HELPER
boolean isInZone(float px, float py,
  float zx, float zy, float zw, float zh) {
  return px>zx && px<zx+zw && py>zy && py<zy+zh;
}
