module View exposing (view)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Model exposing (..)

view : Model -> Html Msg
view model =
  case model.state of
    Participants ->
      div [class "all"]
        [ header [] [ h1 [] [ text "Tirage alea"]]
        , section [class "peoples"] ([p [] [text "Inscrivez la liste des participants"]] ++ (listParticipants model) ++ [newParticipantView model])
        , button [onClick Next] [ text "Next!" ]
        ]
    Mail ->
      div [class "all"]
        [ header [] [ h1 [] [ text "Tirage alea"]]
        , section [class "peoples"]
        [ p [] [ text "Vous pouvez personnaliser les mails envoyés" ]
        , input [ placeholder "Sujet du mail"] [ text "Noël arrive - A vos cadeaux !"]
        , textarea [ placeholder "Contenu du mail"] [ text ""]
        ]
        , button [onClick Next] [ text "Send!" ]
        ]
    Finished ->
      div [class "all"]
        [ header [] [ h1 [] [ text "Tirage alea"]]
        , section [class "peoples"] [p [] [text "Les participants ont reçu le mail leur indiquant à qui faire un cadeau"]]
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
        |> List.map (\p -> option [onClick (NewPartner part.name p.name), selected (p.name == (Maybe.withDefault "" part.partner))] [ text p.name ])))
    ])) model.participants