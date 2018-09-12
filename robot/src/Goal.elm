module Goal exposing (Goal(..), init, update)

import Action exposing (Action)
import Claw
import State exposing (Bumper(..), State)


type Goal
    = Initializing { openedClaw : Bool, closedClaw : Bool }
    | FindingObject
    | RemovingObject (List Action)


init : Goal
init =
    Initializing { openedClaw = False, closedClaw = False }


update : State -> Action -> Goal -> ( Goal, Maybe Action )
update state currentAction goal =
    case goal of
        Initializing context ->
            -- Before we begin, we open and close the claw so that the
            -- State module can determine its extreme positions.
            if Action.isIdle currentAction then
                if not context.closedClaw then
                    ( Initializing { context | closedClaw = True }, Just Action.grab )

                else if not context.openedClaw then
                    ( Initializing { context | openedClaw = True }, Just Action.release )

                else
                    findObject

            else
                ( goal, Nothing )

        FindingObject ->
            case ( Claw.position state.claw, state.bumper, state.travelDirection ) of
                ( Claw.Open, BumperPressed, _ ) ->
                    ( goal, Just Action.grab )

                ( Claw.Closed, _, Just travelDirection ) ->
                    removeObject travelDirection

                ( Claw.Closed, _, _ ) ->
                    if Action.isIdle currentAction then
                        ( goal, Just Action.followLine )

                    else
                        ( goal, Nothing )

                _ ->
                    ( goal, Nothing )

        RemovingObject actions ->
            case ( Action.isIdle currentAction, actions ) of
                ( True, nextAction :: remainingActions ) ->
                    ( RemovingObject remainingActions, Just nextAction )

                ( True, [] ) ->
                    findObject

                _ ->
                    ( goal, Nothing )


findObject : ( Goal, Maybe Action )
findObject =
    ( FindingObject, Just Action.followLine )


removeObject : State.TravelDirection -> ( Goal, Maybe Action )
removeObject direction =
    ( RemovingObject (removeActions direction), Just Action.idle )


removeActions : State.TravelDirection -> List Action
removeActions direction =
    let
        turnLeft =
            Action.moveBy { leftDelta = -180, rightDelta = 180 }

        turnRight =
            Action.moveBy { leftDelta = 180, rightDelta = -180 }

        ( turn, turnBack ) =
            case direction of
                State.Clockwise ->
                    ( turnLeft, turnRight )

                State.CounterClockwise ->
                    ( turnRight, turnLeft )

        forward =
            Action.moveBy { leftDelta = 360, rightDelta = 360 }

        reverse =
            Action.moveBy { leftDelta = -360, rightDelta = -360 }

        release =
            Action.release
    in
    [ turn
    , forward
    , release
    , reverse
    , turnBack
    ]
