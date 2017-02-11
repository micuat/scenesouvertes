from OSC import OSCServer, OSCClient, OSCMessage
import serial
from time import sleep

rot = 0

def rot_callback(path, tags, args, source):
  global rot
  rot = int(args[0])
def default_callback(path, tags, args, source):
  # do nothing
  return

osc_server = OSCServer( ("10.10.30.228", 12001) )
osc_server.timeout = 0
osc_server.addMsgHandler( "/orientation", rot_callback )
osc_server.addMsgHandler( "default", default_callback )

ser = serial.Serial('/dev/ttyACM0',19200)
print(ser.name)


def each_frame():
  ser.write(str(rot * 4 + 1500) + '\n')

  osc_server.handle_request()

try:
  while True:
    sleep(0.001)
    each_frame()
except KeyboardInterrupt:
  osc_server.close()
  ser.close()
finally:
  osc_server.close()
  ser.close()
