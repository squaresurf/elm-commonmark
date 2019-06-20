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
            [ test "Example 481" <|
                \_ ->
                    testMarkdown "[link](/uri \"title\")\n"
                        [ Html.p []
                            [ Html.a [ Attr.href "/uri", Attr.title "title" ] [ Html.text "link" ]
                            ]
                        ]
            , test "Example 482" <|
                \_ ->
                    testMarkdown "[link](/uri)\n"
                        [ Html.p []
                            [ Html.a [ Attr.href "/uri" ] [ Html.text "link" ]
                            ]
                        ]
            , test "Example 483" <|
                \_ ->
                    testMarkdown "[link]()\n"
                        [ Html.p []
                            [ Html.a [ Attr.href "" ] [ Html.text "link" ]
                            ]
                        ]
            , test "Example 484" <|
                \_ ->
                    testMarkdown "[link](<>)\n"
                        [ Html.p []
                            [ Html.a [ Attr.href "" ] [ Html.text "link" ]
                            ]
                        ]
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
