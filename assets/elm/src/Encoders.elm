module Encoders exposing (..)

import Json.Encode
import Types


performEncoder : String -> Json.Encode.Value -> Json.Encode.Value
performEncoder event data =
    Json.Encode.object
        [ ( "action", Json.Encode.string action )
        , ( "data", data )
        ]
