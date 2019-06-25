module CommonMark exposing (toHtml)

import Html exposing (Attribute, Html)
import Html.Attributes as Attr
import Parser exposing ((|.), (|=), Parser, Step(..))


type alias InlineLoopState msg =
    { endTerm : String
    , html : List (Html msg)
    }


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
            |= inlineMdParser "\n\n"
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



---------- Inline Parsers ----------


inlineMdParser : String -> Parser (List (Html msg))
inlineMdParser endTerm =
    Parser.loop (InlineLoopState "\n\n" []) inlineParser


inlineParser : InlineLoopState msg -> Parser (Step (InlineLoopState msg) (List (Html msg)))
inlineParser state =
    Parser.oneOf
        [ linkParser state
        , Parser.succeed (\before str after -> ( before, str, after ))
            |= Parser.getOffset
            |= Parser.getChompedString
                (Parser.chompUntilEndOr state.endTerm)
            |= Parser.getOffset
            |> Parser.andThen
                (\( before, str, after ) ->
                    if str == "\n" then
                        Parser.succeed <| Done (List.reverse state.html)

                    else if before < after then
                        Parser.succeed <|
                            Loop { state | html = Html.text (String.trim str) :: state.html }

                    else
                        Parser.problem str
                )
        , Parser.succeed ()
            |> Parser.map (\_ -> Done (List.reverse state.html))
        ]


linkParser : InlineLoopState msg -> Parser (Step (InlineLoopState msg) (List (Html msg)))
linkParser state =
    Parser.backtrackable <|
        Parser.succeed
            (\text attrs ->
                Loop { state | html = Html.a attrs [ Html.text text ] :: state.html }
            )
            |. Parser.symbol "["
            |= Parser.getChompedString (Parser.chompUntil "]")
            |. Parser.symbol "]"
            |. Parser.symbol "("
            |= linkAttrParser ')'
            |. Parser.symbol ")"


linkAttrParser : Char -> Parser (List (Attribute msg))
linkAttrParser endTerm =
    Parser.succeed
        (\url maybeTitle ->
            case maybeTitle of
                Just title ->
                    [ Attr.href url, Attr.title title ]

                Nothing ->
                    [ Attr.href url ]
        )
        |. Parser.oneOf
            [ Parser.succeed identity |. Parser.chompIf (\c -> c == '<')
            , Parser.succeed identity
            ]
        |= Parser.getChompedString
            (Parser.chompWhile (\c -> c /= ' ' && c /= endTerm && c /= '>'))
        |. Parser.oneOf
            [ Parser.succeed identity |. Parser.chompIf (\c -> c == '>')
            , Parser.succeed identity
            ]
        |. Parser.spaces
        |= Parser.oneOf
            [ Parser.succeed (\t -> Just t)
                |. Parser.token "\""
                |= Parser.getChompedString (Parser.chompWhile (\c -> c /= '"'))
                |. Parser.token "\""
            , Parser.succeed Nothing
            ]
