---
title: Programming Robots with Elm
author: Anthony Deschamps
date: September 26, 2018
---

# Introduction

## A deligtful language

## RoboFest

## LEGO Mindstorms

## EV3

## ev3dev

## Goal

- Can Elm be used to program a robot?
- Is it an _effective_ language for robotics?
- Is it a _delightful_ language for robotics?

# Robotics

## Three ares

- Perception
- Behaviour
- Control

# A simple robot

## A simple robot

- Don't crash into things
- Follow a line

## Don't crash into things

```haskell
type State
    = Blocked
    | Unblocked

update : Input -> State -> State
update input state =
    if input.distanceSensar < 50 then
        Blocked

    else
        Unblocked
```

## Follow the line

```haskell
output : Input -> State -> State
output input state =
    case state of
        Blocked ->
            { leftMotor = 0
            , rightMotor = 0
            }

        Unblocked ->
            { leftMotor = input.lightSensor
            , rightMotor = 1.0 - input.lightSensor
            }
```

# Programming robots in Elm

## A program for robots

```haskell
robot :
    { init : state
    , update : Input -> state -> state
    , output : state -> Input -> Output
    }
    -> Robot state
```

## Wiring it up

# Let's make it more challenging!

## The challenge

- Follow a line around a track
- Grab things that you bump into
- Move them to the _outside_ of the track

# Wrapping Up

##

Thank you!

![](https://avatars3.githubusercontent.com/u/30929018?s=200&v=4)
