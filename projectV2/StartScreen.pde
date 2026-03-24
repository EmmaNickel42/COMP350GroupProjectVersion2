class StartScreen {
  PImage backArt;
  
  StartScreen(){
    backArt = loadImage("startBackV2.png");
  }
  void startup(){
    image(backArt, 0, 0);
    
    rectMode(CENTER);
    
    textSize(80);
    fill(255,0,0);
    text("Firewall", 20, 80);
    
    textSize(20);
    fill(0);
    text("Developed by:", 30, 510);
    text("Emma, Nicole, and Karanpreet", 30, 540);
    
    //Buttons-------------------------------------
    fill(156, 232, 255);
    stroke(88, 208, 245);
    //Play Button
    rect(150, 200, 250,100, 20); 
    //Instructions Button
    rect(150, 350, 250,100, 20);
    //ButtonText
    textSize(30);
    fill(0);
    text("Let's Go!", 90, 210);
    text("Instructions", 70, 360); 
  }
  
  String handleMouse(float x, float y){
    if ((x>=25) && (x<= 275) && (y>= 150) && (y<=245)){
      return "levelSelect";
    } else if ((x>=25) && (x<= 275) && (y>= 300) && (y<=400)) {
      return "instructions";
    } else {
     return "start"; 
    }
  }
  
}
