module Action exposing (Action(..), output)

import Robot exposing (Input, Output)
import State exposing (State)


type Action
    = OpenClaw
    | CloseClaw
    | Move { left : Int, right : Int }


output : Input -> Action -> Output
output input action =
    case action of
        OpenClaw ->
            { leftMotor = 0.0
            , rightMotor = 0.0
            , clawMotor = 1.0
            , lights = Nothing
            }

        CloseClaw ->
            { leftMotor = 0.0
            , rightMotor = 0.0
            , clawMotor = 1.0
            , lights = Nothing
            }

        Move { left, right } ->
            { leftMotor = speed (left - input.leftMotor)
            , rightMotor = speed (right - input.rightMotor)
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
