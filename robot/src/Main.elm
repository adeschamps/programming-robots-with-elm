module Main exposing (main)

import Behaviour exposing (Behaviour)
import Control exposing (Control)
import Curvature
import InfluxDB
import Perception exposing (Perception)
import Robot exposing (Input, Output, Robot)


type alias Model =
    { perception : Perception
    , behaviour : Behaviour
    , control : Control
    }


main : Robot Model
main =
    Robot.program
        { init = init
        , update = update
        , output = output
        , generateMetrics = Just metrics
        }


init : Model
init =
    { perception = Perception.init
    , behaviour = Behaviour.init
    , control = Control.idle
    }


output : Model -> Output
output { perception, control } =
    Control.output control perception


update : Input -> Model -> Model
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


metrics : Input -> Model -> List InfluxDB.Datum
metrics input { perception, behaviour } =
    let
        boolToFloat b =
            if b then
                1.0

            else
                0.0

        time =
            Just (input.time * 1000000)
    in
    [ InfluxDB.Datum "sensor" [ ( "type", "light" ) ] input.lightSensor time
    , InfluxDB.Datum "sensor" [ ( "type", "distance" ) ] (toFloat input.distanceSensor) time
    , InfluxDB.Datum "sensor" [ ( "type", "touch" ) ] (boolToFloat input.touchSensor) time
    ]
        ++ Curvature.metrics perception.curvature time
        ++ Perception.metrics perception time
        ++ Behaviour.metrics behaviour time
