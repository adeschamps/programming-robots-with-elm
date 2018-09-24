module Perception exposing (Bumper(..), Front(..), Perception, TravelDirection(..), init, metrics, update)

import Claw
import Curvature
import InfluxDB
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


type alias Perception =
    { time : Int
    , claw : Claw.State
    , front : Front
    , bumper : Bumper
    , wheels : WheelOdometers
    , curvature : Curvature.State
    , travelDirection : Maybe TravelDirection
    , lightCalibration : LightCalibration.Parameters
    }


init : Perception
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


update : Input -> Perception -> Perception
update input perception =
    let
        claw =
            Claw.update input.clawMotor perception.claw

        front =
            if perception.front == Unblocked && input.distanceSensor < 45 then
                Blocked

            else if perception.front == Blocked && input.distanceSensor > 55 then
                Unblocked

            else
                perception.front

        bumper =
            if input.touchSensor then
                BumperPressed

            else
                BumperUnpressed

        lightCalibration =
            LightCalibration.update input.lightSensor perception.lightCalibration

        wheels =
            { left = input.leftMotor, right = input.rightMotor }

        curvature =
            Curvature.update wheels perception.curvature

        -- Travel direction is reset if the curvature becomes
        -- unknown. If we are going straight, then we maintain the
        -- last known curvature.
        travelDirection =
            case Curvature.curve curvature of
                Curvature.Unknown ->
                    Nothing

                Curvature.Straight ->
                    perception.travelDirection

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


metrics : Perception -> Maybe Int -> List InfluxDB.Datum
metrics perception time =
    Claw.metrics perception.claw time
        ++ Curvature.metrics perception.curvature time
