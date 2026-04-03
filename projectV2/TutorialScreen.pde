class TutorialScreen {

  void drawTut() {
    background(199, 255, 249);

    rectMode(CENTER);
    fill(255, 255, 255, 220);
    stroke(255);
    strokeWeight(2);
    rect(width/2, height/2 + 25, 750, 500, 35);

    textAlign(CENTER, CENTER);
    textSize(80);
    fill(0);
    text("How To Play", width/2, 130);

    textSize(15);
    fill(0);
    
    text("You dream of being the best security developer known to mankind. \n You are on a quest to create the safest firewall of all time.\n"
    + "You know that this is your chance to make it big. But first, you must defend your own server.\n"
    + "Packets and viruses will attempt to enter your server. \n"
    + "All viruses are malicious and will harm your reputation and your server's health.\n"
    + "Packets can be malicious or just fine. Packets must be scanned to determine if they are bad or not. \n"
    + "If safe packets enter your server, your reputation increases. If an unsafe packet enters, your server will lose health \n"
    + "and you will lose reputation. There are power ups you can click on in order to help you out.\n"
    + "Be warned, the server traffic will increase over time.\n"
    + "If your server has no health left, you lose. If your reputation reaches 100, you win!"
    , width/2, height/2 + 40);
    
    //Buttons-------------------------------------
    fill(149, 240, 58);
    stroke(126, 201, 50);
    //Back Button
    rect(110, 40, 150, 50, 35);
    //ButtonText
    textSize(20);
    fill(0);
    text("Back", 110, 40);

    textAlign(LEFT, BASELINE);
  }

  String handleMouse(float x, float y) {
    if ((x>=5) && (x<= 185) && (y>= 15) && (y<=65)) {
      return "start";
    } else {
      return "instructions";
    }
  }
}
