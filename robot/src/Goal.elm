module Goal exposing (Goal(..), init, update)

import Action exposing (Action)
import State exposing (Bumper(..), Claw(..), State)


type Goal
    = Initializing
    | FindingObject
    | RemovingObject (List Action)


type Direction
    = Left
    | Right


init : Goal
init =
    Initializing


update : State -> Action -> Goal -> ( Goal, Maybe Action )
update state currentAction goal =
    case goal of
        Initializing ->
            findObject

        FindingObject ->
            case ( state.claw, state.bumper, state.travelDirection ) of
                ( ClawOpen, BumperPressed, _ ) ->
                    ( goal, Just Action.Grab )

                ( ClawClosed, _, Just travelDirection ) ->
                    removeObject travelDirection

                ( ClawClosed, _, _ ) ->
                    if currentAction == Action.Idle then
                        ( goal, Just Action.FollowLine )

                    else
                        ( goal, Nothing )

                _ ->
                    ( goal, Nothing )

        RemovingObject actions ->
            case ( currentAction, actions ) of
                ( Action.Idle, nextAction :: remainingActions ) ->
                    ( RemovingObject remainingActions, Just nextAction )

                ( Action.Idle, [] ) ->
                    findObject

                _ ->
                    ( goal, Nothing )


findObject : ( Goal, Maybe Action )
findObject =
    ( FindingObject, Just Action.FollowLine )


removeObject : State.TravelDirection -> ( Goal, Maybe Action )
removeObject direction =
    ( RemovingObject (removeActions direction), Just Action.Idle )


removeActions : State.TravelDirection -> List Action
removeActions direction =
    let
        turnLeft =
            Action.MoveBy { leftDelta = -1, rightDelta = 1 }

        turnRight =
            Action.MoveBy { leftDelta = 1, rightDelta = -1 }

        ( turn, turnBack ) =
            case direction of
                State.Clockwise ->
                    ( turnLeft, turnRight )

                State.CounterClockwise ->
                    ( turnRight, turnLeft )

        forward =
            Action.MoveBy { leftDelta = 1, rightDelta = 1 }

        reverse =
            Action.MoveBy { leftDelta = -1, rightDelta = -1 }

        release =
            Action.Release
    in
    [ turn
    , forward
    , release
    , reverse
    , turnBack
    ]
