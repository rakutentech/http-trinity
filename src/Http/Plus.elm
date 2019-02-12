module Http.Plus exposing
    ( Error(..)
    , ResponseData(..)
    , expectPlus
    , header
    , headers
    , isSuccess
    , metadata
    , responseData
    , statusCode
    , statusText
    , url
    )

import Dict
import Http
import Json.Decode
import Json.Encode


type Error body
    = BadUrl String
    | Timeout
    | NetworkError
    | BadStatus (ResponseData body)


type ResponseData body
    = Decoded Http.Metadata body
    | Raw Http.Metadata String String


expectPlus :
    Result Http.Error (Http.Response String)
    -> Maybe (Json.Decode.Decoder body)
    -> Result (Error body) (ResponseData body)
expectPlus response maybeDecoderBody =
    case response of
        Err err ->
            {-
               This case never happen because unbox always store the
               response in an `Ok` type to avoid loosing the metadata and
               the body.
            -}
            Err (BadUrl "This case never happen")

        Ok res ->
            case res of
                Http.BadUrl_ string ->
                    Err (BadUrl string)

                Http.Timeout_ ->
                    Err Timeout

                Http.NetworkError_ ->
                    Err NetworkError

                Http.BadStatus_ metadata_ body ->
                    Err
                        (case maybeDecoderBody of
                            Just decoderBody ->
                                case Json.Decode.decodeString decoderBody body of
                                    Err err ->
                                        BadStatus (Raw metadata_ (Json.Decode.errorToString err) body)

                                    Ok b ->
                                        BadStatus (Decoded metadata_ b)

                            Nothing ->
                                BadStatus (Raw metadata_ "No body decoder provided" body)
                        )

                Http.GoodStatus_ metadata_ body ->
                    Ok
                        (case maybeDecoderBody of
                            Just decoderBody ->
                                case Json.Decode.decodeString decoderBody body of
                                    Err err ->
                                        Raw metadata_ (Json.Decode.errorToString err) body

                                    Ok b ->
                                        Decoded metadata_ b

                            Nothing ->
                                Raw metadata_ "No body decoder provided" body
                        )



-- HELPERS


{-| Find the first key/value pair that matches a predicate.

    Dict.fromList [ ( 9, "Jill" ), ( 7, "Jill" ) ]
        |> find (\_ value -> value == "Jill")
    --> Just ( 7, "Jill" )

    Dict.fromList [ ( 9, "Jill" ), ( 7, "Jill" ) ]
        |> find (\key _ -> key == 5)
    --> Nothing

-}
find : (comparable -> a -> Bool) -> Dict.Dict comparable a -> Maybe ( comparable, a )
find predicate dict =
    Dict.foldl
        (\k v acc ->
            case acc of
                Just _ ->
                    acc

                Nothing ->
                    if predicate k v then
                        Just ( k, v )

                    else
                        Nothing
        )
        Nothing
        dict


caseInsensitiveGet : String -> Dict.Dict String v -> Result String v
caseInsensitiveGet key dict =
    let
        result =
            find (\k _ -> String.toLower k == String.toLower key) dict
    in
    case result of
        Just ( comparable, a ) ->
            Ok a

        Nothing ->
            Err <| "key \"" ++ key ++ "\" not found"



-- EXTRACT


responseData : Result (Error body) (ResponseData body) -> Result String (ResponseData body)
responseData res =
    case res of
        Ok response ->
            Ok response

        Err error ->
            case error of
                BadStatus resposne ->
                    Ok resposne

                BadUrl _ ->
                    Err "Bad Url"

                Timeout ->
                    Err "Timeout"

                NetworkError ->
                    Err "Network Error"


metadata : Result (Error body) (ResponseData body) -> Result String Http.Metadata
metadata res =
    case responseData res of
        Err err ->
            Err err

        Ok response ->
            case response of
                Decoded metadata_ _ ->
                    Ok metadata_

                Raw metadata_ _ _ ->
                    Ok metadata_


url : Result (Error body) (ResponseData body) -> Result String String
url res =
    Result.map .url (metadata res)


statusCode : Result (Error body) (ResponseData body) -> Result String Int
statusCode res =
    Result.map .statusCode (metadata res)


isSuccess : Result (Error body) (ResponseData body) -> Result String Int
isSuccess res =
    case statusCode res of
        Err err ->
            Err err

        Ok code ->
            if 200 <= code && code < 300 then
                Ok code

            else
                Err <| "Bad status: " ++ String.fromInt code


statusText : Result (Error body) (ResponseData body) -> Result String String
statusText res =
    Result.map .statusText (metadata res)


headers : Result (Error body) (ResponseData body) -> Result String (Dict.Dict String String)
headers res =
    Result.map .headers (metadata res)


header : String -> Result (Error body) (ResponseData body) -> Result String String
header key res =
    case headers res of
        Err err ->
            Err err

        Ok h ->
            caseInsensitiveGet key h
