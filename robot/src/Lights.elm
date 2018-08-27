module Lights exposing (green, off, orange, red)

{-| The EV3 brick has two LEDs on it. Each LED has a red and a green channel.
-}

import Robot exposing (BrickLights, LedColor)


red : LedColor
red =
    { red = 1, green = 0 }


green : LedColor
green =
    { red = 0, green = 1 }


orange : LedColor
orange =
    { red = 1, green = 1 }


off : LedColor
off =
    { red = 0, green = 0 }
