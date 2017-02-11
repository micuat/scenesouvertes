#include <Wire.h>
#include <Adafruit_Sensor.h>
#include <Adafruit_BNO055.h>
#include <utility/imumaths.h>

#include "hsv2rgb.h"

#include "Adafruit_BLE.h"
#include "Adafruit_BluefruitLE_UART.h"

#define RTS  10
#define RXI  11
#define TXO  12
#define CTS  13
#define MODE -1

#define BUFSIZE 128
#define VERBOSE_MODE false
Adafruit_BNO055 bno = Adafruit_BNO055(55);
SoftwareSerial bluefruitSS = SoftwareSerial(TXO, RXI);
Adafruit_BluefruitLE_UART ble(bluefruitSS, MODE, CTS, RTS);

#define BNO055_SAMPLERATE_DELAY_MS (100)
#define BLE_SAMPLERATE_DELAY_MS (500)

#define REDPIN 6
#define GREENPIN 5
#define BLUEPIN 3

/***************************************************************************
   Arduino setup functions (automatically called at startup)
 ***************************************************************************/

void setup() {
  // put your setup code here, to run once:
  /* Initialize the BNO055 Sensor */
  Serial.begin(9600);

  delay(5000);

  if (! ble.begin(VERBOSE_MODE)) {
    Serial.println( F("FAILED!") );
    while (1);
  }

  Serial.println( F("OK!") );

  Serial.print(F("Factory reset: "));
  while (! ble.factoryReset()) {
    Serial.println(F("FAILED."));
    delay(1000);
    //while (1);
  }

  Serial.println( F("OK!") );

  ble.echo(false);

  Serial.print(F("Set device name: "));
  if (! ble.sendCommandCheckOK(F("AT+GAPDEVNAME=BNOIOS"))) {
    Serial.println(F("FAILED."));
    while (1);
  }

  Serial.println(F("OK!"));

  ble.reset();

  Serial.print(F("BNO055 init: "));
  if (!bno.begin())
  {
    /* There is a problem initializing the sensor */
    Serial.println("No BN0055 detected: Check your wiring or I2C ADDRESS");
    while (1);
  }
  Serial.println( F("OK!") );

  delay(1000);

  bno.setExtCrystalUse(true);

  //while (! ble.isConnected())
  //  delay(500);

  //Serial.println(F("Connected"));

  pinMode(REDPIN, OUTPUT);
  pinMode(GREENPIN, OUTPUT);
  pinMode(BLUEPIN, OUTPUT);

  analogWrite(REDPIN, 0);
  analogWrite(GREENPIN, 0);
  analogWrite(BLUEPIN, 0);


}

/*Arduino loop functions (continuously iterate through loop function) */

long current_timer = 0;
long bno_timer = 0;
long ble_timer = 0;

imu::Vector<3> Euler;
imu::Vector<3> RGBValues;

void loop() {
  // put your main code here, to run repeatedly:
  current_timer = millis();

  //check to see if 100 ms have elapsed to query the BNO055

  if ((current_timer - bno_timer) >= BNO055_SAMPLERATE_DELAY_MS) {
    /* Get a new sensor event */
    sensors_event_t bno_event;


    /* The expected data structure for the UE4 sketch is acceleration[3] and quaternion[4] */

    // Possible vector values can be:
    // - VECTOR_ACCELEROMETER - m/s^2
    // - VECTOR_MAGNETOMETER  - uT
    // - VECTOR_GYROSCOPE     - rad/s
    // - VECTOR_EULER         - degrees
    // - VECTOR_LINEARACCEL   - m/s^2
    // - VECTOR_GRAVITY       - m/s^2

    //imu::Vector<3> euler = bno.getVector(Adafruit_BNO055::VECTOR_EULER);

    imu::Quaternion quaternion = bno.getQuat();

    Euler = quaternion.toEuler();
    Euler = Euler.scale(100);

    int hue = 0;
    hue += map(Euler[0], -314, 314, 0, 360);

    hue += map(Euler[1], -314 / 2, 314 / 2, 0, 360);

    hue += map(Euler[2], -314, 314, 0, 360);

    hue = hue % 360;

    int colors[3];
    hsv2rgb(hue, 255, 255, colors);
    RGBValues[0] = colors[0];
    RGBValues[1] = colors[1];
    RGBValues[2] = colors[2];
    analogWrite(REDPIN, RGBValues[0]);
    analogWrite(GREENPIN, RGBValues[1]);
    analogWrite(BLUEPIN, RGBValues[2]);
    Serial.print("X");
    Serial.print(Euler[0], 3);
    Serial.print("Y");
    Serial.print(Euler[1], 3);
    Serial.print("Z");
    Serial.print(Euler[2], 3);
    Serial.print("R");
    Serial.print((int)RGBValues[0]);
    Serial.print("G");
    Serial.print((int)RGBValues[1]);
    Serial.print("B");
    Serial.print((int)RGBValues[2]);
    Serial.println("|");

    bno_timer = current_timer;
  }

  if ((current_timer - ble_timer) >= BLE_SAMPLERATE_DELAY_MS) {
    if (ble.isConnected()) {
      ble.print("AT+BLEUARTTX=");
      ble.print("X");
      ble.print(Euler[0], 3);
      ble.print("Y");
      ble.print(Euler[1], 3);
      ble.print("Z");
      ble.print(Euler[2], 3);
      ble.println("|");
      ble.readline(200);
    }

    ble_timer = current_timer;
  }

}
