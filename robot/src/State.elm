module State exposing (Bumper(..), Front(..), State, TravelDirection(..), init, update)

import Claw
import Curvature
import LightCalibration
import Robot exposing (Input)


type TravelDirection
    = Clockwise
    | CounterClockwise


type Bumper
    = BumperPressed
    | BumperUnpressed


type Front
    = Blocked
    | Unblocked


type alias WheelOdometers =
    { left : Int, right : Int }


type alias State =
    { front : Front
    , bumper : Bumper
    , claw : Claw.State
    , wheels : WheelOdometers
    , curvature : Curvature.State
    , travelDirection : Maybe TravelDirection
    , lightCalibration : LightCalibration.Parameters
    }


init : State
init =
    { front = Blocked
    , bumper = BumperUnpressed
    , claw = Claw.init
    , wheels = { left = 0, right = 0 }
    , curvature = Curvature.init
    , travelDirection = Nothing
    , lightCalibration = LightCalibration.init
    }


update : Input -> State -> State
update input state =
    let
        front =
            if state.front == Unblocked && input.distanceSensor < 45 then
                Blocked

            else if state.front == Blocked && input.distanceSensor > 55 then
                Unblocked

            else
                state.front

        bumper =
            if input.touchSensor then
                BumperPressed

            else
                BumperUnpressed

        lightCalibration =
            LightCalibration.update input.lightSensor state.lightCalibration

        wheels =
            { left = input.leftMotor, right = input.rightMotor }
    in
    { state
        | front = front
        , bumper = bumper
        , claw = state.claw |> Claw.update { clawPosition = input.clawMotor, time = input.time }
        , wheels = wheels
        , curvature = state.curvature |> Curvature.update wheels
        , lightCalibration = lightCalibration
    }
