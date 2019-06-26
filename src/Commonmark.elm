module CommonMark exposing (toHtml)

import Html exposing (Attribute, Html)
import Html.Attributes as Attr
import Parser exposing ((|.), (|=), Parser, Step(..))


type PartialHtml
    = Text String


type alias InlineLoopState msg =
    { endTerm : String
    , html : List (Html msg)
    , partialHtml : Maybe PartialHtml
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



-- Inline Parsers --


inlineMdParser : String -> Parser (List (Html msg))
inlineMdParser endTerm =
    Parser.loop (InlineLoopState "\n\n" [] Nothing) inlineParser


inlineParser : InlineLoopState msg -> Parser (Step (InlineLoopState msg) (List (Html msg)))
inlineParser state =
    Parser.oneOf
        [ Parser.succeed (Done <| finishInlineParser state)
            |. Parser.token "\n\n"
        , linkParser
            |> Parser.map (\html -> Loop <| appendHtmlState html state)
        , Parser.succeed (\str -> Loop <| appendPartialHtmlState (Text str) state)
            |= Parser.getChompedString (Parser.chompIf (\_ -> True))
        , Parser.succeed ()
            |> Parser.map (\_ -> Done <| finishInlineParser state)
        ]


linkParser : Parser (Html msg)
linkParser =
    Parser.backtrackable <|
        Parser.succeed (\text attrs -> Html.a attrs [ Html.text text ])
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
        |= Parser.oneOf
            [ Parser.succeed (\href -> String.replace " " "%20" href)
                |. Parser.token "<"
                |= Parser.getChompedString
                    (Parser.chompWhile (\c -> c /= '\n' && c /= '>'))
                |. Parser.token ">"
            , Parser.succeed identity
                |= Parser.getChompedString
                    (Parser.chompWhile (\c -> c /= ' ' && c /= '\n' && c /= endTerm))
            ]
        |. Parser.spaces
        |= Parser.oneOf
            [ Parser.succeed (\t -> Just t)
                |. Parser.token "\""
                |= Parser.getChompedString (Parser.chompWhile (\c -> c /= '"'))
                |. Parser.token "\""
            , Parser.succeed Nothing
            ]



-- Loop State Functions --


appendHtmlState : Html msg -> InlineLoopState msg -> InlineLoopState msg
appendHtmlState html state =
    state
        |> completeHtmlState
        |> updateHtml html


updateHtml : Html msg -> InlineLoopState msg -> InlineLoopState msg
updateHtml html state =
    { state | html = html :: state.html }


appendPartialHtmlState : PartialHtml -> InlineLoopState msg -> InlineLoopState msg
appendPartialHtmlState partial state =
    case partial of
        Text str ->
            case state.partialHtml of
                Nothing ->
                    { state | partialHtml = Just partial }

                Just currentPartial ->
                    case currentPartial of
                        Text partialStr ->
                            { state | partialHtml = Just <| Text <| String.append partialStr str }


completeHtmlState : InlineLoopState msg -> InlineLoopState msg
completeHtmlState state =
    case state.partialHtml of
        Nothing ->
            state

        Just partial ->
            { state | html = List.concat [ completeHtml partial, state.html ], partialHtml = Nothing }


completeHtml : PartialHtml -> List (Html msg)
completeHtml partial =
    case partial of
        Text str ->
            let
                trimmed =
                    String.trim str
            in
            if String.isEmpty trimmed then
                []

            else
                [ Html.text trimmed ]


finishInlineParser : InlineLoopState msg -> List (Html msg)
finishInlineParser state =
    state
        |> completeHtmlState
        |> .html
        |> List.reverse
