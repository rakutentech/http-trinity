module Http.State exposing
    ( State(..)
    , getResult
    , header
    , headers
    , isSuccess
    , responseData
    , statusCode
    , statusText
    , url
    )

import Dict
import Http.Plus


type State body
    = NotRequested
    | Fetching
    | Complete (Result (Http.Plus.Error body) (Http.Plus.ResponseData body))


getResult :
    State body
    -> Result String (Result (Http.Plus.Error body) (Http.Plus.ResponseData body))
getResult state =
    case state of
        NotRequested ->
            Err "Not Requested"

        Fetching ->
            Err "Fetching"

        Complete result ->
            Ok result


myMap :
    State body
    ->
        (Result (Http.Plus.Error body) (Http.Plus.ResponseData body)
         -> Result String value
        )
    -> Result String value
myMap state f =
    case getResult state of
        Err err ->
            Err err

        Ok data ->
            f data


statusCode : State body -> Result String Int
statusCode state =
    myMap state Http.Plus.statusCode


isSuccess : State body -> Result String Int
isSuccess state =
    myMap state Http.Plus.isSuccess


statusText : State body -> Result String String
statusText state =
    myMap state Http.Plus.statusText


url : State body -> Result String String
url state =
    myMap state Http.Plus.url


headers : State body -> Result String (Dict.Dict String String)
headers state =
    myMap state Http.Plus.headers


header : State body -> String -> Result String String
header state key =
    myMap state (Http.Plus.header key)


responseData : State body -> Result String (Http.Plus.ResponseData body)
responseData state =
    myMap state Http.Plus.responseData
