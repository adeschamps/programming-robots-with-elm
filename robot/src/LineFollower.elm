module LineFollower exposing (main)

import Robot exposing (Input, Output, Robot)


main : Robot State
main =
    Robot.program
        { init = Blocked
        , update = update
        , output = output
        }


type State
    = Blocked
    | Unblocked


update : Input -> State -> State
update input state =
    if input.distanceSensor < 50 then
        Blocked

    else
        Unblocked


output : Input -> State -> Output
output input state =
    case state of
        Blocked ->
            { leftMotor = 0
            , rightMotor = 0
            }

        Unblocked ->
            { leftMotor = input.lightSensor
            , rightMotor = 1.0 - input.lightSensor
            }
