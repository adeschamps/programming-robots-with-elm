port module Robot exposing (Config, Input, Output, Robot, reactive, stateful)


port inputs : (Input -> msg) -> Sub msg


port outputs : Output -> Cmd msg


type alias Input =
    { lightSensor : Float
    , distanceSensor : Float
    }


type alias Output =
    { leftMotor : Float
    , rightMotor : Float
    }


type alias Robot state =
    Program () state Input


type alias Config state =
    { init : state
    , update : Input -> state -> state
    , output : Input -> state -> Output
    }


reactive : (Input -> Output) -> Robot ()
reactive output =
    stateful
        { init = ()
        , update = always identity
        , output = \input () -> output input
        }


stateful : Config state -> Robot state
stateful robot =
    Platform.worker
        { init = \_ -> ( robot.init, Cmd.none )
        , update =
            \input state ->
                let
                    newState =
                        robot.update input state

                    output =
                        robot.output input newState
                in
                ( newState, outputs output )
        , subscriptions = \_ -> inputs identity
        }
