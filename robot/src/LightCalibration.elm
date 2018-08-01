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


update : Float -> Parameters -> Parameters
update raw { high, low } =
    { high = max high (raw - 20)
    , low = min low (raw + 20)
    }


corrected : Parameters -> Float -> Float
corrected { high, low } raw =
    if raw >= high then
        1.0

    else if raw <= low then
        0.0

    else
        0.5



-- (raw - low) / (high - low)
