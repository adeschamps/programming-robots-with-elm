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
