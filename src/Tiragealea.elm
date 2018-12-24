module Main exposing (main)

import Model exposing (..)
import Update exposing (..)
import View exposing (..)
import Browser
import Dict exposing (Dict)

main =
  Browser.element
    { init = init
    , update = update
    , subscriptions = subscriptions
    , view = view
    }

init: () -> (Model, Cmd Msg)
init _ =
  ({ state = Participants
   , participants = []
   , newName = Nothing
   , newMail = Nothing
   , mapping = Dict.empty
   }, Cmd.none)

subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.none