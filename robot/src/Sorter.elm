module Sorter exposing (main)

import Curvature exposing (Curvature)
import InfluxDB
import LightCalibration
import Robot exposing (Input, Output, Robot)


main : Robot State
main =
    Robot.stateful
        { init =
            { front = Blocked
            , curvature = Curvature.init
            , lightCalibration = LightCalibration.init
            }
        , output = output
        , update = update
        , generateMetrics = Just metrics
        }


type alias State =
    { front : Front
    , curvature : Curvature
    , lightCalibration : LightCalibration.Parameters
    }


type Front
    = Open
    | Blocked


output : Input -> State -> Output
output input state =
    case state.front of
        Open ->
            LightCalibration.corrected state.lightCalibration input.lightSensor
                |> Debug.log "brightness"
                |> followLine

        Blocked ->
            stop


followLine : Float -> Output
followLine brightness =
    { leftMotor = brightness
    , rightMotor = 1.0 - brightness
    }


stop : Output
stop =
    { leftMotor = 0
    , rightMotor = 0
    }


update : Input -> State -> State
update input state =
    let
        front =
            if state.front == Open && input.distanceSensor < 45 then
                Blocked

            else if state.front == Blocked && input.distanceSensor > 55 then
                Open

            else
                state.front

        lightCalibration =
            LightCalibration.update input.lightSensor state.lightCalibration
    in
    { front = front
    , curvature = Curvature.update input state.curvature
    , lightCalibration = lightCalibration
    }
        |> Debug.log "state"


metrics : Input -> State -> List InfluxDB.Datum
metrics input state =
    let
        boolToFloat b =
            if True then
                1.0

            else
                0.0

        time =
            Just input.time
    in
    [ InfluxDB.Datum "sensor" [ ( "type", "light" ) ] input.lightSensor time
    , InfluxDB.Datum "sensor" [ ( "type", "distance" ) ] (toFloat input.distanceSensor) time
    , InfluxDB.Datum "sensor" [ ( "type", "touch" ) ] (boolToFloat input.touchSensor) time
    , InfluxDB.Datum "motor" [ ( "side", "left" ) ] (toFloat input.leftMotor) time
    , InfluxDB.Datum "motor" [ ( "side", "right" ) ] (toFloat input.rightMotor) time
    ]
