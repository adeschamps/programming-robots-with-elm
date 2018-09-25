---
title: Programming Robots with Elm
author: Anthony Deschamps
date: September 26, 2018
---

## A delightful language

![](./img/elm-homepage.png)

## {data-background-image="./img/robofest.jpg"}

##

![](./img/robofest-bots.jpg)

##

![](./img/ev3.jpg)

##

![](./img/ev3-programming.jpg)

## ev3dev

(all the hard work I didn't have to do)

A Debian distribution for LEGO Mindstorms with API bindings for C,
C++, Python, Go, JavaScript

<https://www.ev3dev.org/>

<https://github.com/ev3dev/ev3dev>

## Questions

- _Can_ Elm be used to program a robot?
- Is it an _effective_ language for robots?
- Is it a _delightful_ language for robots?

## Three areas of robotics

- Perception
- Behaviour
- Control

![](./img/robotics-stick-figure.jpg)

## Mapping to the Elm architecture

```haskell
Browser.sandbox :
    { init : model
    , update : msg -> model -> model
    , view : model -> Html msg
    }
    -> Program () model msg
```

## An Elm program for robots

```haskell
Robot.program :
    { init : state
    , update : Input -> state -> state
    , output : state -> Output
    }
    -> Robot state

type alias Input =
    { lightSensor : Float, {- ... -} }

type alias Output =
    { leftMotor : Float, rightMotor : Float, {- ... -} }
```

## A simple robot

- Follow a line
- Don't crash into things

## Don't crash into things

```haskell
type alias State = (Front, Float)

type Front = Blocked | Unblocked

update : Input -> State -> State
update input _ =
    let front =
        if input.distanceSensor < 50 then
            Blocked
        else
            Unblocked
    in
    (front, input.lightSensor)
```

## Follow a line

![](./img/line-following.jpg)

## Follow a line

```haskell
output : State -> State
output (front, lightSensor) input =
    case front of
        Blocked ->
            { leftMotor = 0
            , rightMotor = 0
            }

        Unblocked ->
            { leftMotor = lightSensor
            , rightMotor = 1.0 - lightSensor
            }
```

# Does it work?

# How does this work?

## Ports!

```haskell
port inputs : (Input -> msg) -> Sub msg

port outputs : Output -> Cmd msg
```

## Platform.worker

```haskell
type alias Config state =
    { init : state
    , update : Input -> state -> state
    , output : state -> Output
    }

program : Config state -> Robot state
program config =
    Platform.worker
        { init = \_ -> ( { state = config.init }, Cmd.none )
        , update = update config
        , subscriptions = \_ -> inputs NewInput
        }
```

## Wiring in Elm

```haskell
update : Config -> Msg -> Model -> ( Model, Cmd Msg )
update config msg model =
    case msg of
        NewInput input ->
            let
                newState =
                    config.update input model.state

                output =
                    config.output newState

            in
            ( { model | state = newState }, outputs output )
```

## Wiring in JavaScript

```js
function updateInput() {
  app.ports.inputs.send({
    lightSensor : lightSensor.reflectedLightIntensity,
    // ...
  });
}
function handleOutputs(outputs) {
  leftMotor.start(Math.round(SPEED * outputs.leftMotor));
  // ...
}
var app = Elm.Main.init();
app.ports.outputs.subscribe(handleOutputs);
setInterval(updateInput, 25);
```

## It's that simple!

# Let's make it more challenging!

## The challenge

- Follow a line around a track
- Grab things that you bump into
- Move them to the _outside_ of the track

## The model

```haskell
type alias Model =
    { perception : Perception
    , behaviour : Behaviour
    , control : Control
    }

init : Model
init =
    { perception = Perception.init
    , behaviour = Behaviour.init
    , control = Control.init
    }
```

##

![](./img/dataflow.jpg)

## Main update

```{.haskell}
update input { perception, behaviour, control } =
   let
      -- Perception
      newPerception =
          Perception.update input perception

      -- Control
      newControl =
          Control.update newPerception control

      -- Behaviour
      ( newBehaviour, maybeControl ) =
         Behaviour.update newPerception newControl behaviour
   in
   { perception = newPerception
   , behaviour = newBehaviour
   , control = maybeControl |> Maybe.withDefault newControl
   }
```

## Main output

```haskell
output : Model -> Output
output { perception, control } =
    Control.output control perception
```

## Perception turns raw data into meaningful information

## We need to detect...

- Have we encountered an obstacle?
- What direction are we going?

## Lots of things to measure

```haskell
module Perception

type alias Perception =
    { time : Int
    , claw : Claw.State
    , bumper : Bumper
    , wheels : WheelOdometers
    , curvature : Curvature.State
    , travelDirection : Maybe TravelDirection
    , lightSensor : Float
    }

update : Input -> Perception -> Perception
```

## Detecting obstacles

Just a boolean, but by a different name

```haskell
update : Input -> Perception -> Perception
update input perception =
    let
        bumper =
            if input.touchSensor then
                BumperPressed
            else
                BumperUnpressed
    in
    { bumper = bumper
    -- ...
    }
```

## Measure curvature

```haskell
module Curvature

type Curve = Unknown | Straight | Left | Right

type State
    = State
        { previous : Maybe { left : Int, right : Int }
        , curve : Curve
        , raw : Float
        , average : Float
        }
```

## Measure curvature

$$delta = \Delta_{left} - \Delta_{right}$$
$$totalTravel = \Delta_{left} + \Delta_{right}$$
$$raw = delta / totalTravel$$
$$average_n = \alpha \cdot raw + (1-\alpha) \cdot average_{n-1}$$

## Categorize curve

![](./img/curve-state-machine.jpg)

## Categorize curve

```haskell
calculateCurve : Float -> Curve -> Curve
calculateCurve curvature current =
    case current of
        Unknown ->
            if curvature > -0.2 && curvature < 0.2 then
                Straight
            else
                current
        Left ->
            if curvature > -0.2 then
                Straight
            else
                current
```

## Things go wrong!

```haskell
newCurve =
    calculateCurve average state.curve
    |> resetIfExtreme average

-- ...

resetIfExtreme : Float -> Curve -> Curve
resetIfExtreme curvature current =
    if abs curvature > 0.7 then
        Unknown

    else
        current
```

## Categorize direction

```haskell
type TravelDirection
    = Clockwise
    | CounterClockwise

type alias Perception =
    { curvature : Curvature.State
    , travelDirection : Maybe TravelDirection
    -- ...
    }
```

## Put it all together

```haskell
let
    wheels = { left = input.leftMotor
             , right = input.rightMotor }
    curvature = Curvature.update wheels perception.curvature
    travelDirection =
        case Curvature.curve curvature of
            Curvature.Unknown -> Nothing
            Curvature.Straight -> perception.travelDirection
            Curvature.Left -> Just CounterClockwise
            Curvature.Right -> Just Clockwise
in
{ travelDirection = travelDirection, -- ...
}
```

## Perception is...

- Often very functional
- Small state machines
- Sometimes math heavy

## Control makes things move

## Like a slightly stateful view function

```haskell
type alias Output =
    { leftMotor : Float
    , rightMotor : Float
    , clawMotor : Float
    }

-- module Control

update : Perception -> Control -> Control

output : Control -> Perception -> Output
```

## Control constrains the things the robot can do

```haskell
type Control
    = Idle
    | Grab Timer
    | Release Timer
    | FollowLine
    | MoveTo { left : Int, right : Int }
    | MoveBy { leftDelta : Int, rightDelta : Int }
```

## Some control is trivial

```haskell
idle : Control
idle = Idle

update : Perception -> Control -> Control
update perception control =
    case control of
        Idle ->
            control

output : Control -> Perception -> Input -> Output
output control perception input =
    case control of
        Idle ->
            { leftMotor = 0.0
            , rightMotor = 0.0
            , clawMotor = 0.0
            }
```

## Some control is stateless

```haskell
output : Control -> Perception -> Input -> Output
output control perception input =
    case control of
        FollowLine ->
            { leftMotor = perception.lightSensor
            , rightMotor = 1.0 - perception.lightSensor
            , clawMotor = 0.0
            , lights = Nothing
            }
```

## Some control is a bit stateful

```haskell
update : Perception -> Control -> Control
update perception control =
   case control of
      Grab Starting ->
         Grab (Since perception.time)

      Grab (Since startTime) ->
         if perception.time - startTime > grabDuration then
            Idle

         else
            control
```

## Some control uses state machines

```haskell
update : Perception -> Control -> Control
update perception control =
   case control of
      MoveBy { leftDelta, rightDelta } ->
         MoveTo
            { left = perception.wheels.left + leftDelta
            , right = perception.wheels.right + rightDelta
            }
      MoveTo { left, right } ->
         if within 5 left perception.wheels.left {-  -} then
            Idle
         else
            control
```

## Control is...

- Often very functional
- Small state machines
- Layered, sometimes realtime

## Behaviour is the core of your Elm application

##

![](./img/behaviour-state-machine.jpg)

## Behaviour is your model

```haskell
module Behaviour

type Behaviour
    = Initializing { openedClaw : Bool, closedClaw : Bool }
    | FindingObject
    | RemovingObject (List Control)
```

## Behaviour is your update function

```haskell
module Behaviour

update :
    Perception
    -> Control
    -> Behaviour
    -> ( Behaviour, Maybe Control )
update perception currentControl behaviour =
    -- ...
```

## To behaviour, control is like a message

```haskell
case behaviour of
   Initializing context ->
      if Control.isIdle currentControl then
         if not context.closedClaw then
            ( Initializing { context | closedClaw = True }
            , Just Control.grab )
         else if not context.openedClaw then
            ( Initializing { context | openedClaw = True }
            , Just Control.release )
         else
            findObject
      else
         ( behaviour, Nothing )
```

## Behaviour should be _readable_

```haskell
case behaviour of
    FindingObject ->
        case ( claw, bumper, travelDirection) of
            ( Claw.Open, BumperPressed, _ ) ->
                ( behaviour, Just Control.grab )

            ( Claw.Closed, _, Just travelDirection ) ->
                removeObject travelDirection

            ( Claw.Closed, _, _ ) ->
                ( behaviour, Just Control.followLine )
```

## Sequential actions are slightly awkward

When we find an obstacle, we need to...

- Grab it
- Turn
- Move forwards
- Let it go
- Move back
- Turn back

## Behaviours can require arguments

```haskell
removeObject : TravelDirection -> (Behaviour, Maybe Control)
removeObject direction =
   let
      turnLeft = Control.moveBy {- ... -}
      turnRight = Control.moveBy {- ... -}
      ( turn, turnBack ) =
         case direction of
            Clockwise -> ( turnLeft, turnRight )
            CounterClockwise -> ( turnRight, turnLeft )
      -- ...
      actions = [ turn, forward, release, reverse, turnBack ]
   in
   ( RemovingObject actions, Just Control.idle )
```

## We need feedback from control

```haskell
update perception currentControl behaviour =
   case behaviour of
      RemovingObject controls ->
         case ( Control.isIdle currentControl, controls ) of
            ( True, next :: remaining ) ->
               ( RemovingObject remaining, Just next )

            ( True, [] ) ->
               findObject

            ( False, _ ) ->
               ( behaviour, Nothing )
```

## Behaviour is...

- Stateful
- Symbolic
- Explainable

# Does it work?

# Wrapping Up

## Can Elm be used to program a robot?

Yes!

## Is it effective?

- Is Elm an effective _platform_?
- Is Elm an effective _language_?

## Is it delightful?

I think so!

Decide for yourself!

<https://github.com/adeschamps/programming-robots-with-elm/>

## Thank you!

Matt Griffith

Mike Onslow + Elm Detroit

<https://www.meetup.com/elm-detroit/>

![](./img/elm-detroit.jpg)
