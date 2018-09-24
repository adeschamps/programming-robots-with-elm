module Behaviour exposing (Behaviour(..), init, metrics, update)

import Claw
import Control exposing (Control)
import InfluxDB
import Perception exposing (Bumper(..), Perception)


type Behaviour
    = Initializing { openedClaw : Bool, closedClaw : Bool }
    | FindingObject
    | RemovingObject (List Control)


init : Behaviour
init =
    Initializing { openedClaw = False, closedClaw = False }


update : Perception -> Control -> Behaviour -> ( Behaviour, Maybe Control )
update perception currentControl behaviour =
    case behaviour of
        Initializing context ->
            -- Before we begin, we open and close the claw so that the
            -- Perception module can determine its extreme positions.
            if Control.isIdle currentControl then
                if not context.closedClaw then
                    ( Initializing { context | closedClaw = True }, Just Control.grab )

                else if not context.openedClaw then
                    ( Initializing { context | openedClaw = True }, Just Control.release )

                else
                    findObject

            else
                ( behaviour, Nothing )

        FindingObject ->
            case ( Claw.position perception.claw, perception.bumper, perception.travelDirection ) of
                ( Claw.Open, BumperPressed, _ ) ->
                    ( behaviour, Just Control.grab )

                ( Claw.Closed, _, Just travelDirection ) ->
                    removeObject travelDirection

                ( Claw.Closed, _, _ ) ->
                    if Control.isIdle currentControl then
                        ( behaviour, Just Control.followLine )

                    else
                        ( behaviour, Nothing )

                _ ->
                    ( behaviour, Nothing )

        RemovingObject controls ->
            case ( Control.isIdle currentControl, controls ) of
                ( True, nextControl :: remainingControls ) ->
                    ( RemovingObject remainingControls, Just nextControl )

                ( True, [] ) ->
                    findObject

                _ ->
                    ( behaviour, Nothing )


findObject : ( Behaviour, Maybe Control )
findObject =
    ( FindingObject, Just Control.followLine )


removeObject : Perception.TravelDirection -> ( Behaviour, Maybe Control )
removeObject direction =
    ( RemovingObject (removeControls direction), Just Control.idle )


removeControls : Perception.TravelDirection -> List Control
removeControls direction =
    let
        turnLeft =
            Control.moveBy { leftDelta = -180, rightDelta = 180 }

        turnRight =
            Control.moveBy { leftDelta = 180, rightDelta = -180 }

        ( turn, turnBack ) =
            case direction of
                Perception.Clockwise ->
                    ( turnLeft, turnRight )

                Perception.CounterClockwise ->
                    ( turnRight, turnLeft )

        forward =
            Control.moveBy { leftDelta = 360, rightDelta = 360 }

        reverse =
            Control.moveBy { leftDelta = -360, rightDelta = -360 }

        release =
            Control.release
    in
    [ turn
    , forward
    , release
    , reverse
    , turnBack
    ]


metrics : Behaviour -> Maybe Int -> List InfluxDB.Datum
metrics behaviour time =
    let
        behaviourString =
            case behaviour of
                Initializing _ ->
                    "initializing"

                FindingObject ->
                    "finding"

                RemovingObject _ ->
                    "removing"
    in
    [ InfluxDB.Datum "behaviour" [ ( "variant", behaviourString ) ] 1 time
    ]
