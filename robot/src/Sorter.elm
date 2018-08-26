module Sorter exposing (main)

import Curvature
import InfluxDB
import LightCalibration
import Robot exposing (Input, Output, Robot)


type alias State =
    { front : Front
    , bumper : Bumper
    , claw : Claw
    , curvature : Curvature.State
    , lightCalibration : LightCalibration.Parameters
    }


main : Robot { state : State, goal : Goal }
main =
    Robot.stateful
        { init =
            { state =
                { front = Blocked
                , bumper = BumperUnpressed
                , claw = ClawOpen
                , curvature = Curvature.init
                , lightCalibration = LightCalibration.init
                }
            , goal = Initialize
            }
        , output = output
        , update = update
        , generateMetrics = Just metrics
        }


type Goal
    = Initialize
    | Search
    | GrabObject
    | TurnAround
    | DropObject


type Front
    = Blocked
    | Unblocked


type Bumper
    = BumperPressed
    | BumperUnpressed


type Claw
    = ClawOpen
    | ClawClosed


output : Input -> { goal : Goal, state : State } -> Output
output input { state, goal } =
    case goal of
        Initialize ->
            stop

        Search ->
            case state.front of
                Blocked ->
                    stop

                Unblocked ->
                    LightCalibration.corrected state.lightCalibration input.lightSensor
                        |> followLine
                        |> (\o -> { o | lights = Just (curvatureLights state.curvature) })

        GrabObject ->
            stop

        TurnAround ->
            stop

        DropObject ->
            stop


followLine : Float -> Output
followLine brightness =
    { leftMotor = brightness
    , rightMotor = 1.0 - brightness
    , lights = Nothing
    }


stop : Output
stop =
    { leftMotor = 0
    , rightMotor = 0
    , lights = Just { left = { red = 1, green = 0 }, right = { red = 1, green = 0 } }
    }


{-| Set the brick lights to indicate the direction of the detected
curvature. Left/right are reversed, since they are labeled as if you
are looking at the front of the robot.
-}
curvatureLights : Curvature.State -> Robot.BrickLights
curvatureLights state =
    case Curvature.curve state of
        Curvature.Left ->
            { left = { green = 0, red = 0 }, right = { green = 1, red = 0 } }

        Curvature.Straight ->
            { left = { green = 1, red = 0 }, right = { green = 1, red = 0 } }

        Curvature.Right ->
            { left = { green = 1, red = 0 }, right = { green = 0, red = 0 } }


update : Input -> { state : State, goal : Goal } -> { state : State, goal : Goal }
update input { state, goal } =
    let
        newState =
            updateState input state

        newGoal =
            updateGoal newState goal
    in
    { state = newState, goal = newGoal }


updateState : Input -> State -> State
updateState input state =
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


updateGoal : State -> Goal -> Goal
updateGoal state goal =
    case goal of
        Initialize ->
            Search

        Search ->
            if state.bumper == BumperPressed then
                GrabObject

            else
                goal

        GrabObject ->
            if state.claw == ClawClosed then
                TurnAround

            else
                goal

        TurnAround ->
            DropObject

        DropObject ->
            if state.claw == ClawOpen then
                Search

            else
                goal


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
    , InfluxDB.Datum "motor" [ ( "side", "left" ) ] (toFloat input.leftMotor) time
    , InfluxDB.Datum "motor" [ ( "side", "right" ) ] (toFloat input.rightMotor) time
    ]
        ++ Curvature.metrics state.curvature time
