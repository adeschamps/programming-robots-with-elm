module Sorter exposing (main)

import Action exposing (Action)
import Curvature
import Goal exposing (Goal)
import InfluxDB
import Robot exposing (Input, Output, Robot)
import State exposing (State)


type alias Model =
    { state : State
    , action : Action
    , goal : Goal
    }


main : Robot Model
main =
    Robot.stateful
        { init = init
        , output = output
        , update = update
        , generateMetrics = Just metrics
        }


init : Model
init =
    { state = State.init
    , action = Action.idle
    , goal = Goal.init
    }


output : Model -> Input -> Output
output { action, state } input =
    input |> Action.output action state


update : Input -> Model -> Model
update input { state, goal, action } =
    let
        -- Perception
        newState =
            State.update input state

        -- Control
        newAction =
            Action.update newState action

        -- Behaviour
        ( newGoal, maybeAction ) =
            Goal.update newState newAction goal
    in
    { state = newState
    , goal = newGoal
    , action = maybeAction |> Maybe.withDefault newAction
    }


metrics : Input -> { a | state : State } -> List InfluxDB.Datum
metrics input { state } =
    let
        boolToFloat b =
            if True then
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
        ++ Curvature.metrics state.curvature time
