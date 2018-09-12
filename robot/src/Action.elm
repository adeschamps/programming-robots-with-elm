module Action exposing (Action, followLine, grab, idle, isIdle, moveBy, output, release, update)

import LightCalibration
import Lights
import Robot exposing (Input, Output)
import State exposing (State)


type Action
    = Idle
    | Grab Timer
    | Release Timer
    | FollowLine
    | MoveTo { left : Int, right : Int }
    | MoveBy { leftDelta : Int, rightDelta : Int }


type Timer
    = Starting
    | Since Int



-- CONSTRUCTORS


idle : Action
idle =
    Idle


grab : Action
grab =
    Grab Starting


release : Action
release =
    Release Starting


followLine : Action
followLine =
    FollowLine


moveBy : { leftDelta : Int, rightDelta : Int } -> Action
moveBy params =
    MoveBy params



-- INSPECTION


isIdle : Action -> Bool
isIdle action =
    case action of
        Idle ->
            True

        _ ->
            False



-- UPDATE AND OUTPUTS


grabDuration : Int
grabDuration =
    2000


releaseDuration : Int
releaseDuration =
    2000


update : State -> Action -> Action
update state action =
    case action of
        Idle ->
            action

        Grab Starting ->
            Grab (Since state.time)

        Grab (Since startTime) ->
            if state.time - startTime > grabDuration then
                Idle

            else
                action

        Release Starting ->
            Release (Since state.time)

        Release (Since startTime) ->
            if state.time - startTime > releaseDuration then
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

        Grab _ ->
            { leftMotor = 0.0
            , rightMotor = 0.0
            , clawMotor = -1.0
            , lights = Nothing
            }

        Release _ ->
            { leftMotor = 0.0
            , rightMotor = 0.0
            , clawMotor = 1.0
            , lights = Nothing
            }

        FollowLine ->
            let
                brightness =
                    LightCalibration.corrected state.lightCalibration input.lightSensor
            in
            { leftMotor = brightness
            , rightMotor = 1.0 - brightness
            , clawMotor = 0.0
            , lights = Nothing
            }

        MoveTo { left, right } ->
            { leftMotor = speed (left - input.leftMotor)
            , rightMotor = speed (right - input.rightMotor)
            , clawMotor = 0.0
            , lights = Nothing
            }

        MoveBy _ ->
            output Idle state input



-- HELPERS


speed : Int -> Float
speed delta =
    delta
        |> toFloat
        |> (*) 0.01
        |> max -1.0
        |> min 1.0


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
