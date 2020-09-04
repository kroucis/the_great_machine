module Main exposing (main)

import Bootstrap.Button as Button
import Bootstrap.CDN as CDN
import Bootstrap.Grid as Grid
import Browser
import Decoders
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Json.Decode exposing (decodeValue)
import Json.Encode
import Ports exposing (..)
import Render exposing (..)
import Types exposing (..)



-- Implementations


init : () -> ( Model, Cmd Msg )
init () =
    ( Intro
    , Cmd.none
    )


subscriptions : Model -> Sub Msg
subscriptions model =
    case model of
        Intro ->
            onMatchmaking (\x -> MatchmakingMsg)

        Matchmaking ->
            onMatchReady
                (\payload ->
                    case ( decodeValue Decoders.matchDecoder payload.match, decodeValue Decoders.playerDecoder payload.player ) of
                        ( Ok match, Ok player ) ->
                            StartingMsg match player

                        _ ->
                            MatchmakingMsg
                )

        MatchPlaying match player uiState ->
            onGameEvent
                (\maybeEvent ->
                    case maybeEvent of
                        Just event ->
                            GameEventMsg event

                        Nothing ->
                            MatchmakingMsg
                )


intro : Msg -> Model -> ( Model, Cmd Msg )
intro msg model =
    case msg of
        BeginWorkMsg ->
            ( model
            , beginWork ()
            )

        MatchmakingMsg ->
            ( Matchmaking, Cmd.none )

        ConsoleLogMsg logMsg ->
            ( model, consoleLog logMsg )

        _ ->
            ( model, Cmd.none )


matchmaking : Msg -> Model -> ( Model, Cmd Msg )
matchmaking msg model =
    case msg of
        StartingMsg match player ->
            ( MatchPlaying match
                player
                { lever = 0
                , dialPad = ""
                , dialPadMessage =
                    if match.machine.dial_pad.state > match.machine.dial_pad.count then
                        "^"

                    else if match.machine.dial_pad.state < match.machine.dial_pad.count then
                        "v"

                    else
                        "-"
                }
            , Cmd.none
            )

        _ ->
            ( model, Cmd.none )


playing : Msg -> Model -> Match -> Player -> UIState -> ( Model, Cmd Msg )
playing msg model match player uiState =
    case msg of
        PerformMsg action Nothing ->
            ( model
            , sendGameEvent
                { event = "perform"
                , payload = Just <| Json.Encode.object [ ( "action", Json.Encode.string action ) ]
                }
            )

        PerformMsg action (Just data) ->
            ( model
            , sendGameEvent
                { event = "perform"
                , payload =
                    Just <|
                        Json.Encode.object
                            [ ( "action", Json.Encode.string action )
                            , ( "data", data )
                            ]
                }
            )

        GameEventMsg event ->
            case ( event.event, event.payload ) of
                ( "sync.machine", Just machineJsonValue ) ->
                    case decodeValue Decoders.machineDecoder machineJsonValue of
                        Ok machine ->
                            ( MatchPlaying
                                { match | machine = machine }
                                player
                                { uiState
                                    | lever = 0
                                    , dialPadMessage =
                                        if machine.dial_pad.state > machine.dial_pad.count then
                                            "^"

                                        else if machine.dial_pad.state < machine.dial_pad.count then
                                            "v"

                                        else
                                            "-"
                                }
                            , Cmd.none
                            )

                        Err err ->
                            ( model, Json.Decode.errorToString err |> consoleLog )

                ( "sys.disconnected", Nothing ) ->
                    ( Intro, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        UpdateUIStateMsg ui ->
            ( MatchPlaying match player ui, Cmd.none )

        ConsoleLogMsg logMsg ->
            ( model, consoleLog logMsg )

        _ ->
            ( model, Cmd.none )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case model of
        Intro ->
            intro msg model

        Matchmaking ->
            matchmaking msg model

        MatchPlaying match player uiState ->
            playing msg model match player uiState


view : Model -> Html Msg
view model =
    div []
        [ CDN.stylesheet
        , Render.titleHeader
        , Render.clientState model
        , footer [] [ text "a software toy by Kyle Roucis" ]
        ]



-- Main Function


main : Program Value Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        }
