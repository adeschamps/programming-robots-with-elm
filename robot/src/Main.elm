module Sorter exposing (main)

import Action exposing (Action)
import Curvature
import InfluxDB
import LightCalibration
import Lights
import Robot exposing (Input, Output, Robot)
import State exposing (Bumper(..), Claw(..), Front(..), State, TravelDirection(..))


main : Robot { state : State, goal : Goal }
main =
    Robot.stateful
        { init = init
        , output = output
        , update = update
        , generateMetrics = Just metrics
        }


init : { state : State, goal : Goal }
init =
    { state = State.init
    , goal = Initialize
    }


type Direction
    = Left
    | Right


type Goal
    = Initialize
    | FollowLine
    | GrabObject
    | MoveObject Direction
    | Sequence (List Action) Goal


output : Input -> { goal : Goal, state : State } -> Output
output input { state, goal } =
    case goal of
        Initialize ->
            stop

        FollowLine ->
            case state.front of
                Blocked ->
                    stop

                Unblocked ->
                    LightCalibration.corrected state.lightCalibration input.lightSensor
                        |> followLine
                        |> (\o -> { o | lights = Just (Curvature.lights state.curvature) })

        GrabObject ->
            closeClaw

        MoveObject _ ->
            stop

        Sequence (action :: remainingActions) _ ->
            Action.output input action

        Sequence [] _ ->
            error


followLine : Float -> Output
followLine brightness =
    { leftMotor = brightness
    , rightMotor = 1.0 - brightness
    , clawMotor = 0.0
    , lights = Nothing
    }


closeClaw : Output
closeClaw =
    { leftMotor = 0.0
    , rightMotor = 0.0
    , clawMotor = 1.0
    , lights = Nothing
    }


stop : Output
stop =
    { leftMotor = 0.0
    , rightMotor = 0.0
    , clawMotor = 0.0
    , lights = Just { left = Lights.green, right = Lights.green }
    }


error : Output
error =
    { leftMotor = 0.0
    , rightMotor = 0.0
    , clawMotor = 0.0
    , lights = Just { left = Lights.red, right = Lights.red }
    }


update : Input -> { state : State, goal : Goal } -> { state : State, goal : Goal }
update input { state, goal } =
    let
        -- Perception
        newState =
            State.update input state

        -- Behaviour
        newGoal =
            updateGoal newState goal
    in
    { state = newState, goal = newGoal }


updateGoal : State -> Goal -> Goal
updateGoal state goal =
    case goal of
        Initialize ->
            FollowLine

        FollowLine ->
            case ( state.claw, state.bumper, state.travelDirection ) of
                ( ClawOpen, BumperPressed, _ ) ->
                    GrabObject

                ( ClawClosed, _, Just travelDirection ) ->
                    MoveObject <| depositSide travelDirection

                _ ->
                    goal

        GrabObject ->
            if state.claw == ClawClosed then
                FollowLine

            else
                goal

        MoveObject direction ->
            let
                actions =
                    []
            in
            Sequence actions FollowLine

        Sequence [] nextGoal ->
            nextGoal

        Sequence (action :: remaining) _ ->
            goal


depositSide : TravelDirection -> Direction
depositSide travel =
    case travel of
        Clockwise ->
            Left

        CounterClockwise ->
            Right


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
