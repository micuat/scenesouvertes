var noble = require('noble');
var osc = require('node-osc');

var client = new osc.Client('10.10.30.109', 7000);

var uartServices = [];
var uartReadCharacteristics = ["6e400003b5a3f393e0a9e50e24dcca9e"];

noble.on('stateChange', function(state) {
  if(state === 'poweredOn') {
    noble.startScanning(["6e400001b5a3f393e0a9e50e24dcca9e"]);
    console.log('start');
  } else {
    noble.stopScanning();
    console.log('stop');
  }
});


noble.on('discover', function(peripheral) {
  peripheral.connect(function(error) {
    peripheral.discoverSomeServicesAndCharacteristics(uartServices, uartReadCharacteristics, function(error, services, characteristics){
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
