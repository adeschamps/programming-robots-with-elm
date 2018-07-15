module LineFollower exposing (main)

import Robot exposing (Input, Output, Robot)


main : Robot ()
main =
    Robot.reactive output


output : Input -> Output
output input =
    if input.distanceSensor > 50 then
        { leftMotor = input.lightSensor
        , rightMotor = 100 - input.lightSensor
        }

    else
        { leftMotor = 0
        , rightMotor = 0
        }
