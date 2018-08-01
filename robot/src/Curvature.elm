module Curvature exposing (Curvature, init, update)


type alias Curvature =
    { raw : Float
    , curve_1s : Float
    , curve_5s : Float
    }


init : Curvature
init =
    { raw = 0
    , curve_1s = 0
    , curve_5s = 0
    }


update : { a | leftMotor : Int, rightMotor : Int } -> Curvature -> Curvature
update { leftMotor, rightMotor } current =
    let
        delta =
            toFloat <| leftMotor - rightMotor

        alpha =
            0.1
    in
    { raw = current.curve_1s * (1 - 1) + delta * 1
    , curve_1s = current.curve_1s * (1 - 0.1) + delta * 0.1
    , curve_5s = current.curve_1s * (1 - 0.01) + delta * 0.01
    }
