module State exposing (Bumper(..), Claw(..), Front(..), State, TravelDirection(..), init, update)

import Curvature
import LightCalibration
import Robot exposing (Input)


type TravelDirection
    = Clockwise
    | CounterClockwise


type Claw
    = ClawOpen
    | ClawClosed


type Bumper
    = BumperPressed
    | BumperUnpressed


type Front
    = Blocked
    | Unblocked


type alias State =
    { front : Front
    , bumper : Bumper
    , claw : Claw
    , curvature : Curvature.State
    , travelDirection : Maybe TravelDirection
    , lightCalibration : LightCalibration.Parameters
    }


init : State
init =
    { front = Blocked
    , bumper = BumperUnpressed
    , claw = ClawOpen
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
    in
    { state
        | front = front
        , bumper = bumper
        , curvature = state.curvature |> Curvature.update { left = input.leftMotor, right = input.rightMotor }
        , lightCalibration = lightCalibration
    }
