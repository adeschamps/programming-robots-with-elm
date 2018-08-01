#!/usr/bin/env node

const Elm = require("./robot.js").Elm;
const ev3 = require("ev3dev-lang");

const rightMotor = new ev3.Motor(ev3.OUTPUT_B);
const leftMotor = new ev3.Motor(ev3.OUTPUT_C);
const lightSensor = new ev3.LightSensor();
const distanceSensor = new ev3.UltrasonicSensor();

function handleOutputs(outputs) {
  console.log(outputs);
  leftMotor.start(Math.round(100 * outputs.leftMotor));
  rightMotor.start(Math.round(100 * outputs.rightMotor));
}

function updateInput() {
  const inputs = {
    lightSensor : lightSensor.reflectedLightIntensity,
    distanceSensor : distanceSensor.distanceCentimiters || 255,
    touchSensor : false,
    leftMotor : leftMotor.position,
    rightMotor : rightMotor.position,
    clawMotor : 0,
    time : Date.now(),
  };
  console.log(inputs);
  app.ports.inputs.send(inputs);
}

const flags = {
  influxDB : {server : "localhost", database : "ev3"}
};
console.log(flags);
var app = Elm.Sorter.init(flags);
app.ports.outputs.subscribe(handleOutputs);
setInterval(updateInput, 25);
