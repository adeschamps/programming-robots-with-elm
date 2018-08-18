module Curvature exposing (Inputs, State, init, metrics, update)

import InfluxDB


type Curve
    = Straight
    | Left
    | Right


type State
    = State
        { previous : Maybe Inputs
        , curve : Curve
        , instant : Float
        , average_1 : Float
        , average_3 : Float
        , average_5 : Float
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
        , average_1 = 0.0
        , average_3 = 0.0
        , average_5 = 0.0
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

        average_1 =
            let
                alpha =
                    1.0 - e ^ (-totalTravel / 1.0)
            in
            state.average_1 * (1 - alpha) + instant * alpha

        average_3 =
            let
                alpha =
                    1.0 - e ^ (-totalTravel / 3.0)
            in
            state.average_3 * (1 - alpha) + instant * alpha

        average_5 =
            let
                alpha =
                    1.0 - e ^ (-totalTravel / 5.0)
            in
            state.average_5 * (1 - alpha) + instant * alpha

        curve =
            calculateCurve average_5 state.curve
    in
    State
        { previous = Just current
        , curve = curve
        , instant = instant
        , average_1 = average_1
        , average_3 = average_3
        , average_5 = average_5
        }


calculateCurve : Float -> Curve -> Curve
calculateCurve curvature current =
    Straight


metrics : State -> Maybe Int -> List InfluxDB.Datum
metrics (State state) time =
    [ InfluxDB.Datum "curve" [ ( "window", "instant" ) ] state.instant time
    , InfluxDB.Datum "curve" [ ( "window", "1_turns" ) ] state.average_1 time
    , InfluxDB.Datum "curve" [ ( "window", "3_turns" ) ] state.average_3 time
    , InfluxDB.Datum "curve" [ ( "window", "5_turns" ) ] state.average_5 time
    ]
