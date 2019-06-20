module Main exposing (main)

import Browser
import CommonMark
import Debug
import Html exposing (Attribute, Html, div, p, text, textarea)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput)



-- MAIN


main =
    Browser.sandbox { init = init, update = update, view = view }



-- MODEL


type alias Model =
    { markdown : String
    , parsedMarkdown : List (Html Msg)
    , error : Maybe String
    }


init : Model
init =
    { markdown = "", parsedMarkdown = [ text "" ], error = Nothing }



-- UPDATE


type Msg
    = Change String


update : Msg -> Model -> Model
update msg model =
    case msg of
        Change newMarkdown ->
            case CommonMark.toHtml newMarkdown of
                Ok newHtml ->
                    { model
                        | markdown = newMarkdown
                        , parsedMarkdown = newHtml
                        , error = Nothing
                    }

                Err e ->
                    { model
                        | markdown = newMarkdown
                        , parsedMarkdown = [ text "" ]
                        , error = Just <| Debug.toString e
                    }



-- VIEW


view : Model -> Html Msg
view model =
    div []
        [ textarea [ id "markdown_input", placeholder "Markdown", value model.markdown, onInput Change ] []
        , div [ id "parsed_markdown" ] model.parsedMarkdown
        , div [] [ errorView model ]
        ]


errorView : Model -> Html Msg
errorView model =
    case model.error of
        Nothing ->
            p [] []

        Just err ->
            p [ style "color" "red" ] [ text err ]
