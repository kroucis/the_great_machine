port module Ports exposing (..)

import Json.Encode
import Types exposing (..)



-- Ports
---- Out Ports


port beginWork : () -> Cmd msg


port sendGameEvent : GameEvent -> Cmd msg


port consoleLog : String -> Cmd msg



-- In Ports


port onMatchmaking : (() -> msg) -> Sub msg


port onMatchReady : ({ match : Json.Encode.Value, player : Json.Encode.Value } -> msg) -> Sub msg


port onGameEvent : (Maybe GameEvent -> msg) -> Sub msg
