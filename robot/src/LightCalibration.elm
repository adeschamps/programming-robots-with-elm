module LightCalibration exposing (Parameters, corrected, init, update)


type alias Parameters =
    { high : Float
    , low : Float
    }


init : Parameters
init =
    { high = 0.0
    , low = 100.0
    }


{-| I was experimenting with making the light sensor auto-calibrate
itself, but it turns out these hard coded parameters work pretty even
under vairous light conditions.
-}
update : Float -> Parameters -> Parameters
update raw { high, low } =
    -- { high = max high (raw - 10)
    -- , low = min low (raw + 10)
    -- }
    { high = 60
    , low = 30
    }


corrected : Parameters -> Float -> Float
corrected { high, low } raw =
    ((raw - low) / (high - low))
        |> max 0.0
        |> min 1.0
