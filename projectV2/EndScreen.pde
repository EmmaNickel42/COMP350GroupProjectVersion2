class EndScreen {
  
  void drawEnd(String result){
    background(255);
    
    if (result == "win"){
      //Header
      textAlign(CENTER);
      
      textSize(80);
      fill(50,205,50);
      text("Game Won!", width/2, 100);
      
      //Story
      textSize(30);
      fill(0);
      text("You have become famous for your excellent firewall!\n" +
          "It goes on to sell very well and you \n" + 
          "become a very wealthy developer.", width/2,250);
    }  
    if (result == "lose"){
      //Header
      textAlign(CENTER);
      
      textSize(80);
      fill(255,0,0);
      text("Game Lost!", width/2, 100);
      
      //Story
      textSize(30);
      fill(0);
      text("Your firewall is hacked! You've lost your files and\n" +
          "your credibility. An AI builds the next great firewall \n" + 
          "and your hard work is forgotten.", width/2,250);
    }
      
    //Buttons
    rectMode(CENTER);
    stroke(0,76, 153);
    fill(0, 128, 255);
    rect(200, 450, 150, 75, 8);
    rect(600, 450, 150, 75, 8);
    fill(0);
    text("Play Again", 200, 455);
    text("Main Menu", 600, 455);
    
    textAlign(LEFT, BASELINE);
    rectMode(CORNER);
  }
  
  String handleMouse(float x, float y){
   if ((x>=125) && (x<275) && (y<= 485) && (y>=410)){
     return "mainGameplay";
   }else if ((x>=425) && (x<675) && (y<= 485) && (y>=410)){
     return "start";
   } else {
    return "end"; 
   }
  }
}
