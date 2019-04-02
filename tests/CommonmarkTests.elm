module CommonMarkTests exposing (suite)

import CommonMark
import Test exposing (Test, describe, test)
import Test.Html.Query as Query
import Test.Html.Selector as Selector


suite : Test
suite =
    describe "CommonMark"
        [ test "emphasis" <|
            \_ ->
                "*foo bar*"
                    |> CommonMark.toHtml []
                    |> Query.fromHtml
                    |> Query.has [ Selector.all [ Selector.tag "em", Selector.text "foo bar" ] ]
        ]
