var noble = require('noble');
var osc = require('node-osc');

var client = new osc.Client('10.10.30.109', 7000);

var uartServices = [];
var uartReadCharacteristics = ["6e400003b5a3f393e0a9e50e24dcca9e"];

noble.on('stateChange', function(state) {
  if(state === 'poweredOn') {
    var allowDuplicates = true;
    setInterval(function() {
      console.log('start scanning');
      noble.startScanning(["6e400001b5a3f393e0a9e50e24dcca9e"], allowDuplicates);
      setTimeout(function() {
        noble.stopScanning();
      }, 1 * 1000);
    }, 2 * 1000);
  } else {
    console.log('stop scanning');
    noble.stopScanning();
  }
});

var currentPeripheral = null;

noble.on('discover', function(peripheral) {
  if(currentPeripheral != null) {
    return;
  }

  peripheral.connect(function(error) {
    console.log("connected to: " + peripheral.id + " " + peripheral.address + " " + peripheral.localName);

    peripheral.removeAllListeners('disconnect');
    peripheral.on('disconnect', function() {
      console.log("disconnected from: " + peripheral.id);
    });

    peripheral.discoverSomeServicesAndCharacteristics(uartServices, uartReadCharacteristics, function(error, services, characteristics){
      if(characteristics.length == 0) {
        peripheral.disconnect();
      }

      peripheral.removeAllListeners('disconnect');
      peripheral.on('disconnect', function() {
        console.log("disconnected from peripheral with UART: " + peripheral.id);
        currentPeripheral = null;
      });

      currentPeripheral = peripheral.id;
      console.log("UART characteristic found on: " + currentPeripheral);

      characteristics.forEach(function(ch, chId) {

        ch.removeAllListeners('data');
        ch.on('data', function(data) {
          var eulersString = data.toString().slice(0, -2);
          var eulers = data.toString().split(",");
          if(eulers.length == 3) {
            var e0 = parseFloat(eulers[0]);
            var e1 = parseFloat(eulers[1]);
            var e2 = parseFloat(eulers[2]);
            console.log(e0 + " " + e1 + " " + e2);
            client.send('/scenes/cube', e0, e1, e2, function (error) {
            });
          }
        });
        ch.notify(true);
      });
    });
  });
});
