# elm-commonmark
A commonmark markdown parser written completely in Elm.

## CommonMark Spec

The [CommonMark Spec](https://github.com/commonmark/commonmark-spec) is used to generate the
spec/CommonMark-0.29.0.spec.json file. The filename contains the CommonMark version and is used to generate
tests that use [puppeteer](https://pptr.dev/) and elm reactor to test that this implementation follows the
spec. This library will be pre 1.0.0 until it implements the full spec.

You can run the specs via `yarn spec`

Note: the spec script will start elm reactor so make sure that isn't running before running `yarn spec`.

### Slight Deviation

There is a slight deviation from the spec. The spec examples all have an ending newline in their expected html. As
this library is meant to generate html directly to a browser it will omit that ending newline and we
artificially add it to the test expectation.

## Development

Pull requests are welcome. See [DEVELOPMENT.MD](./DEVELOPMENT.MD) for documentation on how to work on this repo.

## License
This project is licensed under the terms of the BSD 3-Clause License.
