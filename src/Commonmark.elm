module CommonMark exposing (toHtml)

import Html exposing (Html)
import Parser exposing ((|.), (|=), Parser, Step(..))


toHtml : String -> Result (List Parser.DeadEnd) (List (Html msg))
toHtml markdown =
    Parser.run mdParser markdown


mdParser : Parser (List (Html msg))
mdParser =
    Parser.loop [] blockParser


blockParser : List (Html msg) -> Parser (Step (List (Html msg)) (List (Html msg)))
blockParser html =
    Parser.oneOf
        [ Parser.succeed (Loop html) |. Parser.symbol "\n"
        , Parser.succeed
            (\t ->
                Loop
                    (Html.pre [] [ Html.code [] [ Html.text t ] ]
                        :: html
                    )
            )
            |. Parser.symbol "\t"
            |= Parser.getChompedString (Parser.chompUntilEndOr "\n\n")
        , Parser.succeed (\before str after -> ( before, str, after ))
            |= Parser.getOffset
            |= Parser.getChompedString
                (Parser.chompUntilEndOr "\n\n")
            |= Parser.getOffset
            |> Parser.andThen
                (\( before, str, after ) ->
                    if before < after then
                        Parser.succeed <|
                            Loop (Html.p [] [ Html.text <| String.trim str ] :: html)

                    else
                        Parser.problem str
                )
        , Parser.succeed ()
            |> Parser.map (\_ -> Done (List.reverse html))
        ]
