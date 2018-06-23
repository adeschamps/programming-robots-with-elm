module LineFollower exposing (main)

import Robot exposing (Input, Output, Robot)


main : Robot ()
main =
    Robot.reactive output


output : Input -> Output
output input =
    { leftMotor = input.lightSensor
    , rightMotor = 100.0 - input.lightSensor
    }
