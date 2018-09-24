module InfluxDB exposing (Config, Datum, QueryResult, get, post)

-- import InfluxDB.Query as Query exposing (Query)

import Dict exposing (Dict)
import Http exposing (Request)
import InfluxDB.Series as Series exposing (Series)
import Json.Decode as D exposing (Decoder)
import Json.Encode exposing (Value)


type alias Config =
    { server : String
    , database : String
    }


type alias QueryResult =
    { statementId : Int
    , series : Maybe (List Series)
    , error : Maybe String
    }


type alias Datum =
    { measurement : String
    , tags : List ( String, String )
    , value : Float
    , time : Maybe Int
    }


{-| Get the result of a single query.
-}
get : ()
get =
    ()



-- get : Config -> Query -> Request QueryResult
-- get config query =
--     let
--         url =
--             config.server ++ "/query?db=" ++ config.database ++ "&q=" ++ Http.encodeUri (Query.build query)
--         decoder =
--             D.field "results" <| D.index 0 <| decodeResult
--     in
--     Http.get url decoder


post : Config -> List Datum -> Request ()
post config data =
    let
        url =
            config.server ++ "/write?db=" ++ config.database

        body =
            data |> List.map formatDatum |> String.join "\n"
    in
    Http.post url (Http.stringBody "application/x-www-form-urlencoded" body) (D.succeed ())


formatDatum : Datum -> String
formatDatum datum =
    let
        time =
            datum.time |> Maybe.map (\t -> " " ++ String.fromInt t) |> Maybe.withDefault ""

        tag ( key, value ) =
            key ++ "=" ++ value
    in
    String.join "," (datum.measurement :: (datum.tags |> List.map tag))
        ++ " value="
        ++ String.fromFloat datum.value
        ++ time


decodeResult : Decoder QueryResult
decodeResult =
    D.map3 QueryResult
        (D.field "statement_id" D.int)
        (D.maybe (D.field "series" (D.list Series.decode)))
        (D.maybe (D.field "error" D.string))
