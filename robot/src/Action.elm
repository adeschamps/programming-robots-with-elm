module Action exposing (Action(..), output, update)

import LightCalibration
import Lights
import Robot exposing (Input, Output)
import State exposing (Claw(..), State)


type Action
    = Idle
    | Grab
    | Release
    | FollowLine
    | MoveTo { left : Int, right : Int }
    | MoveBy { leftDelta : Int, rightDelta : Int }


update : State -> Action -> Action
update state action =
    case action of
        Idle ->
            action

        Grab ->
            if state.claw == ClawClosed then
                Idle

            else
                action

        Release ->
            if state.claw == ClawOpen then
                Idle

            else
                action

        FollowLine ->
            action

        MoveBy { leftDelta, rightDelta } ->
            MoveTo { left = state.wheels.left + leftDelta, right = state.wheels.right + rightDelta }

        MoveTo { left, right } ->
            if within 5 left state.wheels.left && within 5 right state.wheels.right then
                Idle

            else
                action


output : Action -> State -> Input -> Output
output action state input =
    case action of
        Idle ->
            { leftMotor = 0.0
            , rightMotor = 0.0
            , clawMotor = 0.0
            , lights = Nothing
            }

        Grab ->
            { leftMotor = 0.0
            , rightMotor = 0.0
            , clawMotor = 1.0
            , lights = Nothing
            }

        Release ->
            { leftMotor = 0.0
            , rightMotor = 0.0
            , clawMotor = 1.0
            , lights = Nothing
            }

        FollowLine ->
            followLine <| LightCalibration.corrected state.lightCalibration input.lightSensor

        MoveTo { left, right } ->
            { leftMotor = speed (left - input.leftMotor)
            , rightMotor = speed (right - input.rightMotor)
            , clawMotor = 0.0
            , lights = Nothing
            }

        MoveBy _ ->
            output Idle state input


followLine : Float -> Output
followLine brightness =
    { leftMotor = brightness
    , rightMotor = 1.0 - brightness
    , clawMotor = 0.0
    , lights = Nothing
    }


speed : Int -> Float
speed delta =
    if delta > 1 then
        -1.0

    else if delta < 1 then
        1.0

    else
        0.0


within : Int -> Int -> Int -> Bool
within tolerance a b =
    abs (a - b) < tolerance


error : Output
error =
    { leftMotor = 0.0
    , rightMotor = 0.0
    , clawMotor = 0.0
    , lights = Just { left = Lights.red, right = Lights.red }
    }
