module Claw exposing (Claw(..), State, init, update)


type Claw
    = Uninitialized
    | Open
    | Closed
    | Opening { since : Int }
    | Closing { since : Int }


type alias State =
    { claw : Claw
    , previous : Maybe Int
    }


init : State
init =
    { claw = Uninitialized
    , previous = Nothing
    }


update : { a | clawPosition : Int, time : Int } -> State -> State
update { clawPosition } state =
    let
        previous =
            state.previous |> Maybe.withDefault clawPosition

        delta =
            clawPosition - previous

        claw =
            state.claw
    in
    { state
        | claw = claw
        , previous = Just clawPosition
    }
