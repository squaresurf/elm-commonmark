module CommonMarkTests exposing (suite)

import CommonMark
import Debug exposing (toString)
import Expect
import Html
import Test exposing (Test, describe, test)
import Test.Html.Query as Query
import Test.Html.Selector as Selector


suite : Test
suite =
    describe "CommonMark"
        [ describe "Tabs"
            [ test "Basic CodeFence" <|
                \_ ->
                    case CommonMark.toHtml "\tfoo\tbaz\t\tbim\n" of
                        Ok html ->
                            html
                                |> Html.div []
                                |> Query.fromHtml
                                |> Query.contains
                                    [ Html.pre [] [ Html.code [] [ Html.text "foo\tbaz\t\tbim\n" ] ]
                                    ]

                        Err err ->
                            Expect.fail <| toString err
            ]
        ]
