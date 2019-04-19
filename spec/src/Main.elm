module Main exposing (main)

import Browser
import CommonMark
import Html exposing (Attribute, Html, div, text, textarea)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput)



-- MAIN


main =
    Browser.sandbox { init = init, update = update, view = view }



-- MODEL


type alias Model =
    { markdown : String
    , parsedMarkdown : Html Msg
    }


init : Model
init =
    { markdown = "", parsedMarkdown = text "" }



-- UPDATE


type Msg
    = Change String


update : Msg -> Model -> Model
update msg model =
    case msg of
        Change newMarkdown ->
            { model | markdown = newMarkdown, parsedMarkdown = CommonMark.toHtml newMarkdown }



-- VIEW


view : Model -> Html Msg
view model =
    div []
        [ textarea [ id "markdown_input", placeholder "Markdown", value model.markdown, onInput Change ] []
        , div [ id "parsed_markdown" ] [ model.parsedMarkdown ]
        ]
