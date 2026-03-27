// GameplaySystem.pde - Version 2 (Visual / Icon Style)
// WHAT THIS FILE DOES:
// - Spawns packets, viruses, and powerups
// - Moves them across the screen toward the server
// - Handles drag-and-drop to scanner / incinerator / server
// - Draws scanner (dial style), incinerator, icon counters, search bar

ArrayList<NetworkObject> objects;
NetworkObject selectedObj = null;

int serverHealth  = 100;
int reputation    = 50;
int threatMeter   = 0;
int slowTimer     = 0;

int packetsPassed = 0;
int virusesBurned = 0;
int packetsBurned = 0;

boolean levelEnded = false;
String endTitle    = "";
String endStory    = "";

// IMAGES — exact names from the data/ folder
PImage imgVirus1, imgVirus2, imgVirus3;
PImage imgStar, imgSlow, imgBlast;
PImage imgIncinerator, imgHealth, imgDial;

// SPAWNING
int lastSpawnTime     = 0;
int baseSpawnInterval = 2500;
// DRAG
float dragOffsetX = 0;
float dragOffsetY = 0;
// SCANNER
float   scannerX, scannerY, scannerW, scannerH;
boolean isScanning    = false;
int     scanStartTime = 0;
int     scanDuration  = 3000;
float   scanDialAngle = 0; // V2: sweeps from 0 to PI
// INCINERATOR
float   incinX, incinY, incinW, incinH;
boolean showIncinEffect = false;
int     incinEffectStart = 0;
int     incinEffectDur   = 800;
// SERVER ZONE
float serverZoneX, serverZoneY, serverZoneW, serverZoneH;
// SEARCH BAR
String searchInput  = "";
String searchResult = "";

void setupGameplaySystem() {
  objects = new ArrayList<NetworkObject>();

  // Load images ONCE — never inside draw() or display()
  imgVirus1      = loadImage("virus1.png");
  imgVirus2      = loadImage("virus2.png");
  imgVirus3      = loadImage("virus3.png");
  imgStar        = loadImage("star.png");
  imgSlow        = loadImage("slow.png");
  imgBlast       = loadImage("blast.png");
  imgIncinerator = loadImage("incinerator.png");
  imgHealth      = loadImage("health.png");
  imgDial        = loadImage("dial.png");

  // Interaction zones
  scannerX    = width * 0.38;  scannerY    = height * 0.72;
  scannerW    = 160;           scannerH    = 110;

  incinX      = width * 0.62;  incinY      = height * 0.72;
  incinW      = 100;           incinH      = 100;

  serverZoneX = width * 0.84;  serverZoneY = height * 0.10;
  serverZoneW = 80;            serverZoneH = height * 0.70;

  lastSpawnTime = millis();
}
//  RESET — call when starting a new game from level select
void resetGameplaySystem() {
  objects.clear();
  selectedObj   = null;
  serverHealth  = 100;
  reputation    = 50;
  threatMeter   = 0;
  slowTimer     = 0;
  packetsPassed = 0;
  virusesBurned = 0;
  packetsBurned = 0;
  levelEnded    = false;
  isScanning    = false;
  scanDialAngle = 0;
  showIncinEffect = false;
  searchInput   = "";
  searchResult  = "";
  lastSpawnTime = millis();
}

void drawGameplay() {
  background(199, 255, 249); // V2: light teal background matches tutorial screen

  // Spawn objects on timer
  if (millis() - lastSpawnTime > getSpawnInterval()) {
    spawnObject();
    lastSpawnTime = millis();
  }

  // Speed multiplier from slow powerup
  float speedMult = (slowTimer > 0) ? 0.4 : 1.0;

  // Move and draw every object
  for (int i = objects.size() - 1; i >= 0; i--) {
    NetworkObject obj = objects.get(i);

    if (obj != selectedObj) {
      obj.x += obj.speed * speedMult;
    }

    obj.display();

    // Object reached server on its own
    if (obj.x > serverZoneX && obj != selectedObj) {
      handleObjectReachedServer(obj);  
      objects.remove(i);
    }
  }

  // Nicole's per-frame functions
  updatePowerupEffects();  // counts down slowTimer
  checkLevelState();       // sets currentScreen = "end" on win/lose

  // Draw UI elements
  drawServerZone();
  drawScannerAndIncinerator();
  if (showIncinEffect) drawIncinEffect();
  drawIconCounters();      // V2: hearts/stars/dial instead of bar graphs
  drawSearchBar();
}
//  SPAWNING
void spawnObject() {
  float  roll   = random(1);
  String sType  = "packet";
  String sPower = "";

  if      (roll < 0.50) { sType = "packet"; }
  else if (roll < 0.80) { sType = "virus";  }
  else {
    sType  = "powerup";
    sPower = (random(1) < 0.5) ? "slow" : "blast";
  }

  float sy = random(height * 0.12, height * 0.65);
  objects.add(new NetworkObject(sType, sPower, -50, sy));
}

// Spawn gets faster based on difficulty + threat level
int getSpawnInterval() {
  int base = baseSpawnInterval;
  if (difficulty != null) {
    if (difficulty.equals("Easy"))   base = 3000;
    if (difficulty.equals("Medium")) base = 2200;
    if (difficulty.equals("Hard"))   base = 1400;
  }
  return max(600, base - threatMeter * 12);
}
//  MOUSE INTERACTION
void gameMousePressed() {
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
      
      // Otherwise drag it
      selectedObj = obj;
      dragOffsetX = obj.x - mouseX;
      dragOffsetY = obj.y - mouseY;
      return;
    }
  }
}

void gameDragged() {
  if (selectedObj != null) {
    selectedObj.x = mouseX + dragOffsetX;
    selectedObj.y = mouseY + dragOffsetY;
  }
}

void gameReleased() {
  if (selectedObj == null) return;

  // SCANNER
  if (isInZone(selectedObj.x, selectedObj.y, scannerX, scannerY, scannerW, scannerH)) {
    if (!isScanning) {
      isScanning    = true;
      scanStartTime = millis();
      scanDialAngle = 0;
      selectedObj.x = scannerX + scannerW / 2;
      selectedObj.y = scannerY + scannerH / 2;
    }

  // INCINERATOR
  } else if (isInZone(selectedObj.x, selectedObj.y, incinX, incinY, incinW, incinH)) {
    if (selectedObj.type.equals("powerup") && selectedObj.powerType.equals("blast")) {
      showIncinEffect  = true;
      incinEffectStart = millis();
    }
    burnSelectedObject();  
    isScanning    = false;
    scanDialAngle = 0;
    selectedObj   = null;

  // SERVER ZONE
  } else if (isInZone(selectedObj.x, selectedObj.y, serverZoneX, serverZoneY, serverZoneW, serverZoneH)) {
    handleObjectReachedServer(selectedObj); 
    objects.remove(selectedObj);
    selectedObj   = null;
    isScanning    = false;
    scanDialAngle = 0;

  // Dropped elsewhere
  } else {
    selectedObj = null;
  }
}

void gameKeyPressed() {
  if (key == BACKSPACE && searchInput.length() > 0) {
    searchInput  = searchInput.substring(0, searchInput.length() - 1);
    searchResult = "";
  } else if (key == ENTER) {
    searchResult = searchByID(searchInput);
  } else if (key != CODED && searchInput.length() < 12) {
    searchInput += key;
  }
}
//  SCAN COMPLETION — checked every frame inside drawGameplay()
void checkScanComplete() {
  if (!isScanning || selectedObj == null) return;

  int elapsed = millis() - scanStartTime;

  // Update dial angle for V2 visual
  scanDialAngle = map(elapsed, 0, scanDuration, 0, PI);

  if (elapsed >= scanDuration) {
    String result              = scanSelectedObject(); 
    selectedObj.scanned        = true;
    selectedObj.scanResult     = result;
    selectedObj.showScanResult = true;
    isScanning    = false;
    scanDialAngle = 0;
    selectedObj   = null;
  }
}
//  SEARCH BY ID
String searchByID(String query) {
  for (NetworkObject obj : objects) {
    if (obj.id.equalsIgnoreCase(query)) {
      if (obj.scanned) {
        boolean safe = obj.scanResult.contains("Safe") ||
                       obj.scanResult.contains("safe");
        return obj.id + (safe ? " → Safe ✓" : " → Unsafe ✗");
      } else {
        return obj.id + " → Not verified";
      }
    }
  }
  return "ID not found.";
}

//  DRAW: SERVER ZONE
void drawServerZone() {
  stroke(0, 180, 80);
  strokeWeight(2);
  noFill();
  rect(serverZoneX, serverZoneY, serverZoneW, serverZoneH, 8);
  fill(0, 160, 60);
  noStroke();
  textSize(11);
  textAlign(CENTER, TOP);
  text("SERVER", serverZoneX + serverZoneW / 2, serverZoneY + 4);
}
//  DRAW: SCANNER + INCINERATOR (V2 — dial style, minimal text)
void drawScannerAndIncinerator() {
  checkScanComplete();

  // Scanner box — purple glow
  stroke(180, 100, 255);
  strokeWeight(2);
  noFill();
  rect(scannerX, scannerY, scannerW, scannerH, 12);

  // Scan icon instead of text label
  fill(180, 100, 255, 80);
  noStroke();
  ellipse(scannerX + scannerW / 2, scannerY + 18, 28, 28);
  fill(220, 180, 255);
  textAlign(CENTER, CENTER);
  textSize(14);
  text("O", scannerX + scannerW / 2, scannerY + 18);

  // Dial arc (V2 style — half circle sweep)
  pushMatrix();
  translate(scannerX + scannerW / 2, scannerY + scannerH - 28);
  noFill();
  // Background arc
  stroke(80);
  strokeWeight(8);
  arc(0, 0, 64, 64, PI, TWO_PI);
  // Progress arc
  if (isScanning) {
    color arcCol = lerpColor(color(255, 60, 60), color(80, 255, 80),
                             scanDialAngle / PI);
    stroke(arcCol);
    strokeWeight(8);
    arc(0, 0, 64, 64, PI, PI + scanDialAngle);
  }
  popMatrix();

  // Incinerator box — icon only in V2, no text label
  stroke(255, 100, 0);
  strokeWeight(2);
  noFill();
  rect(incinX, incinY, incinW, incinH, 12);
  image(imgIncinerator,
        incinX + incinW / 2 - 24,
        incinY + incinH / 2 - 24, 48, 48);
}
//  DRAW: BLAST VISUAL EFFECT
void drawIncinEffect() {
  int elapsed = millis() - incinEffectStart;
  if (elapsed > incinEffectDur) {
    showIncinEffect = false;
    return;
  }
  float alpha = map(elapsed, 0, incinEffectDur, 220, 0);
  float sz    = map(elapsed, 0, incinEffectDur, 160, 320);
  tint(255, alpha);
  image(imgIncinerator, width / 2 - sz / 2, height / 2 - sz / 2, sz, sz);
  noTint();
}
//  DRAW: ICON COUNTERS (V2 — hearts/stars/dial, no bar graphs)
void drawIconCounters() {
  float px  = 12;
  float py  = height * 0.06;
  float sz  = 30;
  float gap = 10;

  // Server health as hearts (up to 5)
  int hearts = (int) map(serverHealth, 0, 100, 0, 5);
  for (int i = 0; i < 5; i++) {
    if (i < hearts) {
      tint(255);
    } else {
      tint(80);
    }
    image(imgHealth, px + i * (sz + gap), py, sz, sz);
  }
  noTint();

  // Reputation as stars (up to 5)
  int stars = (int) map(reputation, 0, 100, 0, 5);
  for (int i = 0; i < 5; i++) {
    if (i < stars) {
      tint(255);
    } else {
      tint(80);
    }
    image(imgStar, px + i * (sz + gap), py + sz + 8, sz, sz);
  }
  noTint();

  // Threat dial icon + number
  image(imgDial, px, py + (sz + 8) * 2, sz, sz);
  fill(0);
  noStroke();
  textSize(13);
  textAlign(LEFT, CENTER);
  text("Threat: " + threatMeter, px + sz + 6, py + (sz + 8) * 2 + sz / 2);
}
//  DRAW: SEARCH BAR (V2 styled — rounded, minimal)
void drawSearchBar() {
  float bx = scannerX - 165;
  float by = scannerY + 10;
  float bw = 150;
  float bh = 26;

  fill(220, 200, 255);
  stroke(180, 100, 255);
  strokeWeight(1);
  rect(bx, by, bw, bh, 8);

  fill(60, 0, 100);
  noStroke();
  textSize(11);
  textAlign(LEFT, CENTER);
  text(searchInput.length() > 0 ? searchInput : "Search ID...",
       bx + 8, by + bh / 2);

  if (searchResult.length() > 0) {
    fill(100, 0, 160);
    textSize(10);
    textAlign(LEFT, TOP);
    text(searchResult, bx, by + bh + 5);
  }
}
//  HELPER
boolean isInZone(float px, float py,
                 float zx, float zy, float zw, float zh) {
  return px > zx && px < zx + zw &&
         py > zy && py < zy + zh;
}
//  NetworkObject CLASS 
class NetworkObject {
  String type;       // "packet" / "virus" / "powerup"
  String powerType;  // "slow" / "blast"  (powerup only)
  String id;

  float x, y, speed, w, h;

  boolean scanned        = false;
  boolean showScanResult = false;
  String  scanResult     = "";

  PImage img;

  NetworkObject(String t, String pt, float sx, float sy) {
    type      = t;
    powerType = pt;
    x = sx;  y = sy;
    speed = random(0.8, 1.6);

    if (type.equals("virus")) {
      int r = (int) random(3);
      img = (r == 0) ? imgVirus1 : (r == 1) ? imgVirus2 : imgVirus3;
      w = 48;  h = 48;
      id = "VIR-" + (int) random(1000, 9999);

    } else if (type.equals("packet")) {
      img = null;
      w = 64;  h = 40;
      id = "PKT-" + (int) random(1000, 9999);

    } else {  // powerup
      img = powerType.equals("slow") ? imgSlow : imgBlast;
      w = 44;  h = 44;
      id = "PWR-" + powerType.toUpperCase();
    }
  }

  void display() {
    if (type.equals("packet")) {
      drawPacket();
    } else if (img != null) {
      image(img, x - w/2, y - h/2, w, h);
    }

    // Yellow outline when selected
    if (this == selectedObj) {
      noFill();
      stroke(255, 255, 0);
      strokeWeight(2);
      rect(x - w/2 - 3, y - h/2 - 3, w + 6, h + 6, 4);
    }

    // V2 scan result: colour glow circle, no text
    if (showScanResult) {
      boolean safe = scanResult.contains("Safe") ||
                     scanResult.contains("safe");
      fill(safe ? color(0, 255, 100, 160) : color(255, 30, 30, 160));
      noStroke();
      ellipse(x + w/2, y - h/2, 20, 20);
    }
  }

  // V2 packet: rounded, colourful, just the ID — minimal text
  void drawPacket() {
    boolean safe = scanResult.contains("Safe") ||
                   scanResult.contains("safe");
    color bg = scanned
      ? (safe ? color(30, 180, 80) : color(180, 30, 30))
      : color(100, 60, 200);

    fill(bg);
    stroke(200, 160, 255);
    strokeWeight(1.5);
    rect(x - w/2, y - h/2, w, h, 10);

    fill(255);
    textSize(10);
    textAlign(CENTER, CENTER);
    noStroke();
    text(id, x, y);
  }

  boolean isMouseOver() {
    return mouseX > x - w/2 && mouseX < x + w/2 &&
           mouseY > y - h/2 && mouseY < y + h/2;
  }
}
