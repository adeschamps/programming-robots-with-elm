#!/usr/bin/env node

const Elm = require("./robot.js");
const ev3 = require("ev3dev-lang");
global.XMLHttpRequest = require("xhr2");

const rightMotor = new ev3.Motor(ev3.OUTPUT_B);
const leftMotor = new ev3.Motor(ev3.OUTPUT_C);
const lightSensor = new ev3.LightSensor();
const distanceSensor = new ev3.UltrasonicSensor();
const touchSensor = new ev3.TouchSensor();

// This constant is used to map speeds in the range [-1.0, 1.0] to actual outputs.
const SPEED = 100;

process.on("SIGINT", function() {
  console.log("Stopping...");
  leftMotor.start(0);
  rightMotor.start(0);
  process.exit(0);
});

function handleOutputs(outputs) {
  leftMotor.start(Math.round(SPEED * outputs.leftMotor));
  rightMotor.start(Math.round(SPEED * outputs.rightMotor));
  // Handling lights seems to introduce a very long delay in the update loop.
  // const lights = outputs.lights;
  // if (lights) {
  //   ev3.Ev3Leds.left.setColor([ lights.left.red, lights.left.green ])
  //   ev3.Ev3Leds.right.setColor([ lights.right.red, lights.right.green ])
  // }
}

function updateInput() {
  const inputs = {
    lightSensor : lightSensor.reflectedLightIntensity,
    distanceSensor : 255, // distanceSensor.distanceCentimeters || 255,
    touchSensor : touchSensor.isPressed,
    leftMotor : leftMotor.position,
    rightMotor : rightMotor.position,
    clawMotor : 0,
    time : Date.now(),
  };
  app.ports.inputs.send(inputs);
}

const flags = {
  influxDB : {server : "http://192.168.86.33:8086", database : "ev3"},
  influxPeriod : 1000
};
console.log(flags);
var app = Elm.Sorter.worker(flags);
app.ports.outputs.subscribe(handleOutputs);
setInterval(updateInput, 25);
