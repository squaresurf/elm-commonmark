module CommonMark exposing (toHtml)

import Html exposing (Html)
import Html.Attributes as Attr
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
        , Parser.succeed identity
            |= inlineMdParser
            |> Parser.andThen
                (\inline ->
                    if List.isEmpty inline then
                        Parser.problem "At the end."

                    else
                        Parser.succeed <| Loop (Html.p [] inline :: html)
                )
        , Parser.succeed ()
            |> Parser.map (\_ -> Done (List.reverse html))
        ]


inlineMdParser : Parser (List (Html msg))
inlineMdParser =
    Parser.loop [] inlineParser


inlineParser : List (Html msg) -> Parser (Step (List (Html msg)) (List (Html msg)))
inlineParser html =
    Parser.oneOf
        [ Parser.succeed (\text url -> Loop (Html.a [ Attr.href url ] [ Html.text text ] :: html))
            |. Parser.symbol "["
            |= Parser.getChompedString
                (Parser.chompWhile (\c -> c /= ']'))
            |. Parser.symbol "]"
            |. Parser.symbol "("
            |= Parser.getChompedString
                (Parser.chompWhile (\c -> c /= ')'))
            |. Parser.symbol ")"
        , Parser.succeed (\before str after -> ( before, str, after ))
            |= Parser.getOffset
            |= Parser.getChompedString
                (Parser.chompUntilEndOr "\n\n")
            |= Parser.getOffset
            |> Parser.andThen
                (\( before, str, after ) ->
                    if before < after then
                        Parser.succeed <|
                            Loop (Html.text (String.trim str) :: html)

                    else
                        Parser.problem str
                )
        , Parser.succeed ()
            |> Parser.map (\_ -> Done (List.reverse html))
        ]
