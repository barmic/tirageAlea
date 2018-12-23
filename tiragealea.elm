import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Random

main =
  Browser.element
    { init = init
    , update = update
    , subscriptions = subscriptions
    , view = view
    }

type StateNav = Participants | Template | Finished

type alias Participant =
  { name: String
  , mail: String
  , partner: Maybe String
  }

type alias Model =
  { state: StateNav
  , participants: List Participant
  , newName: Maybe String
  , newMail: Maybe String
  }

init: () -> (Model, Cmd Msg)
init _ =
  ({ state = Participants
   , participants = []
   , newName = Nothing
   , newMail = Nothing
   }, Cmd.none)

type Msg = NewParticipant | NewName String | NewMail String | DelParticipant String | NewPartner String String | Next

-- view

view : Model -> Html Msg
view model =
  div [class "all"]
    [ header [] [ h1 [] [ text "Tirage alea"]]
    , section [class "breadcrumb"] [ text "Inscriptions > Mail" ]
    , section [class "peoples"] ((listParticipants model) ++ [newParticipantView model])
    ]

newParticipantView : Model -> Html Msg
newParticipantView model =
  div [class "people"]
         [ text "Participant"
         , input [ placeholder "Nom", value (Maybe.withDefault "" model.newName), autofocus True, onInput NewName ][]
         , input [ placeholder "Mail", value (Maybe.withDefault "" model.newMail), onInput NewMail ][]
         , button [onClick NewParticipant] [ text "+" ]
         ]

listParticipants : Model -> List (Html Msg)
listParticipants model =
  List.map (\part -> (div [class "people"]
    [ text (part.name ++ " <" ++ part.mail ++ ">")
    , button [onClick (DelParticipant part.name)] [ text "-" ]
    , select [] ([option [] [ text "" ]]
      ++
      (model.participants
        |> List.filter (\p -> p.name /= part.name)
        |> List.map (\p -> option [selected (p.name == (Maybe.withDefault "" part.partner))] [ text p.name])))
    ])) model.participants

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    NewParticipant ->
      case [model.newName, model.newMail] of
          [Just name, Just mail] -> (newParticipant model name mail, Cmd.none )
          _ -> ( model, Cmd.none )
    NewName name -> ( { model | newName = Just name }, Cmd.none )
    NewMail mail -> ( { model | newMail = Just mail }, Cmd.none )
    DelParticipant name -> (delParticipant model name, Cmd.none )
    NewPartner a b ->
      ( { model | participants = (List.map (\p -> {p | partner = if p.name == a then Just b else if p.name == b then Just a else p.partner }) model.participants)
        }, Cmd.none )
    Next -> ( { model | state = Template}, Cmd.none )

-- TODO check already exists
-- TODO check valid mail
newParticipant : Model -> String -> String -> Model
newParticipant model name mail =
  { model |
    participants = model.participants ++ [{ name = name, mail = mail, partner = Nothing }]
  , newName = Nothing
  , newMail = Nothing
  }

delParticipant : Model -> String -> Model
delParticipant model name =
  { model |
    newName = Just name
  , newMail = model.participants |> List.filter (\p -> p.name == name) |> List.map (\p -> p.mail) |> List.head
  , participants = model.participants |> List.filter (\p -> p.name /= name) |> List.map (\p -> {p | partner = (if p.partner == Just name then Nothing else p.partner)})
  }

subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.none