module Types exposing (..)

import Json.Encode


type alias ID =
    Int


type alias Name =
    String


type alias UUID =
    String


type alias GameEvent =
    { event : String
    , payload : Maybe Json.Encode.Value
    }


type alias MachineControl =
    { count : Int
    , state : Int
    , visible : Bool
    }


type alias Player =
    { id : ID
    }


type alias PlayerCount =
    { player_count : Int
    }


type alias Machine =
    { blue_button : MachineControl
    , red_button : MachineControl
    , green_button : MachineControl

    --, lever : MachineControl
    --, switch : MachineControl
    , button_array : MachineControl
    , guess : MachineControl
    , wheel : MachineControl
    , unlock : MachineControl
    , dial_pad : MachineControl

    --, message : Maybe String
    }


type alias Match =
    { id : ID
    , player_count : Int
    , machine : Machine
    }


type alias UIState =
    { lever : Int
    , dialPad : String
    , dialPadMessage : String
    }


type ClientState
    = Intro
    | Matchmaking
    | MatchPlaying Match Player UIState


type alias Model =
    ClientState


type alias Value =
    ()


type Msg
    = BeginWorkMsg
    | MatchmakingMsg
    | StartingMsg Match Player
    | PerformMsg String (Maybe Json.Encode.Value)
    | GameEventMsg GameEvent
    | ConsoleLogMsg String
    | UpdateUIStateMsg UIState


type alias Link =
    Maybe String


perform : String -> Msg
perform action =
    PerformMsg action Nothing


performStr : String -> String -> Msg
performStr action data =
    PerformMsg action (Just (Json.Encode.object [ ( "value", Json.Encode.string data ) ]))


performInt : String -> Int -> Msg
performInt action data =
    PerformMsg action (Just (Json.Encode.object [ ( "value", Json.Encode.int data ) ]))
