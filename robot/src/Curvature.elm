module Curvature exposing (Curve(..), Inputs, State, curve, init, lights, metrics, update)

import InfluxDB
import Lights
import Robot exposing (BrickLights)


type Curve
    = Straight
    | Left
    | Right


type State
    = State
        { previous : Maybe Inputs
        , curve : Curve
        , instant : Float
        , average_0_5 : Float
        , average_1_0 : Float
        , average_2_0 : Float
        }


type alias Inputs =
    { left : Int
    , right : Int
    }


init : State
init =
    State
        { previous = Nothing
        , curve = Straight
        , instant = 0.0
        , average_0_5 = 0.0
        , average_1_0 = 0.0
        , average_2_0 = 0.0
        }


curve : State -> Curve
curve (State state) =
    state.curve


update : Inputs -> State -> State
update current (State state) =
    let
        -- If we don't have a previous measurement, then use the
        -- current one. It is as if we haven't moved.
        previous =
            state.previous |> Maybe.withDefault current

        deltaLeft =
            toFloat (current.left - previous.left) / 360

        deltaRight =
            toFloat (current.right - previous.right) / 360

        delta =
            deltaLeft - deltaRight

        totalTravel =
            deltaLeft + deltaRight

        instant =
            if totalTravel > 0 then
                delta / totalTravel

            else
                0.0

        average_0_5 =
            let
                alpha =
                    1.0 - e ^ (-totalTravel / 0.5)
            in
            state.average_0_5 * (1 - alpha) + instant * alpha

        average_1_0 =
            let
                alpha =
                    1.0 - e ^ (-totalTravel / 1.0)
            in
            state.average_1_0 * (1 - alpha) + instant * alpha

        average_2_0 =
            let
                alpha =
                    1.0 - e ^ (-totalTravel / 2.0)
            in
            state.average_2_0 * (1 - alpha) + instant * alpha

        curve =
            calculateCurve average_1_0 state.curve
    in
    State
        { previous = Just current
        , curve = curve
        , instant = instant
        , average_0_5 = average_0_5
        , average_1_0 = average_1_0
        , average_2_0 = average_2_0
        }


calculateCurve : Float -> Curve -> Curve
calculateCurve curvature current =
    case current of
        Left ->
            if curvature > -0.2 then
                Straight

            else
                current

        Straight ->
            if curvature < -0.25 then
                Left

            else if curvature > 0.25 then
                Right

            else
                current

        Right ->
            if curvature < 0.2 then
                Straight

            else
                current


metrics : State -> Maybe Int -> List InfluxDB.Datum
metrics (State state) time =
    [ InfluxDB.Datum "curve" [ ( "window", "instant" ) ] state.instant time
    , InfluxDB.Datum "curve" [ ( "window", "0_5_turns" ) ] state.average_0_5 time
    , InfluxDB.Datum "curve" [ ( "window", "1_0_turns" ) ] state.average_1_0 time
    , InfluxDB.Datum "curve" [ ( "window", "2_0_turns" ) ] state.average_2_0 time
    ]


{-| Set the brick lights to indicate the direction of the detected
curvature. Left/right are reversed, since they are labeled as if you
are looking at the front of the robot.
-}
lights : State -> BrickLights
lights (State { curve }) =
    case curve of
        Left ->
            { left = Lights.off, right = Lights.green }

        Straight ->
            { left = Lights.green, right = Lights.green }

        Right ->
            { left = Lights.green, right = Lights.off }
