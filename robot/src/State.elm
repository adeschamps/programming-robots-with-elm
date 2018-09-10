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
    { left : Int
    , right : Int
    }


type alias State =
    { time : Int
    , claw : Claw.State
    , front : Front
    , bumper : Bumper
    , wheels : WheelOdometers
    , curvature : Curvature.State
    , travelDirection : Maybe TravelDirection
    , lightCalibration : LightCalibration.Parameters
    }


init : State
init =
    { time = 0
    , claw = Claw.init
    , front = Blocked
    , bumper = BumperUnpressed
    , wheels = { left = 0, right = 0 }
    , curvature = Curvature.init
    , travelDirection = Nothing
    , lightCalibration = LightCalibration.init
    }


update : Input -> State -> State
update input state =
    let
        claw =
            Claw.update input.clawMotor state.claw

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

        curvature =
            Curvature.update wheels state.curvature

        -- Travel direction is reset if the curvature becomes
        -- unknown. If we are going straight, then we maintain the
        -- last known curvature.
        travelDirection =
            case Curvature.curve curvature of
                Curvature.Unknown ->
                    Nothing

                Curvature.Straight ->
                    state.travelDirection

                Curvature.Left ->
                    Just CounterClockwise

                Curvature.Right ->
                    Just Clockwise
    in
    { time = input.time
    , claw = claw
    , front = front
    , bumper = bumper
    , wheels = wheels
    , curvature = curvature
    , lightCalibration = lightCalibration
    , travelDirection = travelDirection
    }
