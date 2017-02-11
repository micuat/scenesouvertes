import serial
from time import sleep

ser = serial.Serial('/dev/ttyACM0',19200)
print(ser.name)

angle = 0

while True:
  if angle < 1000:
    ser.write(str(angle + 1000) + '\n')
  else:
    ser.write(str(3000 - angle) + '\n')
  angle = (angle + 10) % 2000
  sleep(1 / 30.0)
ser.close()

