#!/usr/bin/env node

const Elm = require("./robot.js").Elm;
const ev3 = require("ev3dev-lang");

const handleOutputs = function() {
  const leftMotor = new ev3.Motor(ev3.OUTPUT_A);
  const rightMotor = new ev3.Motor(ev3.OUTPUT_B);
  if (leftMotor.connected && rightMotor.connected) {
    // Control real robot
    return function(outputs) {
      leftMotor.start(outputs.leftMotor);
      rightMotor.start(outputs.rightMotor);
    };
  } else {
    // Mock outputs to console
    return function(outputs) {
      console.log(outputs.leftMotor);
      console.log(outputs.rightMotor);
      console.log();
    };
  }
}();

const updateInput = function() {
  const lightSensor = new ev3.LightSensor();
  const distanceSensor = new ev3.UltrasonicSensor();
  if (lightSensor.connected && distanceSensor.connected) {
    // Read real sensors
    return () => {
      app.ports.inputs.send({
        lightSensor : lightSensor.getValue(),
        distanceSensor : distanceSensor.getValue(),
      });
    };
  } else {
    // Mock inputs
    var time = 0.0;
    return () => {
      time += 1;
      brightness = Math.round(50 + 10 * Math.sin(time * 0.1));
      distance = 50 + (time % 40) - 20;
      app.ports.inputs.send({
        lightSensor : brightness,
        distanceSensor : distance,
      });
    };
  }
}();

var app = Elm.LineFollower.init();
app.ports.outputs.subscribe(handleOutputs);
setInterval(updateInput, 100);
