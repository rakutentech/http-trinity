# Http Trinity

## [Demo](https://rakutentech.github.io/http-trinity/)

This library...

* ..gives more visibility to the http response data. The general concept of Elm is to be friendly to beginners. So the default library, in line with this principle, tend to hide several details of the http response, for example the header of a response or the body, in case of error. This library, trying to keep a simple profile, return all the data as returned by the API server.
* ..makes easy to test all use cases without the need to add and maintain an extra API mock server. Just creating example of responses and saving in static JSON files allow to test all possible scenarios of the application and refine all errors messages, for case when APIs return errors.
* ..offers simple getters to access the response data. In a strictly typed environment is sometime cumbersome to reach down some nested structure. Getters overcome this issue.
* ..provides a simple status wrapper (NotRequested, Fetching, Complete) that can be used in combination with the getters.

## Possible improvements

* Generate the use cases static JSON files directly from Swagger. There is already a project that [convert Swagger into Elm](https://github.com/ahultgren/swagger-elm).
* Wrap completely the elm/http library, or rebuild this package on top of [https://package.elm-lang.org/packages/jzxhuang/http-extras/latest/](https://package.elm-lang.org/packages/jzxhuang/http-extras/latest/).

## Details

The library is composed of three small modules that expand the default Elm Http library:

* Nº1 Http.Plus ⇒ Redefining Error and Response
* Nº2 Http.Boxed ⇒ Mocking APIs the easy way
* Nº3 Http.State ⇒ A simple wrapper

## Nº1 Http.Plus ⇒ Redefining Error and Response

Elm has an official Http package: [elm/http](https://package.elm-lang.org/packages/elm/http/latest) with support for [file uploading and a big bunch of simplifications](https://elm-lang.org/blog/working-with-files).

This is the error type this package produce, in case something goes wrong with an http request:

```elm
type Error
    = BadUrl String
    | Timeout
    | NetworkError
    | BadStatus Int
    | BadBody String
```

For our purpose:

1. In case of `BadStatus`, we still need to access the entire response because the body contains error details and the header contains tokens that we need to send in the following requests
2. In case of `BadBody`, similar issue: we still need to access the header

As explained in the documentation, we can use `expectStringResponse` to get more flexibility than this.

So we created a slightly different type of error:

```elm
type Error body
    = BadUrl String
    | Timeout
    | NetworkError
    | BadStatus (ResponseData body)
```

The differences are:

1. `BadStatus` has a payload of `(ResponseData body)` that contains the header, the body and other meta data
2. `BadBody` disappeared and the concept of an "unexpected body" has been moved inside the `ResponseData`

`ResponseData` is defined as


```elm
type ResponseData body
    = Decoded Http.Metadata body
    | Raw Http.Metadata String String
```

Here there are two possibilities

1. The body has been successfully decoded (`Decoded`)

2. For some reason (either the decoding failed or the decoding has not being attempted), the body is in its raw state (i.e. a `String`). The second string in the `Raw` payload explain way the body has not been decoded

In both the above cases, the type payload includes the header, the body and other meta data as defined in the new http package:

```elm
type alias Metadata =
    { url : String
    , statusCode : Int
    , statusText : String
    , headers : Dict String String
    }
```

So the file type will be

```elm
Result (Error body) (ResponseData body)
```

### How to use Plus without Boxed

from

_(Example #1)_
```elm
type Msg
  = GotText (Result Http.Error String)

getPublicOpinion : Cmd Msg
getPublicOpinion =
  Http.get
    { url = "https://elm-lang.org/assets/public-opinion.txt"
    , expect = Http.expectString GotText
    }

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotText result ->
            -- do something with result that is of type
            -- Result Http.Error String
            ...
```

To

_(Example #2)_
```elm
type Msg
  = GotResponse (Result Http.Error (Http.Response String))

getPublicOpinion : Cmd Msg
getPublicOpinion =
  Http.get
    { url = "https://elm-lang.org/assets/public-opinion.txt"
    , expect = Http.expectStringResponse GotResponse (\\response -> Ok response)
    }

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotResponse result ->
            let
                result = Http.Boxed.expectPlus response Nothing
            in
            -- do something with result that is of type
            -- Result (Http.Plus.Error body) (Http.Plus.ResponseData body)
            ...
```


## Nº2 Http.Boxed ⇒ Mocking APIs the easy way

Http.Boxed help to simulate all possible type or responses from the api server without actually installing any api server, but just mocking all passible responses.

So let's imagine that we are expecting a response where the body is just text. We can create a file that contain some text, store in a folder and then use it in development to simulate the response from the api server.

But what if we want to simulate, for example, a status code 401 (Unauthorized)?

The idea is that, instead storing the body in the file, we store the entire response:

```json
{
    "metadata": {
        "url": "",
        "statusCode": 401,
        "statusText": "Unauthorized",
        "headers": {}
    },
    "body": "Here is the body"
}
```
Now we need to make our script believe that this is the real response.

Let's see how this can be done using `Http.Boxed` this way:

Instead of building a request like:

_(Example #1)_
```elm
type Msg
  = GotText (Result Http.Error String)

getPublicOpinion : Cmd Msg
getPublicOpinion =
  Http.get
    { url = "https://elm-lang.org/assets/public-opinion.txt"
    , expect = Http.expectString GotText
    }

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotText result ->
            -- do something with result that is of type
            -- Result Http.Error String
            ...
```

we need to add `Http.Boxed.unboxResponse` this way:

_(Example #3)_
```elm
type Msg
  = GotResponse (Result Http.Error (Http.Response String))

getPublicOpinion : Cmd Msg
getPublicOpinion =
  Http.get
    { url = "https://elm-lang.org/assets/public-opinion.txt"
    , expect = Http.expectStringResponse GotResponse Http.Boxed.unboxResponse
    }

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotResponse response ->
            let
                result = Http.Boxed.expectText response
            in
            -- do something with result that is of type
            -- Result Http.Error String
            ...
```

now `result` will contain a response with status code of 401, even though the response was actually 200.
```
 Response  ┌──────────┐  Unboxed  ┌──────┐
=========> │ 200      │ ========> │ 401  │
           ╞══════════╡           ╞══════╡
           │ ┌──────┐ │           │ data │
           │ │ 401  │ │           └──────┘
           │ ╞══════╡ │
           │ │ data │ │
           │ └──────┘ │
           └──────────┘
```

In case the response doesn't contain any `boxed` response, it will be passed intact:


```
 Response  ┌──────┐  Unboxed  ┌──────┐
=========> │ 401  │ ========> │ 401  │
           ╞══════╡           ╞══════╡
           │ data │           │ data │
           └──────┘           └──────┘
```


## Nº3 Http.State ⇒ A simple wrapper

The third helper is a simple wrapper that add a type around the request:

```elm
type State body
    = NotRequested
    | Fetching
    | Complete (Result (Http.Plus.Error body) (Http.Plus.ResponseData body))
```

It also duplicate all the getters of Http.Plus.


## All together!


_(Example #4)_
```elm
type Msg
  = GotResponse (Result Http.Error (Http.Response String))

getPublicOpinion : Cmd Msg
getPublicOpinion =
  Http.get
    { url = "https://elm-lang.org/assets/public-opinion.txt"
    , expect = Http.expectStringResponse GotResponse Http.Boxed.unboxResponse
    }

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotResponse response ->
            let
                state =
                    Http.Boxed.Complete
                        <| Http.Boxed.expectPlus response (Just bodyDecoder)
            in
            -- do something with result that is of type
            -- Http.State Body
            ...
```

Now let's suppose that you want to get the status code of the response regardless if it is successful or not and regardless if the body a good body or a bad body. This would be the way of doing it:

```elm
statusCode =
    case state of
        Http.State.Complete result ->
            case result of
                Ok response ->
                    case response of
                        Http.Plus.Decoded metadata _ ->
                            Ok metadata.statusCode

                        Http.Plus.Raw metadata _ _ ->
                            Ok metadata.statusCode

                Err err ->
                    case err of
                        Http.Plus.BadStatus response ->
                            case response of
                                Http.Plus.Decoded metadata _ ->
                                    Ok metadata.statusCode

                                Http.Plus.Raw metadata _ _ ->
                                    Ok metadata.statusCode

                        _ ->
                            Err <| "BadUrl, Timeout or NetworkError"

        _ ->
            Err "Request is not Complete"
```

to help with this you can use a getter that works both with Http.State and Http.Plus:

```elm
statusCode =
    Http.State.statusCode state
```

In this case the type of the returned value is a simple `Result String Int`.
