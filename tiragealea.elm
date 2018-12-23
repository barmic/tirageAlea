import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput)
import Random

main =
  Browser.element
    { init = init
    , update = update
    , subscriptions = subscriptions
    , view = view
    }

-- types

type StateNav = Participants | Couples | Template | Finished

type alias Participant =
  { name: String
  , mail: String
  }

type alias Model =
  { state: StateNav
  , participants: List Participant
  }

init: () -> (Model, Cmd Msg)
init _ =
  ({ state = Participants
   , participants = []
   }, Cmd.none)

type Msg = NewParticipant String String | DelParticipant String

-- view

view : Model -> Html Msg
view model =
  div []
    [ header [] [ h1 [] [ text "Tirage alea"]]
    , section [] [ text "Inscriptions > Couples > Mail" ]
    , section []
      [
        div []
          [
            text "Participant",
            input [ placeholder "Nom" ][],
            input [ placeholder "Mail" ][]
          ]
      ]
    ]

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    NewParticipant name mail ->
      ( { model | participants = model.participants ++ [{ name = name, mail = mail }] }, Cmd.none )
    _ ->
      ( model, Cmd.none )

subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.none