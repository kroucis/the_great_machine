module Render exposing (..)

import Bitwise
import Bootstrap.Button as Button
import Bootstrap.ButtonGroup as ButtonGroup
import Bootstrap.CDN as CDN
import Bootstrap.Grid as Grid
import Bootstrap.Grid.Col as Col
import Bootstrap.Grid.Row as Row
import Html exposing (..)
import Html.Attributes as Attrs exposing (..)
import Html.Events exposing (..)
import Json.Encode
import Types exposing (..)


intro : Html Msg
intro =
    div []
        [ div []
            --[ h3 [] [ text "The Great Machine demands your labor for its upkeep! Join The Holy Engineering Corps and follow Its commands!" ]
            []
        , div []
            [ Button.button
                [ Button.primary
                , Button.large
                , Button.block
                , Button.attrs [ onClick BeginWorkMsg ]
                ]
                [ text "Begin Work" ]
            ]
        ]


matchmaking : Html Msg
matchmaking =
    div []
        --[ text "Matchmaking..."
        []


blueButton : MachineControl -> Html Msg
blueButton bB =
    case bB.visible of
        False ->
            div [] []

        True ->
            Button.button
                [ Button.primary
                , Button.large
                , Button.block
                , Button.attrs [ onClick <| perform "blue_button" ]
                ]
                [ text <| String.fromInt bB.count ]


redButton : MachineControl -> Html Msg
redButton rB =
    --case rB.visible of
    --    False ->
    --        div [] []
    --    True ->
    Button.button
        [ Button.danger
        , Button.large
        , Button.block
        , Button.attrs
            [ onClick <| perform "red_button"
            , disabled <| not rB.visible
            ]
        ]
        [ text <| String.fromInt rB.count ]


greenButton : MachineControl -> MachineControl -> Html Msg
greenButton gB rB =
    case gB.visible of
        False ->
            div [] []

        True ->
            Button.button
                [ Button.success
                , Button.large
                , Button.block
                , Button.disabled ((4 * (2 ^ gB.count)) > rB.count)
                , Button.attrs [ onClick <| perform "green_button" ]
                ]
                [ text <| String.fromInt gB.count ]



--lever : UIState -> MachineControl -> Html Msg
--lever uiState hL =
--    case hL.visible of
--        False ->
--            div [] []
--        True ->
--            div []
--                [ input
--                    [ type_ "range"
--                    , Attrs.min "0"
--                    , Attrs.max "5"
--                    , value <| String.fromInt uiState.lever
--                    , onInput <| \str -> UpdateUIStateMsg { uiState | lever = String.toInt str |> Maybe.withDefault 0 }
--                    ]
--                    []
--                , text <| String.fromInt uiState.lever
--                , Button.button
--                    [ Button.secondary
--                    , Button.small
--                    , Button.attrs [ onClick <| performInt "lever" uiState.lever ]
--                    ]
--                    [ text "Set" ]
--                ]
--switch : MachineControl -> Html Msg
--switch sW =
--    case sW.visible of
--        False ->
--            div [] []
--        True ->
--            div []
--                [ input
--                    [ type_ "checkbox"
--                    , checked <| sW.count > 0
--                    , onCheck <| \b -> perform "switch"
--                    ]
--                    []
--                ]


buttonArrayBreaker : MachineControl -> Html Msg
buttonArrayBreaker bA =
    div []
        [ input
            [ type_ "checkbox"
            , checked (bA.state /= -1)
            , onCheck
                (\b ->
                    performInt "button_array"
                        (if b then
                            0

                         else
                            -1
                        )
                )
            ]
            []
        ]


buttonArrayButton : Bool -> Bool -> Int -> ButtonGroup.RadioButtonItem Msg
buttonArrayButton enabled selected index =
    ButtonGroup.radioButton selected
        [ Button.secondary
        , Button.large
        , Button.disabled (not enabled)
        , Button.attrs
            (if enabled then
                [ onClick <| performInt "button_array" index
                ]

             else
                []
            )
        ]
        [ text
            (if selected then
                "|"

             else
                "--"
            )
        ]


buttonArray : MachineControl -> Html Msg
buttonArray bA =
    let
        enabled =
            bA.state /= -1

        firstSelected =
            bA.state == 1

        secondSelected =
            (bA.state == 2) || (bA.state == -2) || (bA.state == 4)

        thirdSelected =
            (bA.state == 3) || (bA.state == -3)
    in
    ButtonGroup.radioButtonGroup
        [ ButtonGroup.large
        ]
        [ buttonArrayButton enabled firstSelected 1
        , buttonArrayButton enabled secondSelected 2
        , buttonArrayButton enabled thirdSelected 3
        ]


buttonArrayUnlock : MachineControl -> MachineControl -> Html Msg
buttonArrayUnlock unlock bA =
    case ( unlock.visible, unlock.state, bA.visible ) of
        ( False, _, False ) ->
            div [] []

        ( True, 0, False ) ->
            Button.button
                [ Button.secondary
                , Button.attrs
                    [ onClick <| performInt "unlock" unlock.count
                    ]
                ]
                [ text "Power Up Circuit" ]

        ( True, _, False ) ->
            div [] []

        ( _, _, True ) ->
            div []
                [ buttonArrayBreaker bA
                , buttonArray bA
                ]


wheelCheckbox : Int -> Int -> Html Msg
wheelCheckbox index state =
    input
        [ type_ "checkbox"
        , checked (index == state)
        , disabled (index /= ((state + 1) |> modBy 8))
        , onCheck <| \b -> performInt "wheel" index
        ]
        []


wheelTop : MachineControl -> Html Msg
wheelTop wh =
    Grid.container []
        [ Grid.row []
            [ Grid.col []
                [ wheelCheckbox 0 wh.state ]
            , Grid.col []
                [ wheelCheckbox 1 wh.state ]
            , Grid.col []
                [ wheelCheckbox 2 wh.state ]
            ]
        ]


wheelUnlock : MachineControl -> MachineControl -> MachineControl -> MachineControl -> Html Msg
wheelUnlock unlock wh blue red =
    case ( unlock.visible, unlock.state, wh.visible ) of
        ( False, _, False ) ->
            div [] []

        ( True, 1, False ) ->
            Button.button
                [ Button.secondary
                , Button.attrs
                    [ onClick <| performInt "unlock" unlock.count
                    , disabled ((blue.count < unlock.count) || (red.count < unlock.count // 4))
                    ]
                ]
                [ text "Disengage Brake" ]

        ( True, _, False ) ->
            div [] []

        ( _, _, True ) ->
            wheelTop wh


wheelMiddle : MachineControl -> Html Msg
wheelMiddle wh =
    case wh.visible of
        False ->
            div [] []

        True ->
            Grid.container []
                [ Grid.row []
                    [ Grid.col []
                        [ wheelCheckbox 7 wh.state ]
                    , Grid.col []
                        [ h1 [] [ text "O" ] ]
                    , Grid.col []
                        [ wheelCheckbox 3 wh.state ]
                    ]
                ]


wheelBottom : MachineControl -> Html Msg
wheelBottom wh =
    case wh.visible of
        False ->
            div [] []

        True ->
            Grid.container []
                [ Grid.row []
                    [ Grid.col []
                        [ wheelCheckbox 6 wh.state ]
                    , Grid.col []
                        [ wheelCheckbox 5 wh.state ]
                    , Grid.col []
                        [ wheelCheckbox 4 wh.state ]
                    ]
                ]


pressureGuage : MachineControl -> Html Msg
pressureGuage bA =
    case bA.visible of
        False ->
            div [] []

        True ->
            div []
                [ h3 [ style "text-align" "center" ] [ text "Pressure" ]
                , h4 [ style "text-align" "center" ] [ text <| String.fromInt bA.count ]
                ]


engageDriveButton : MachineControl -> Html Msg
engageDriveButton bA =
    case bA.visible of
        False ->
            div [] []

        True ->
            Button.button
                [ Button.secondary
                , Button.disabled (bA.count < 15)
                , Button.attrs
                    [ onClick <| perform "engage" ]
                ]
                [ text "Engage Drive" ]


guessBreaker : MachineControl -> Html Msg
guessBreaker g =
    div []
        [ input
            [ type_ "checkbox"
            , checked (g.state > 0)
            , onCheck
                (\b ->
                    performInt "guess"
                        (if b then
                            0

                         else
                            -1
                        )
                )
            ]
            []
        ]


guessButton : Int -> Bool -> Int -> ButtonGroup.ButtonItem Msg
guessButton index dsbld count =
    let
        num =
            2 ^ (index - 1)
    in
    ButtonGroup.button
        [ Button.primary
        , Button.small
        , Button.attrs
            [ onClick <| performInt "guess" index
            , disabled <| dsbld || (Bitwise.and num count == num)
            ]
        ]
        [ text <| String.fromInt index ]


guess : MachineControl -> Html Msg
guess g =
    ButtonGroup.buttonGroup []
        --[ ButtonGroup.vertical
        --]
        (List.range 1 9
            |> List.map (\index -> guessButton index (g.state == -1) g.count)
        )


guessUnlock : MachineControl -> MachineControl -> MachineControl -> MachineControl -> Html Msg
guessUnlock unlock g blue red =
    case ( unlock.visible, unlock.state, g.visible ) of
        ( False, _, False ) ->
            div [] []

        ( True, 2, False ) ->
            Button.button
                [ Button.secondary
                , Button.attrs
                    [ onClick <| performInt "unlock" unlock.count
                    , disabled ((blue.count < unlock.count) || (red.count < unlock.count // 4))
                    ]
                ]
                [ text "Power Panel" ]

        ( True, _, False ) ->
            div [] []

        ( _, _, True ) ->
            div []
                [ guessBreaker g
                , guess g
                ]


dialPadBreaker : MachineControl -> Html Msg
dialPadBreaker dP =
    div []
        [ input
            [ type_ "checkbox"
            , checked (dP.state >= 0)
            , onCheck
                (\b ->
                    performInt "dial_pad"
                        (if b then
                            0

                         else
                            -1
                        )
                )
            ]
            []
        ]


dialPadButton : UIState -> Bool -> String -> Html Msg
dialPadButton uiState dsbld str =
    Button.button
        [ Button.secondary
        , Button.small
        , Button.block
        , Button.attrs
            [ onClick <| UpdateUIStateMsg { uiState | dialPad = uiState.dialPad ++ str |> String.left 4 }
            , disabled dsbld
            ]
        ]
        [ text str ]


dialPad : UIState -> Bool -> MachineControl -> Html Msg
dialPad uiState dsbld dP =
    Grid.container []
        [ Grid.row []
            [ Grid.col []
                [ input
                    [ value uiState.dialPad
                    , disabled True
                    , maxlength 4
                    ]
                    []
                , text uiState.dialPadMessage
                ]
            , Grid.col []
                [ Button.button
                    [ Button.secondary
                    , Button.small
                    , Button.attrs
                        [ onClick <| UpdateUIStateMsg { uiState | dialPad = "" }
                        , disabled dsbld
                        ]
                    ]
                    [ text "Clear" ]
                ]
            , Grid.col []
                [ Button.button
                    [ Button.secondary
                    , Button.small
                    , Button.attrs
                        [ onClick <| performInt "dial_pad" <| (String.toInt uiState.dialPad |> Maybe.withDefault 0)
                        , disabled dsbld
                        ]
                    ]
                    [ text "Send" ]
                ]
            ]
        , Grid.row [ Row.centerMd ]
            [ Grid.col []
                [ dialPadButton uiState dsbld "1" ]
            , Grid.col []
                [ dialPadButton uiState dsbld "2" ]
            , Grid.col []
                [ dialPadButton uiState dsbld "3" ]
            ]
        , Grid.row [ Row.centerMd ]
            [ Grid.col []
                [ dialPadButton uiState dsbld "4" ]
            , Grid.col []
                [ dialPadButton uiState dsbld "5" ]
            , Grid.col []
                [ dialPadButton uiState dsbld "6" ]
            ]
        , Grid.row [ Row.centerMd ]
            [ Grid.col []
                [ dialPadButton uiState dsbld "7" ]
            , Grid.col []
                [ dialPadButton uiState dsbld "8" ]
            , Grid.col []
                [ dialPadButton uiState dsbld "9" ]
            ]
        , Grid.row [ Row.centerMd ]
            [ Grid.col [] []
            , Grid.col []
                [ dialPadButton uiState dsbld "0" ]
            , Grid.col []
                []

            --[ text uiState.dialPadMessage ]
            ]
        ]


dialPadUnlock : UIState -> MachineControl -> MachineControl -> MachineControl -> MachineControl -> Html Msg
dialPadUnlock uiState unlock dP blue red =
    case ( unlock.visible, unlock.state, dP.visible ) of
        ( False, _, False ) ->
            div [] []

        ( True, 3, False ) ->
            Button.button
                [ Button.secondary
                , Button.attrs
                    [ onClick <| performInt "unlock" unlock.count
                    , disabled ((blue.count < unlock.count) || (red.count < unlock.count // 4))
                    ]
                ]
                [ text "Unlock Cover" ]

        ( True, _, False ) ->
            div [] []

        ( _, _, True ) ->
            div []
                [ dialPadBreaker dP
                , dialPad uiState (dP.state == -1) dP
                ]


vertButton : Int -> Int -> Int -> Html Msg
vertButton state index blueCount =
    Button.button
        [ if state < index then
            Button.secondary

          else
            Button.warning
        , Button.small
        , Button.attrs
            [ disabled ((blueCount < (2 ^ index * 200)) || (state /= index - 1))

            --, onClick <| ConsoleLogMsg (String.fromInt (2 ^ index * 200))
            , onClick <| performInt "wheel_amp" index
            ]
        ]
        [ text ("L " ++ String.fromInt index) ]


vertCheckmark : Int -> Int -> Html Msg
vertCheckmark state index =
    input
        [ type_ "checkbox"
        , checked (state >= index)
        , disabled True
        ]
        []


vertButtons : MachineControl -> MachineControl -> Html Msg
vertButtons wheel blue =
    Grid.container []
        [ Grid.row []
            [ Grid.col []
                [ vertButton wheel.count 2 blue.count
                ]
            , Grid.col []
                [ vertCheckmark wheel.count 2
                ]
            ]
        , Grid.row []
            [ Grid.col []
                [ vertButton wheel.count 3 blue.count
                ]
            , Grid.col []
                [ vertCheckmark wheel.count 3
                ]
            ]
        , Grid.row []
            [ Grid.col []
                [ vertButton wheel.count 4 blue.count
                ]
            , Grid.col []
                [ vertCheckmark wheel.count 4
                ]
            ]
        ]


vertButtonGroupUnlock : MachineControl -> MachineControl -> MachineControl -> MachineControl -> Html Msg
vertButtonGroupUnlock unlock wheel blue red =
    case ( unlock.visible, unlock.state, wheel.count ) of
        ( False, 4, 1 ) ->
            div [] []

        ( False, 4, _ ) ->
            vertButtons wheel blue

        ( True, 4, 1 ) ->
            Button.button
                [ Button.secondary
                , Button.attrs
                    [ onClick <| performInt "unlock" unlock.count
                    , disabled ((blue.count < unlock.count) || (red.count < unlock.count // 4))
                    ]
                ]
                [ text "Enable Switches" ]

        ( _, _, _ ) ->
            div [] []


matchPlaying : Match -> Player -> UIState -> Html Msg
matchPlaying match player uiState =
    let
        m =
            match.machine
    in
    Grid.container []
        [ Grid.row []
            [ Grid.col []
                [ blueButton m.blue_button ]
            , Grid.col []
                [ redButton m.red_button ]
            ]
        , Grid.row []
            [ Grid.col []
                [ greenButton m.green_button m.red_button ]
            ]
        , Grid.row []
            --[ Grid.col []
            --    [ lever uiState m.lever ]
            --, Grid.col []
            --    [ buttonArray m.button_array ]
            --]
            [ Grid.col []
                [ buttonArrayUnlock
                    m.unlock
                    m.button_array
                ]
            , Grid.col []
                [ pressureGuage m.button_array ]
            , Grid.col []
                [ wheelUnlock
                    m.unlock
                    m.wheel
                    m.blue_button
                    m.red_button
                ]
            ]
        , Grid.row []
            [ Grid.col []
                [ guessUnlock
                    m.unlock
                    m.guess
                    m.blue_button
                    m.red_button
                ]
            , Grid.col [] []
            , Grid.col []
                [ wheelMiddle m.wheel ]
            ]
        , Grid.row [ Row.centerSm ]
            [ Grid.col []
                [ dialPadUnlock
                    uiState
                    m.unlock
                    m.dial_pad
                    m.blue_button
                    m.red_button
                ]
            , Grid.col [ Col.sm ]
                [ engageDriveButton m.button_array
                ]
            , Grid.col []
                [ wheelBottom m.wheel
                , vertButtonGroupUnlock
                    m.unlock
                    m.wheel
                    m.blue_button
                    m.red_button
                ]
            ]

        --, Grid.row []
        --    [ Grid.col []
        --        [ switch match.machine.switch ]
        --    ]
        --, Grid.row []
        --    [ Grid.col []
        --        [ dialPad uiState match.machine.dial_pad match.machine.message ]
        --    ]
        ]


clientState : ClientState -> Html Msg
clientState state =
    case state of
        Intro ->
            intro

        Matchmaking ->
            matchmaking

        MatchPlaying match player uiState ->
            matchPlaying match player uiState


titleHeader : Html Msg
titleHeader =
    header []
        [ h1 [ style "text-align" "center" ]
            [ text "The Great Machine" ]
        ]
