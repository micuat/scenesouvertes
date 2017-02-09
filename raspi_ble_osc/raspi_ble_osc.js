var noble = require('noble');
var osc = require('node-osc');

var client = new osc.Client('10.10.30.109', 7000);

var uartServices = [];
var uartReadCharacteristics = ["6e400003b5a3f393e0a9e50e24dcca9e"];

var currentPeripheral = null;

noble.on('stateChange', function(state) {
  if(state === 'poweredOn') {
    var allowDuplicates = false;
    setInterval(function() {
      if(currentPeripheral != null) {
        return;
      }

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
        return;
      }
      if(currentPeripheral != null) {
        peripheral.disconnect();
        return;
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
        var databuf = '';
        ch.on('data', function(data) {
          databuf += data.toString();
          //console.log(databuf);

          var res = databuf.match(/X(-?\d+(\.\d+)?)Y(-?\d+(\.\d+))?Z(-?\d+(\.\d+))?\|(.*)/);
          if(res) {
            var e0 = parseFloat(res[1]);
            var e1 = parseFloat(res[3]);
            var e2 = parseFloat(res[5]);
            
            if(typeof res[7] != 'undefined')
              databuf = res[7];
            else
              databuf = '';

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
