port module Robot exposing (Config, Input, Output, Robot, reactive, stateful)

import Http
import InfluxDB
import Json.Decode as D


port inputs : (Input -> msg) -> Sub msg


port outputs : Output -> Cmd msg


type alias Input =
    { lightSensor : Float
    , distanceSensor : Int
    , touchSensor : Bool
    , time : Int
    , leftMotor : Int
    , rightMotor : Int
    , clawMotor : Int
    }


type alias Output =
    { leftMotor : Float
    , rightMotor : Float
    }


type Msg
    = NewInput Input
    | NoOp


type alias Model model =
    { state : model
    , flags : Flags
    }


type alias Flags =
    { influxDB : Maybe InfluxDB.Config
    }


type alias Robot state =
    Program Flags (Model state) Msg


type alias Config state =
    { init : state
    , update : Input -> state -> state
    , output : Input -> state -> Output
    , generateMetrics : Maybe (Input -> state -> List InfluxDB.Datum)
    }


reactive : (Input -> Output) -> Robot ()
reactive output =
    stateful
        { init = ()
        , update = always identity
        , output = \input () -> output input
        , generateMetrics = Nothing
        }


stateful : Config state -> Robot state
stateful robot =
        { init = \flags -> ( { flags = flags, state = robot.init }, Cmd.none )
    Platform.programWithFlags
        , update = update robot
        , subscriptions = \_ -> inputs NewInput
        }


update : Config state -> Msg -> Model state -> ( Model state, Cmd Msg )
update config msg model =
    case msg of
        NewInput input ->
            let
                newState =
                    config.update input model.state

                output =
                    config.output input newState

                sendMetrics =
                    case ( model.flags.influxDB, config.generateMetrics ) of
                        ( Just influxConfig, Just generate ) ->
                            InfluxDB.post influxConfig (generate input newState) |> Http.send (always NoOp)

                        _ ->
                            Cmd.none
            in
            ( { model | state = newState }, Cmd.batch [ outputs output, sendMetrics ] )

        NoOp ->
            ( model, Cmd.none )
