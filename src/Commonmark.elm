module CommonMark exposing (toHtml)

import Html exposing (Html)


toHtml : List (Html.Attribute msg) -> String -> Html msg
toHtml htmlAttr markdown =
    Html.em [] [ Html.text "foo bar" ]
