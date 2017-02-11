#include <Servo.h> 

Servo myservo;  // create servo object to control a servo 

void setup() 
{ 
  Serial.begin(19200);
  myservo.attach(9);  // attaches the servo on pin 9 to the servo object
} 

int val = 1500;

String inString = "";    // string to hold input

void loop()
{ 
// Read serial input:
  while (Serial.available() > 0) {
    int inChar = Serial.read();
    if (isDigit(inChar)) {
      // convert the incoming byte to a char
      // and add it to the string:
      inString += (char)inChar;
    }
    // if you get a newline, print the string,
    // then the string's value:
    if (inChar == '\n') {
      val = inString.toInt();
      // clear the string for new input:
      inString = "";
    }
  }
  myservo.writeMicroseconds(val);

//  delay(5);
} 


