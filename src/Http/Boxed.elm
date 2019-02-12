module Http.Boxed exposing
    ( dontUnboxResponse
    , expectJson
    , expectText
    , unboxResponse
    )

import Http
import Json.Decode


type alias Response body =
    { metadata : Http.Metadata
    , body : body
    }


statusIsSuccess : Int -> Bool
statusIsSuccess code =
    200 <= code && code < 300


expectText :
    Result Http.Error (Http.Response String)
    -> Result Http.Error String
expectText response =
    case response of
        Err err ->
            Err (Http.BadUrl "This case never happen")

        Ok res ->
            case res of
                Http.BadUrl_ url ->
                    Err (Http.BadUrl url)

                Http.Timeout_ ->
                    Err Http.Timeout

                Http.NetworkError_ ->
                    Err Http.NetworkError

                Http.BadStatus_ metadata _ ->
                    Err <| Http.BadStatus metadata.statusCode

                Http.GoodStatus_ _ body ->
                    Ok body


expectJson :
    Result Http.Error (Http.Response String)
    -> Json.Decode.Decoder body
    -> Result Http.Error body
expectJson response decoder =
    case response of
        Err err ->
            Err (Http.BadUrl "This case never happen")

        Ok res ->
            case res of
                Http.BadUrl_ url ->
                    Err (Http.BadUrl url)

                Http.Timeout_ ->
                    Err Http.Timeout

                Http.NetworkError_ ->
                    Err Http.NetworkError

                Http.BadStatus_ metadata _ ->
                    Err <| Http.BadStatus metadata.statusCode

                Http.GoodStatus_ metadata body ->
                    case Json.Decode.decodeString decoder body of
                        Ok value ->
                            Ok value

                        Err err ->
                            Err <| Http.BadBody <| Json.Decode.errorToString err


dontUnboxResponse : Http.Response String -> Result Http.Error (Http.Response String)
dontUnboxResponse outerResponse =
    {-
       The reason we always convert to `Ok` here is that becase `Ok`
       is the only option to avoid loosing metadata and body information.

       If we try to map the response to the Http.Error we will have this case:

       Err (Http.BadStatus metadata.statusCode)

       But this case is dropping metadata (except the status Code) and the
       entire body.
    -}
    Ok outerResponse


unboxResponse : Http.Response String -> Result Http.Error (Http.Response String)
unboxResponse outerResponse =
    {-
       This function need tp be unboxing from a type "Http.Response String"
       to the same type "Http.Response String" so that can be chained with
       the rest of the flow
    -}
    let
        unboxingAttempt body =
            case Json.Decode.decodeString decodeResponse body of
                Ok innerResponse ->
                    if statusIsSuccess innerResponse.metadata.statusCode then
                        Http.GoodStatus_ innerResponse.metadata innerResponse.body

                    else
                        Http.BadStatus_ innerResponse.metadata innerResponse.body

                Err err ->
                    outerResponse
    in
    Ok
        (case outerResponse of
            {-
               Whenever we gat a body (`Http.BadStatus_` and `Http.GoodStatus_`),
               we try to unbox it. In all other cases, we just return the
               outer response.
            -}
            Http.BadStatus_ metadata body ->
                unboxingAttempt body

            Http.GoodStatus_ metadata body ->
                unboxingAttempt body

            _ ->
                outerResponse
        )


decodeResponse : Json.Decode.Decoder (Response String)
decodeResponse =
    Json.Decode.map2 Response
        (Json.Decode.field "metadata" decodeMetadata)
        (Json.Decode.field "body" Json.Decode.string)


decodeMetadata : Json.Decode.Decoder Http.Metadata
decodeMetadata =
    Json.Decode.map4 Http.Metadata
        (Json.Decode.field "url" Json.Decode.string)
        (Json.Decode.field "statusCode" Json.Decode.int)
        (Json.Decode.field "statusText" Json.Decode.string)
        (Json.Decode.field "headers" (Json.Decode.dict Json.Decode.string))
