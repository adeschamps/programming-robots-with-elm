module Claw exposing (Claw(..), State, init, metrics, position, update)

import InfluxDB


type Claw
    = Uninitialized
    | Open
    | Closed


type State
    = State
        { position : Claw
        , min : Maybe Int
        , max : Maybe Int
        }


init : State
init =
    State
        { position = Open
        , min = Nothing
        , max = Nothing
        }


position : State -> Claw
position (State { position }) =
    position


update : Int -> State -> State
update motorPosition (State state) =
    let
        min_ =
            state.min |> Maybe.withDefault motorPosition |> min motorPosition

        max_ =
            state.max |> Maybe.withDefault motorPosition |> max motorPosition

        delta =
            max_ - min_

        quarterDelta =
            delta // 4

        closedThreshold =
            min_ + 1 * quarterDelta

        openThreshold =
            min_ + 3 * quarterDelta

        position =
            if delta < 70 then
                Uninitialized

            else if motorPosition > openThreshold then
                Open

            else if motorPosition < closedThreshold then
                Closed

            else
                state.position
    in
    State
        { position = position
        , min = Just min_
        , max = Just max_
        }


metrics : State -> Maybe Int -> List InfluxDB.Datum
metrics (State state) time =
    let
        positionString =
            case state.position of
                Uninitialized ->
                    "uninitialized"

                Open ->
                    "open"

                Closed ->
                    "closed"
    in
    [ InfluxDB.Datum "claw" [ ( "group", "params" ), ( "param", "min" ) ] (state.min |> Maybe.withDefault 0 |> toFloat) time
    , InfluxDB.Datum "claw" [ ( "group", "params" ), ( "param", "max" ) ] (state.max |> Maybe.withDefault 0 |> toFloat) time
    , InfluxDB.Datum "claw" [ ( "group", "position" ), ( "position", positionString ) ] 1 time
    ]
