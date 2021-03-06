################################################################################
#
# Bare Conductive Pi Cap
# ----------------------
#
# datastream-osc.py - streams capacitive sense data from MPR121 to OSC endpoint
#
# Written for Raspberry Pi.
#
# Bare Conductive code written by Szymon Kaliski.
#
# This work is licensed under a MIT license https://opensource.org/licenses/MIT
#
# Copyright (c) 2016, Bare Conductive
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#
#################################################################################

from time import sleep
import signal, sys, getopt, liblo, MPR121

success = 0
while success == 0:
  try:
    sensor = MPR121.begin()
    success = 1
  except Exception as e:
    print e
    sleep(5)
    #sys.exit(1)

# how many electrodes we have
electrodes_range = range(12)

# this is the touch threshold - setting it low makes it more like a proximity trigger default value is 40 for touch
touch_threshold = 40

# this is the release threshold - must ALWAYS be smaller than the touch threshold default value is 20 for touch
release_threshold = 20

# set the thresholds
sensor.set_touch_threshold(touch_threshold)
sensor.set_release_threshold(release_threshold)

# OSC address
host = "127.0.0.1"
port = 3000

# handle ctrl+c gracefully
def signal_handler(signal, frame):
  sys.exit(0)

signal.signal(signal.SIGINT, signal_handler)

# print help
def print_help():
  print "Sends Pi Cap readings through OSC - MUST be run as root.\n"
  print "Usage: python datastream-osc.py [OPTIONS]\n"
  print "Options:"
  print "  -h, --host   host address, defaults to 127.0.0.1"
  print "  -p, --port   port on which to send, defaults to 3000"
  print "      --help   displays this message"
  sys.exit(0)

# arguments parsing
def parse_args(argv):
  # we need to tell python that those variables are global
  # we don't want to create new local copies, but change global state
  global host, port

  try:
    opts, args = getopt.getopt(argv, "h:p:", [ "host=", "port=", "help" ])
  except getopt.GetoptError:
    print_help()

  for opt, arg in opts:
    if opt in ("-h", "--host"):
      host = arg
    elif opt in ("-p", "--port"):
      port = arg
    elif opt in ("--help"):
      print_help()

# parse arguments on start
parse_args(sys.argv[1:])

# setup OSC
address = liblo.Address(host, port)

touched = []
for i in electrodes_range:
  touched.append(False)

while True:
  bundle = liblo.Bundle()

  if sensor.touch_status_changed():
    sensor.update_touch_data()

  sensor.update_baseline_data()
  sensor.update_filtered_data()

  # touch values
  for i in electrodes_range:
    is_touched = sensor.get_touch_data(i)
    if touched[i] == False and is_touched:
      touch = liblo.Message("/live/play")
      print "touched: " + str(i)
      bundle.add(touch)
      touched[i] = True
    elif touched[i] == True and is_touched == False:
      touched[i] = False
  #print touched

  # touch thresholds
  #tths = liblo.Message("/tths")
  #for i in electrodes_range:
  #  tths.add(touch_threshold)
  #bundle.add(tths)

  # release threshold
  #rths = liblo.Message("/rths")
  #for i in electrodes_range:
  #  rths.add(release_threshold)
  #bundle.add(rths)

  # filtered values
  #fdat = liblo.Message("/fdat")
  #for i in electrodes_range:
  #  fdat.add(sensor.get_filtered_data(i))
  #bundle.add(fdat)

  # baseline values
  #bval = liblo.Message("/bval")
  #for i in electrodes_range:
  #  bval.add(sensor.get_baseline_data(i))
  #bundle.add(bval)

  # value pairs
  #diff = liblo.Message("/diff")
  #for i in electrodes_range:
  #  diff.add(sensor.get_baseline_data(i) - sensor.get_filtered_data(i))
  #bundle.add(diff)

  # send our bundle to given address
  liblo.send(address, bundle)

  # a little delay so that we don't just sit chewing CPU cycles
  sleep(1.0 / 30.0)
