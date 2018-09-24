port module Robot exposing (BrickLights, Config, Input, LedColor, Output, Robot, program)

import Http
import InfluxDB
import Time


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
    , clawMotor : Float
    , lights : Maybe BrickLights
    }


type alias BrickLights =
    { left : LedColor
    , right : LedColor
    }


type alias LedColor =
    { red : Float
    , green : Float
    }


type Msg
    = NewInput Input
    | Tick
    | NoOp


type alias Model model =
    { state : model
    , flags : Flags
    , metrics : List InfluxDB.Datum
    }


type alias Flags =
    { influxDB : Maybe InfluxDB.Config
    , influxPeriod : Maybe Float
    }


type alias Robot state =
    Program Flags (Model state) Msg


type alias Config state =
    { init : state
    , update : Input -> state -> state
    , output : state -> Input -> Output
    , generateMetrics : Maybe (Input -> state -> List InfluxDB.Datum)
    }


program : Config state -> Robot state
program config =
    Platform.programWithFlags
        { init = \flags -> ( { flags = flags, state = config.init, metrics = [] }, Cmd.none )
        , update = update config
        , subscriptions = subscriptions
        }


subscriptions : Model state -> Sub Msg
subscriptions model =
    let
        ticks =
            case model.flags.influxDB of
                Just _ ->
                    Time.every (model.flags.influxPeriod |> Maybe.withDefault 1000) (always Tick)

                _ ->
                    Sub.none
    in
    Sub.batch [ inputs NewInput, ticks ]


update : Config state -> Msg -> Model state -> ( Model state, Cmd Msg )
update config msg model =
    case msg of
        NewInput input ->
            let
                newState =
                    config.update input model.state

                output =
                    config.output newState input

                metrics =
                    case config.generateMetrics of
                        Just generate ->
                            generate input newState ++ model.metrics

                        _ ->
                            []
            in
            ( { model | state = newState, metrics = metrics }, outputs output )

        Tick ->
            let
                sendMetrics =
                    case model.flags.influxDB of
                        Just influxConfig ->
                            InfluxDB.post influxConfig model.metrics
                                |> Http.send (always NoOp)

                        _ ->
                            Cmd.none
            in
            ( { model | metrics = [] }, sendMetrics )

        NoOp ->
            ( model, Cmd.none )
