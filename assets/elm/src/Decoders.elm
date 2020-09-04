module Decoders exposing (..)

import Json.Decode exposing (..)
import Types exposing (..)



--type alias Player =
--    { id : ID
--    }


playerDecoder : Decoder Player
playerDecoder =
    map Player
        (field "id" int)



--type alias PlayerCount =
--     { player_count : Int
--     }


playerCountDecoder : Decoder PlayerCount
playerCountDecoder =
    map PlayerCount
        (field "player_count" int)



--type alias MachineControl =
--    { count : Int
--    , visible : Bool
--    }


machineControlDecoder : Decoder MachineControl
machineControlDecoder =
    map3 MachineControl
        (field "count" int)
        (field "state" int)
        (field "visible" bool)



--type alias Machine =
--    { blue_button : MachineControl
--    , red_button : MachineControl
--    }


machineDecoder : Decoder Machine
machineDecoder =
    map8 Machine
        (field "blue_button" machineControlDecoder)
        (field "red_button" machineControlDecoder)
        (field "green_button" machineControlDecoder)
        (field "button_array" machineControlDecoder)
        (field "guess" machineControlDecoder)
        (field "wheel" machineControlDecoder)
        (field "unlock" machineControlDecoder)
        (field "dial_pad" machineControlDecoder)



--(maybe (field "message" Json.Decode.string))
--type alias Match =
--    { id : ID
--    , machine : Machine
--    }


matchDecoder : Decoder Match
matchDecoder =
    map3 Match
        (field "id" int)
        (field "player_count" int)
        (field "machine" machineDecoder)
