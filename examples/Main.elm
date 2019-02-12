module Main exposing (main)

import Browser
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Events as Events
import Element.Font as Font
import Element.Input as Input
import Html
import Html.Attributes
import Html.Events
import Http
import Http.Boxed
import Http.Plus
import Http.State
import Json.Decode
import Json.Decode.Pipeline
import Json.Encode
import Markdown
import Svg
import Svg.Attributes as SA
import Url.Builder



{-
   ███    ███  ██████  ██████  ███████ ██
   ████  ████ ██    ██ ██   ██ ██      ██
   ██ ████ ██ ██    ██ ██   ██ █████   ██
   ██  ██  ██ ██    ██ ██   ██ ██      ██
   ██      ██  ██████  ██████  ███████ ███████
-}


type alias Model =
    -- NOT UNBOXED
    { httpResult : Maybe (Result Http.Error (Http.Response String))
    , httpState : Http.State.State BodyResponse
    , httpStateRaw : Http.State.State String

    -- UNBOXED
    , httpResultUnboxed : Maybe (Result Http.Error (Http.Response String))
    , httpStateUnboxed : Http.State.State BodyResponse
    , httpStateRawUnboxed : Http.State.State String

    -- OTHERS
    , httpUrl : String
    }



{-
   ██ ███    ██ ██ ████████
   ██ ████   ██ ██    ██
   ██ ██ ██  ██ ██    ██
   ██ ██  ██ ██ ██    ██
   ██ ██   ████ ██    ██
-}


init : () -> ( Model, Cmd Msg )
init _ =
    ( { httpResult = Nothing
      , httpState = Http.State.NotRequested
      , httpStateRaw = Http.State.NotRequested

      --
      , httpResultUnboxed = Nothing
      , httpStateUnboxed = Http.State.NotRequested
      , httpStateRawUnboxed = Http.State.NotRequested

      --
      , httpUrl = ""
      }
    , Cmd.none
    )



{-
   ███    ███ ███████  ██████
   ████  ████ ██      ██
   ██ ████ ██ ███████ ██   ███
   ██  ██  ██      ██ ██    ██
   ██      ██ ███████  ██████
-}


type Msg
    = MorePlease String
    | GotGif (Result Http.Error (Http.Response String))
    | GotGifUnboxed (Result Http.Error (Http.Response String))
    | MsgFetching
    | MsgNotRequested



{-
   ██    ██ ██████  ██████   █████  ████████ ███████
   ██    ██ ██   ██ ██   ██ ██   ██    ██    ██
   ██    ██ ██████  ██   ██ ███████    ██    █████
   ██    ██ ██      ██   ██ ██   ██    ██    ██
    ██████  ██      ██████  ██   ██    ██    ███████
-}


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        MorePlease url ->
            ( { model
                | httpUrl = url
                , httpState = Http.State.Fetching
              }
            , Cmd.batch
                [ getRandomGif url
                , getRandomGifUnboxed url
                ]
            )

        MsgFetching ->
            ( { model
                | httpUrl = ""
                , httpState = Http.State.Fetching
                , httpStateRaw = Http.State.Fetching
                , httpStateUnboxed = Http.State.Fetching
                , httpStateRawUnboxed = Http.State.Fetching
              }
            , Cmd.none
            )

        MsgNotRequested ->
            ( { model
                | httpUrl = ""
                , httpState = Http.State.NotRequested
                , httpStateRaw = Http.State.NotRequested
                , httpStateUnboxed = Http.State.NotRequested
                , httpStateRawUnboxed = Http.State.NotRequested
              }
            , Cmd.none
            )

        GotGif result ->
            ( { model
                | httpResult = Just result
                , httpState = Http.State.Complete (Http.Plus.expectPlus result (Just decoderBodyResponse))
                , httpStateRaw = Http.State.Complete (Http.Plus.expectPlus result Nothing)
              }
            , Cmd.none
            )

        GotGifUnboxed result ->
            ( { model
                | httpResultUnboxed = Just result
                , httpStateUnboxed = Http.State.Complete (Http.Plus.expectPlus result (Just decoderBodyResponse))
                , httpStateRawUnboxed = Http.State.Complete (Http.Plus.expectPlus result Nothing)
              }
            , Cmd.none
            )



{-
   ██   ██ ████████ ████████ ██████
   ██   ██    ██       ██    ██   ██
   ███████    ██       ██    ██████
   ██   ██    ██       ██    ██
   ██   ██    ██       ██    ██
-}


getRandomGif : String -> Cmd Msg
getRandomGif url =
    Http.get
        { url = url
        , expect = Http.expectStringResponse GotGif (\response -> Ok response)

        {-
           expect = Http.Boxed.expectStringResponse GotGif Http.Extras.responseToJson)
           expect = Http.Boxed.expectBytes GotGif byteDecoder )
        -}
        }


getRandomGifUnboxed : String -> Cmd Msg
getRandomGifUnboxed url =
    Http.get
        { url = url
        , expect = Http.expectStringResponse GotGifUnboxed Http.Boxed.unboxResponse
        }


toGiphyUrl : String -> String
toGiphyUrl topic =
    Url.Builder.crossOrigin "https://api.giphy.com"
        [ "v1", "gifs", "random" ]
        [ Url.Builder.string "api_key" "dc6zaTOxFJmzC"
        , Url.Builder.string "tag" topic
        ]



{-
   ██    ██ ██ ███████ ██     ██
   ██    ██ ██ ██      ██     ██
   ██    ██ ██ █████   ██  █  ██
    ██  ██  ██ ██      ██ ███ ██
     ████   ██ ███████  ███ ███
-}


gray1 : Color
gray1 =
    rgb 0.7 0.7 0.7


color2 : Color
color2 =
    -- rgb(191, 0, 0)
    rgb (191 / 255) (0 / 255) (0 / 255)


color3 : Color
color3 =
    -- rgba(34, 89, 74, 0.72)
    rgb (255 / 255) (255 / 255) (255 / 255)


attrTitle : List (Attr decorative msg)
attrTitle =
    [ Font.color <| gray1
    ]


activeAttrs : List (Attr decorative msg)
activeAttrs =
    [ moveRight 30 ]


notActiveAttrs : List (Attr decorative msg)
notActiveAttrs =
    [ moveRight 30, Font.color gray1 ]


attrCond1 :
    { a | httpStateUnboxed : Http.State.State body }
    -> String
    -> List (Attr decorative msg)
attrCond1 model type_ =
    let
        active =
            stringFromState model.httpStateUnboxed == type_
    in
    if active then
        activeAttrs

    else
        notActiveAttrs


attrCond2 :
    { a | httpStateUnboxed : Http.State.State body }
    -> String
    -> List (Attr decorative msg)
attrCond2 model type_ =
    let
        active =
            case model.httpStateUnboxed of
                Http.State.Complete res ->
                    case res of
                        Err err ->
                            stringFromError err == type_

                        _ ->
                            False

                _ ->
                    False
    in
    if active then
        activeAttrs

    else
        notActiveAttrs


attrCond3 :
    { a | httpStateUnboxed : Http.State.State body }
    -> String
    -> List (Attr decorative msg)
attrCond3 model type_ =
    let
        active =
            case model.httpStateUnboxed of
                Http.State.Complete res ->
                    case res of
                        Err err ->
                            case err of
                                Http.Plus.BadStatus body ->
                                    stringFromResponseData body == type_

                                _ ->
                                    False

                        Ok body ->
                            stringFromResponseData body == type_

                _ ->
                    False
    in
    if active then
        activeAttrs

    else
        notActiveAttrs


longTextAttrs : List (Attribute msg)
longTextAttrs =
    [ height <| px 80
    , scrollbarY
    , htmlAttribute <| Html.Attributes.style "word-break" "break-all"
    , Border.width 1
    , Border.color <| rgb 0.85 0.85 0.85
    , padding 6
    ]


githubIcon color size =
    Svg.svg [ SA.xmlBase "http://www.w3.org/2000/svg", SA.width <| String.fromInt size ++ "px", SA.viewBox "0 0 438.55 438.55" ]
        [ Svg.path [ SA.fill color, SA.d "M409.13 114.57a218.32 218.32 0 0 0-79.8-79.8c-33.6-19.6-70.27-29.4-110.06-29.4-39.78 0-76.47 9.8-110.06 29.4a218.3 218.3 0 0 0-79.8 79.8C9.8 148.17 0 184.85 0 224.63c0 47.78 13.94 90.75 41.83 128.9 27.88 38.17 63.9 64.58 108.06 79.23 5.14.96 8.95.29 11.42-2a11.17 11.17 0 0 0 3.71-8.55l-.14-15.42c-.1-9.71-.15-18.18-.15-25.4l-6.56 1.13c-4.2.77-9.47 1.09-15.85 1-6.38-.1-13-.76-19.84-2a44.34 44.34 0 0 1-19.13-8.56 36.23 36.23 0 0 1-12.56-17.56l-2.86-6.57c-1.9-4.37-4.9-9.23-8.99-14.55-4.1-5.34-8.23-8.95-12.42-10.85l-2-1.43a20.96 20.96 0 0 1-3.7-3.43c-1.15-1.33-2-2.67-2.58-4-.57-1.33-.1-2.43 1.43-3.29 1.52-.86 4.28-1.27 8.28-1.27l5.7.85c3.81.76 8.52 3.04 14.14 6.85a46.08 46.08 0 0 1 13.85 14.84c4.38 7.8 9.65 13.76 15.84 17.85 6.19 4.1 12.42 6.13 18.7 6.13 6.28 0 11.7-.47 16.28-1.42a56.79 56.79 0 0 0 12.84-4.28c1.72-12.76 6.38-22.56 14-29.41a195.5 195.5 0 0 1-29.27-5.14c-8.66-2.29-17.6-6-26.84-11.14-9.23-5.14-16.9-11.52-22.98-19.13-6.1-7.61-11.1-17.61-14.99-29.98-3.9-12.37-5.85-26.65-5.85-42.82 0-23.04 7.52-42.64 22.55-58.82-7.04-17.32-6.37-36.73 2-58.24 5.52-1.72 13.7-.43 24.56 3.85 10.85 4.28 18.79 7.95 23.84 11 5.04 3.04 9.08 5.61 12.13 7.7 17.7-4.94 35.98-7.42 54.82-7.42s37.12 2.48 54.82 7.42l10.85-6.85c7.42-4.57 16.18-8.75 26.26-12.56 10.1-3.8 17.8-4.85 23.14-3.14 8.56 21.51 9.32 40.92 2.28 58.24 15.03 16.18 22.55 35.79 22.55 58.82 0 16.18-1.95 30.5-5.85 42.96-3.9 12.48-8.94 22.46-15.12 29.98a79.82 79.82 0 0 1-23.13 18.99c-9.24 5.14-18.19 8.85-26.84 11.14a195.3 195.3 0 0 1-29.27 5.14c9.9 8.56 14.84 22.08 14.84 40.54v60.24c0 3.42 1.2 6.28 3.58 8.56 2.38 2.28 6.13 2.95 11.27 2 44.17-14.66 80.19-41.07 108.07-79.23 27.88-38.16 41.83-81.13 41.83-128.9-.01-39.78-9.82-76.46-29.42-110.06z" ] []
        ]


rakutenColor : String -> Int -> Html.Html msg
rakutenColor cl size =
    Svg.svg [ Html.Attributes.style "height" (String.fromInt size ++ "px"), SA.viewBox "0 0 166 49.4" ]
        [ Svg.path
            [ SA.fill cl
            , SA.d "M41.2 49.4l92.3-8H33.2l8 8zm1.3-14.3v1.2h6.2V9.1h-6.2v1.2a10 10 0 0 0-5.8-1.9c-7 0-12.4 6.4-12.4 14.3S29.6 37 36.7 37c2.3 0 4-.7 5.8-1.9zM30.7 22.7c0-4.3 2.5-7.7 6-7.7s5.9 3.4 5.9 7.7c0 4.3-2.5 7.7-5.9 7.7-3.5 0-6-3.4-6-7.7zm56 14.3c3 0 5.3-1.7 5.3-1.7v1h6.2V9.1H92v16c0 3-2.1 5.5-5.1 5.5s-5.1-2.5-5.1-5.5v-16h-6.2v16c0 6.6 4.5 11.9 11.1 11.9zm68.2-28.6c-3 0-5.3 1.7-5.3 1.7v-1h-6.2v27.2h6.2v-16c0-3 2.1-5.5 5.1-5.5s5.1 2.5 5.1 5.5v16h6.2v-16c0-6.6-4.5-11.9-11.1-11.9zM22.4 14c0-6.5-5.3-11.7-11.7-11.7H0v34h6.5V25.8h4.6L19 36.3h8.1l-9.6-12.7c3-2.1 4.9-5.6 4.9-9.6zm-11.7 5.3H6.5V8.7h4.2c2.9 0 5.3 2.4 5.3 5.3s-2.4 5.3-5.3 5.3zm92.9 8c0 6.1 4.6 9.7 9.2 9.7a13 13 0 0 0 6-1.7l-4-5.4c-.6.4-1.3.7-2.1.7-1 0-2.9-.8-2.9-3.3V15.6h5.3V9.1h-5.3V2.3h-6.2v6.8h-3.3v6.5h3.3v11.7zm-45.1-2.2l9.2 11.2h8.6L64 21.8 74.6 9.1H66l-7.5 9.5V0h-6.3v36.3h6.3V25.1zm70.6-16.7c-7.2 0-12.3 6.3-12.3 14.3 0 8.4 6.4 14.3 12.9 14.3 3.3 0 7.4-1.1 10.9-6.1l-5.5-3.2c-4.2 6.2-11.3 3.1-12.1-3.2h17.8c1.7-9.7-4.7-16.1-11.7-16.1zm-5.7 10.8c1.3-6.4 9.9-6.8 11.1 0h-11.1z"
            ]
            []
        ]


tridentIcon : String -> Int -> Html.Html msg
tridentIcon cl size =
    Svg.svg [ Html.Attributes.style "height" (String.fromInt size ++ "px"), SA.viewBox "0 0 424.25 424.25" ]
        [ Svg.path [ SA.fill cl, SA.d "M349.57 218.87l-64.38 64.37c-29.98 30-74.19 37.34-111.17 22.05L152.03 329a132.91 132.91 0 0 0 61.07 14.83c34 0 67.99-12.93 93.86-38.8l64.39-64.4-4.42-17.33-17.36-4.42zM283.95 140.3l-18.78-4.78L9.48 372.86a29.67 29.67 0 0 0 20.18 51.4l.55-.02a29.64 29.64 0 0 0 21.18-9.47l237.35-255.7-4.79-18.76zM118.97 250.24c-15.3-36.99-7.96-81.19 22.04-111.18L205.4 74.7l-4.42-17.36-17.34-4.42-64.39 64.38a132.3 132.3 0 0 0-38.8 93.86c0 21 4.96 41.99 14.83 61.07l23.7-21.98z" ] []
        , Svg.path [ SA.fill cl, SA.d "M170.44 33.66l43.18 11.02 11 43.17a3.37 3.37 0 0 0 3.16 2.52h.1c1.44 0 2.74-.93 3.18-2.32l27.06-83.66a3.35 3.35 0 0 0-4.21-4.22l-83.67 27.06a3.34 3.34 0 0 0 .2 6.43zM250.92 113.5a3.36 3.36 0 0 0 2.52 3.14l43.17 11 11.01 43.19a3.36 3.36 0 0 0 3.14 2.52l.11-.01c1.45 0 2.74-.93 3.18-2.31l27.06-83.66a3.35 3.35 0 0 0-4.22-4.22l-83.65 27.06a3.36 3.36 0 0 0-2.32 3.29zM423.27 166.94a3.36 3.36 0 0 0-3.4-.8l-83.66 27.05a3.34 3.34 0 0 0 .2 6.43l43.17 11.02 11.01 43.17a3.36 3.36 0 0 0 3.15 2.52h.1c1.45 0 2.74-.93 3.18-2.32l27.07-83.66c.4-1.2.07-2.51-.81-3.4z" ] []
        ]


viewHeader : a -> Element msg
viewHeader model =
    row
        [ Background.color color2
        , Font.color color3
        , width fill
        , paddingXY 40 30
        , Font.size 20
        , spacing 20
        ]
        [ row [ spacing 40 ]
            [ el [] <| html <| tridentIcon "#eeeeee" 50
            , column [ spacing 10 ]
                [ el [ Font.size 30 ] <| text "Http Trinity"
                , el [ Font.size 20 ] <| text "Http.Boxed ＋ Http.Plus ＋ Http.State"
                ]
            ]
        , link [ alignRight ]
            { url = "https://github.com/rakutentech/http-trinity"
            , label =
                row [ spacing 20 ]
                    [ el [] <| text "Github"
                    , el [] <| html <| githubIcon "#ffffff" 30
                    ]
            }
        ]


viewFooter =
    wrappedRow
        [ centerX
        , paddingXY 40 40
        , Background.color <| rgb 0.9 0.9 0.9
        , width fill
        , Font.color <| rgb 0.6 0.6 0.6
        ]
        [ column [ spacing 5 ]
            [ wrappedRow []
                [ text "Made with "
                , el [ Font.color <| rgb255 191 0 0 ] <| text "❤"
                , text " and "
                , link [] { label = text "Elm", url = "https://elm-lang.org/" }
                ]
            , link [] { label = text "Rakuten Open Source", url = "https://github.com/rakutentech" }
            ]
        , column [ alignRight, spacing 14 ]
            [ link [ alignRight ] { label = html <| rakutenColor "#bf0000" 20, url = "https://global.rakuten.com/corp/" }
            , text "© 2019 Rakuten"
            ]
        ]


view : Model -> Html.Html Msg
view model =
    let
        commonAttr =
            [ width <| px 70
            ]

        statusCode =
            case model.httpStateUnboxed of
                Http.State.Complete result ->
                    case result of
                        Ok response ->
                            case response of
                                Http.Plus.Decoded metadata _ ->
                                    Ok metadata.statusCode

                                Http.Plus.Raw metadata _ _ ->
                                    Ok metadata.statusCode

                        Err err ->
                            case err of
                                Http.Plus.BadStatus response ->
                                    case response of
                                        Http.Plus.Decoded metadata _ ->
                                            Ok metadata.statusCode

                                        Http.Plus.Raw metadata _ _ ->
                                            Ok metadata.statusCode

                                _ ->
                                    Err <| "BadUrl, Timeout or NetworkError"

                _ ->
                    Err "Request is not Complete"
    in
    layoutWith
        { options =
            [ focusStyle
                { borderColor = Just color2
                , backgroundColor = Nothing
                , shadow = Nothing
                }
            ]
        }
        [ Font.family
            [ Font.typeface "Noto Sans"
            , Font.sansSerif
            ]
        ]
    <|
        column [ width fill, Font.size 15 ]
            [ viewHeader model
            , row [ spacing 20, padding 20, width fill ]
                [ column [ spacing 20, alignTop, width fill ]
                    [ column [ spacing 4 ]
                        [ wrappedRow [ spacing 4 ]
                            [ paragraph commonAttr [ text "Status" ]
                            , viewButton2 model Http.State.NotRequested MsgNotRequested "Not Requested"
                            , viewButton2 model Http.State.Fetching MsgFetching "Fetching"
                            ]
                        , wrappedRow [ spacing 4 ]
                            [ paragraph commonAttr [ text "Unboxed" ]
                            , viewButton model "api-tests/unboxed.json" "200"
                            , viewButton model "api-tests/unboxedEmptyJson.json" "\"{}\" 200"
                            , viewButton model "api-tests/unboxedEmptyString.json" "\"\" 200"
                            ]
                        , wrappedRow [ spacing 4 ]
                            [ paragraph commonAttr [ text "Boxed" ]
                            , viewButton model "api-tests/boxed200.json" "200"
                            , viewButton model "api-tests/boxed200EmptyJson.json" "\"{}\" 200"
                            , viewButton model "api-tests/boxed200EmptyString.json" "\"\" 200"
                            , viewButton model "api-tests/boxed401.json" "401"
                            , viewButton model "api-tests/boxed401EmptyJson.json" "\"{}\" 401"
                            , viewButton model "api-tests/boxed401EmptyString.json" "\"\" 401"
                            , viewButton model "api-tests/boxed401Headers.json" "401 Headers"
                            ]
                        , wrappedRow [ spacing 4 ]
                            [ paragraph commonAttr [ text "Others" ]
                            , viewButton model (toGiphyUrl "cat") "Real API call"
                            , viewButton model "api-tests/unexistingFile.json" "Unexisting File"
                            , viewButton model "https://" "Bad Url"
                            , viewButton model "https://unexistingDomain.com" "Unexisting Domain"
                            ]
                        ]
                    , column [ Font.family [ Font.monospace ] ]
                        [ paragraph [] [ text "type State body" ]
                        , paragraph (attrCond1 model "NotRequested") [ text "= NotRequested" ]
                        , paragraph (attrCond1 model "Fetching") [ text "| Fetching" ]
                        , paragraph (attrCond1 model "Complete") [ text "| Complete (Result (Error body) (ResponseData body))" ]
                        ]
                    , column [ Font.family [ Font.monospace ] ]
                        [ paragraph [] [ text "type Error body" ]
                        , paragraph (attrCond2 model "BadStatus") [ text "= BadStatus (ResponseData body)" ]
                        , paragraph (attrCond2 model "BadUrl") [ text "| BadUrl String" ]
                        , paragraph (attrCond2 model "Timeout") [ text "| Timeout" ]
                        , paragraph (attrCond2 model "NetworkError") [ text "| NetworkError" ]
                        ]
                    , column [ Font.family [ Font.monospace ] ]
                        [ paragraph [] [ text "type ResponseData body" ]
                        , paragraph (attrCond3 model "Decoded") [ text "= Decoded Http.Metadata body" ]
                        , paragraph (attrCond3 model "Raw") [ text "| Raw Http.Metadata String String" ]
                        ]
                    , paragraph attrTitle [ text <| "Json content" ]
                    , el [ width fill ] <|
                        html <|
                            Html.iframe
                                [ Html.Attributes.style "border" "1px solid #ddd"
                                , Html.Attributes.style "width" "100%"
                                , Html.Attributes.style "height" "100px"
                                , Html.Attributes.src model.httpUrl
                                ]
                                []
                    ]

                --
                --  SECOND COLUMN
                --
                , column [ spacing 20, width fill, alignTop ]
                    [ paragraph attrTitle [ text <| "Http.State.isSuccess" ]
                    , paragraph [] [ text <| Debug.toString <| Http.State.isSuccess model.httpStateUnboxed ]

                    --
                    , paragraph attrTitle [ text <| "Http.State.statusCode" ]
                    , paragraph [] [ text <| Debug.toString <| Http.State.statusCode model.httpStateUnboxed ]

                    --
                    , paragraph attrTitle [ text <| "Http.State.statusText" ]
                    , paragraph [] [ text <| Debug.toString <| Http.State.statusText model.httpStateUnboxed ]

                    --
                    , paragraph attrTitle [ text <| "Http.State.url" ]
                    , paragraph [] [ text <| Debug.toString <| Http.State.url model.httpStateUnboxed ]

                    --
                    , paragraph attrTitle [ text <| "Http.State.headers" ]
                    , paragraph [] [ text <| Debug.toString <| Http.State.headers model.httpStateUnboxed ]

                    --
                    , paragraph attrTitle [ text <| "Http.State.header \"last-modified\"" ]
                    , paragraph [] [ text <| Debug.toString <| Http.State.header model.httpStateUnboxed "last-modified" ]

                    --
                    , paragraph attrTitle [ text <| "Http.State.responseData" ]
                    , paragraph [] [ text <| Debug.toString <| Http.State.responseData model.httpStateUnboxed ]
                    ]
                ]
            , viewFooter
            ]


buttonAttributes : List (Attribute msg)
buttonAttributes =
    [ padding 5
    , Border.width 1
    , Font.size 14
    ]


viewButton : { a | httpUrl : String } -> String -> String -> Element Msg
viewButton model httpUrl description =
    Input.button
        (buttonAttributes
            ++ (if httpUrl == model.httpUrl then
                    [ Background.color color2, Font.color color3 ]

                else
                    []
               )
        )
        { label = text description
        , onPress = Just <| MorePlease httpUrl
        }


viewButton2 : { b | httpState : a } -> a -> msg -> String -> Element msg
viewButton2 model type_ msg description =
    Input.button
        (buttonAttributes
            ++ (if model.httpState == type_ then
                    [ Background.color color2, Font.color color3 ]

                else
                    []
               )
        )
        { label = text description
        , onPress = Just msg
        }



{-
   ██████  ███████  ██████  ██████  ██████  ███████ ██████  ███████
   ██   ██ ██      ██      ██    ██ ██   ██ ██      ██   ██ ██
   ██   ██ █████   ██      ██    ██ ██   ██ █████   ██████  ███████
   ██   ██ ██      ██      ██    ██ ██   ██ ██      ██   ██      ██
   ██████  ███████  ██████  ██████  ██████  ███████ ██   ██ ███████
-}
-- from https://becoming-functional.com/handling-real-world-json-data-in-elm-c1816c7b3620


type alias Imageurl =
    { image_url : String
    }


type alias Error =
    { key : String
    , value : String
    }


type BodyResponse
    = Success Imageurl
    | Errors (List Error)


type alias ImageurlValidResponse =
    { data : Imageurl
    }


type alias ErrorObject =
    { errors : List Error
    }


imageurlDecoder : Json.Decode.Decoder Imageurl
imageurlDecoder =
    Json.Decode.succeed Imageurl
        |> Json.Decode.Pipeline.required "image_url" Json.Decode.string


userResponseDecoder : Json.Decode.Decoder ImageurlValidResponse
userResponseDecoder =
    Json.Decode.succeed ImageurlValidResponse
        |> Json.Decode.Pipeline.required "data" imageurlDecoder


errorDecoder : Json.Decode.Decoder Error
errorDecoder =
    Json.Decode.succeed Error
        |> Json.Decode.Pipeline.required "key" Json.Decode.string
        |> Json.Decode.Pipeline.required "value" Json.Decode.string


errorListDecoder : Json.Decode.Decoder (List Error)
errorListDecoder =
    Json.Decode.list errorDecoder


errorResponseDecoder : Json.Decode.Decoder ErrorObject
errorResponseDecoder =
    Json.Decode.succeed ErrorObject
        |> Json.Decode.Pipeline.required "errors" errorListDecoder


successResponse : Json.Decode.Decoder BodyResponse
successResponse =
    Json.Decode.map
        (\response -> Success response.data)
        userResponseDecoder


errorResponse : Json.Decode.Decoder BodyResponse
errorResponse =
    Json.Decode.map
        (\response -> Errors response.errors)
        errorResponseDecoder


decoderBodyResponse : Json.Decode.Decoder BodyResponse
decoderBodyResponse =
    Json.Decode.oneOf
        [ successResponse
        , errorResponse
        ]



{-
   ████████  ██████      ███████ ████████ ██████  ██ ███    ██  ██████
      ██    ██    ██     ██         ██    ██   ██ ██ ████   ██ ██
      ██    ██    ██     ███████    ██    ██████  ██ ██ ██  ██ ██   ███
      ██    ██    ██          ██    ██    ██   ██ ██ ██  ██ ██ ██    ██
      ██     ██████      ███████    ██    ██   ██ ██ ██   ████  ██████
-}


stringFromError : Http.Plus.Error body -> String
stringFromError res =
    case res of
        Http.Plus.BadStatus _ ->
            "BadStatus"

        Http.Plus.BadUrl _ ->
            "BadUrl"

        Http.Plus.Timeout ->
            "Timeout"

        Http.Plus.NetworkError ->
            "NetworkError"


stringFromResponseData : Http.Plus.ResponseData body -> String
stringFromResponseData res =
    case res of
        Http.Plus.Decoded _ _ ->
            "Decoded"

        Http.Plus.Raw _ _ _ ->
            "Raw"


encodeMetadata : Http.Metadata -> Json.Encode.Value
encodeMetadata metadata =
    Json.Encode.object
        [ ( "url", Json.Encode.string <| metadata.url )
        , ( "statusCode", Json.Encode.int <| metadata.statusCode )
        , ( "statusText", Json.Encode.string <| metadata.statusText )
        , ( "headers", Json.Encode.dict identity Json.Encode.string metadata.headers )
        ]


stringFromState : Http.State.State body -> String
stringFromState state =
    case state of
        Http.State.NotRequested ->
            "NotRequested"

        Http.State.Fetching ->
            "Fetching"

        Http.State.Complete _ ->
            "Complete"



{-
   ███    ███  █████  ██ ███    ██
   ████  ████ ██   ██ ██ ████   ██
   ██ ████ ██ ███████ ██ ██ ██  ██
   ██  ██  ██ ██   ██ ██ ██  ██ ██
   ██      ██ ██   ██ ██ ██   ████
-}


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , subscriptions = \_ -> Sub.none
        , view = view
        }
