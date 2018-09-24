module InfluxDB.Series exposing (Series, decode)

import Dict exposing (Dict)
import Json.Decode as D exposing (Decoder)
import Json.Encode exposing (Value)


type alias Series =
    { name : String
    , tags : Dict String String
    , columns : List String
    , values : List (List Value)
    }


decode : Decoder Series
decode =
    D.map4 Series
        (D.field "name" D.string)
        (D.maybe (D.field "tags" (D.dict D.string))
            |> D.map (Maybe.withDefault Dict.empty)
        )
        (D.field "columns" (D.list D.string))
        (D.field "values" (D.list (D.list D.value)))
