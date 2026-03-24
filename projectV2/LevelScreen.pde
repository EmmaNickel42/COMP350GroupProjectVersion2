class LevelScreen{
  PImage map;

  color NORTH_AMERICA = color(255, 75, 75);   
  color SOUTH_AMERICA = color(255, 145, 40);   
  color EUROPE        = color(70, 150, 230);   
  color AFRICA        = color(255, 210, 50);   
  color ASIA          = color(170, 215, 90);   
  color AUSTRALIA     = color(120, 200, 220);  

  String currentContinent = "";
  
  float backX = 10;
  float backY = 10;
  float backW = 100;
  float backH = 40;
  
  LevelScreen() {
    map = loadImage("mapV2.png");
  }
  
  void drawLevels(){
     image(map, 0, 0, width, height);

    color c = get(mouseX, mouseY);

    currentContinent = detectContinent(c);
    
    drawBackButton();

    if (currentContinent != "") {
      drawTooltip(mouseX, mouseY, currentContinent);
    }
  }
  
   String detectContinent(color c) {
    if (isClose(c, NORTH_AMERICA)) return "North America";
    if (isClose(c, SOUTH_AMERICA)) return "South America";
    if (isClose(c, EUROPE)) return "Europe";
    if (isClose(c, AFRICA)) return "Africa";
    if (isClose(c, ASIA)) return "Asia";
    if (isCloseCustom(c, AUSTRALIA, 40)) return "Australia"; 
    //Australia was trickier to detect for some reason so needed higher tolerance.

    return "";
  }
  
  boolean isClose(color c1, color c2) {
    float r1 = red(c1), g1 = green(c1), b1 = blue(c1);
    float r2 = red(c2), g2 = green(c2), b2 = blue(c2);

    float tolerance = 30;

    return abs(r1 - r2) < tolerance &&
           abs(g1 - g2) < tolerance &&
           abs(b1 - b2) < tolerance;
  }
  
  boolean isCloseCustom(color c1, color c2, float tolerance) {
    return abs(red(c1) - red(c2)) < tolerance &&
           abs(green(c1) - green(c2)) < tolerance &&
           abs(blue(c1) - blue(c2)) < tolerance;
  }
  
  void drawTooltip(float x, float y, String continent) {
    String difficulty = getDifficulty(continent);

    float boxW = 140;
    float boxH = 50;

    fill(0, 180);
    stroke(0);
    rectMode(CORNER);
    rect(x, y, boxW, boxH, 8);

    fill(255);
    textSize(15);
    text(continent, x + 20, y + 20);
    textSize(12);
    text("Difficulty: " + difficulty, x + 20, y + 45);
  }
  
    String getDifficulty(String continent) {
    if (continent.equals("North America")) return "Easy";
    if (continent.equals("South America")) return "Medium";
    if (continent.equals("Europe")) return "Medium";
    if (continent.equals("Africa")) return "Hard";
    if (continent.equals("Asia")) return "Hard";
    if (continent.equals("Australia")) return "Easy";

    return "";
  }
  
  void drawBackButton() {
    boolean hovering = mouseX > backX && mouseX < backX + backW &&
                       mouseY > backY && mouseY < backY + backH;
  
    if (hovering) {
      fill(80);
    } else {
      fill(40);
    }
  
    stroke(255);
    rect(backX, backY, backW, backH, 8);
  
    fill(255);
    textSize(14);
    textAlign(CENTER, CENTER);
    text("← Back", backX + backW/2, backY + backH/2);
  
    textAlign(LEFT, BASELINE);
  }
  
  String chooseDifficulty(){
    return getDifficulty(currentContinent);
  }

  String chooseScreen(float x, float y){
    // Check BACK button first
    if (x > backX && x < backX + backW &&
        y > backY && y < backY + backH) {
      return "start";
    }
  
    // Otherwise, continent selection
    if (currentContinent != "") {
      return "mainGameplay"; 
    }
  
    return "levelSelect";
  }
}
