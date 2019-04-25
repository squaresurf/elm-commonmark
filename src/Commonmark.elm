module CommonMark exposing (toHtml)

import Html exposing (Html)
import Parser exposing ((|.), (|=), Parser)


toHtml : String -> Result (List Parser.DeadEnd) (List (Html msg))
toHtml markdown =
    Parser.run mdParser markdown


mdParser : Parser (List (Html msg))
mdParser =
    Parser.succeed (\t -> [ Html.pre [] [ Html.code [] [ Html.text <| String.concat [ t, "\n" ] ] ] ])
        |. Parser.symbol "\t"
        |= (Parser.getChompedString <|
                Parser.succeed ()
                    |. Parser.chompUntilEndOr "\n"
           )
