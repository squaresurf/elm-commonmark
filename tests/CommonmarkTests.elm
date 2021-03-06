module CommonMarkTests exposing (suite)

import CommonMark
import Debug exposing (toString)
import Expect
import Html exposing (Html)
import Html.Attributes as Attr
import Test exposing (Test, describe, test)
import Test.Html.Query as Query
import Test.Html.Selector as Selector


suite : Test
suite =
    describe "CommonMark"
        -- TODO test all chompWhiles
        -- TODO write fuzz tests that would generate markdown documents longer than the excerpts from the spec
        -- json.
        [ describe "Tabs"
            -- TODO write fuzz tests over a strong mapping to the spec tests
            [ test "Basic CodeFence" <|
                \_ ->
                    testMarkdown "\tfoo\tbaz\t\tbim\n"
                        [ Html.pre [] [ Html.code [] [ Html.text "foo\tbaz\t\tbim\n" ] ]
                        ]
            ]
        , describe "Thematic breaks" <|
            -- TODO write fuzz tests over a strong mapping to the spec tests
            [ test "Three Pluses" <|
                \_ ->
                    testMarkdown "+++" [ Html.p [] [ Html.text "+++" ] ]
            ]
        , describe "Links" <|
            [ test "embedded link" <|
                \_ ->
                    testMarkdown "some text [link](/uri \"title\") some more text\n"
                        [ Html.p []
                            [ Html.text "some text"
                            , Html.a [ Attr.href "/uri", Attr.title "title" ] [ Html.text "link" ]
                            , Html.text "some more text"
                            ]
                        ]
            , test "Example 481" <|
                \_ ->
                    testMarkdown "[link](/uri \"title\")\n"
                        [ Html.p [] [ Html.a [ Attr.href "/uri", Attr.title "title" ] [ Html.text "link" ] ] ]
            , test "Example 482" <|
                \_ ->
                    testMarkdown "[link](/uri)\n"
                        [ Html.p [] [ Html.a [ Attr.href "/uri" ] [ Html.text "link" ] ] ]
            , test "Example 483" <|
                \_ ->
                    testMarkdown "[link]()\n"
                        [ Html.p [] [ Html.a [ Attr.href "" ] [ Html.text "link" ] ] ]
            , test "Example 484" <|
                \_ ->
                    testMarkdown "[link](<>)\n"
                        [ Html.p [] [ Html.a [ Attr.href "" ] [ Html.text "link" ] ] ]
            , test "Example 485" <|
                \_ ->
                    testMarkdown "[link](/my uri)\n"
                        [ Html.p [] [ Html.text "[link](/my uri)" ] ]
            , test "Example 486" <|
                \_ ->
                    testMarkdown "[link](</my uri>)\n"
                        [ Html.p [] [ Html.a [ Attr.href "/my%20uri" ] [ Html.text "link" ] ] ]
            , test "Example 487" <|
                \_ ->
                    testMarkdown "[link](foo\nbar)\n"
                        [ Html.p [] [ Html.text "[link](foo\nbar)" ] ]
            , test "Example 488" <|
                \_ ->
                    testMarkdown "[link](<foo\nbar>)\n"
                        [ Html.p [] [ Html.text "[link](<foo\nbar>)" ] ]
            , test "Example 489" <|
                \_ ->
                    testMarkdown "[a](<b)c>)\n"
                        [ Html.p [] [ Html.a [ Attr.href "b)c" ] [ Html.text "a" ] ] ]
            ]
        ]


testMarkdown : String -> List (Html msg) -> Expect.Expectation
testMarkdown md expectedHtml =
    case CommonMark.toHtml md of
        Ok html ->
            html
                |> Html.div []
                |> Query.fromHtml
                |> Query.contains expectedHtml

        Err err ->
            Expect.fail <| toString err
