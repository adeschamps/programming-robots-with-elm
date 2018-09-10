module Claw exposing (Claw(..), State, init, position, update)


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

        midpoint =
            min_ + (max_ - min_) // 2

        position =
            if delta < 70 then
                Uninitialized

            else if motorPosition > midpoint then
                Open

            else
                Closed
    in
    State
        { position = position
        , min = Just min_
        , max = Just max_
        }
