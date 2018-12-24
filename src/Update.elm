module Update exposing (update)

import Model exposing (..)

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    NewParticipant ->
      case [model.newName, model.newMail] of
          [Just name, Just mail] -> (newParticipant model name mail, Cmd.none )
          _ -> ( model, Cmd.none ) -- ignore add if no name or no mail
    NewName name -> ( { model | newName = Just name }, Cmd.none )
    NewMail mail -> ( { model | newMail = Just mail }, Cmd.none )
    DelParticipant name -> (delParticipant model name, Cmd.none )
    NewPartner a b -> ( newPartner model a b, Cmd.none )
    Next -> ( { model | state = case model.state of
      Participants -> Mail
      Mail -> Finished
      Finished -> Finished}, Cmd.none )

-- TODO check valid mail
newParticipant : Model -> String -> String -> Model
newParticipant model name mail =
  case model.participants |> List.filter (\p -> p.name == name) |> List.head of
    Nothing ->
      { model |
        participants = model.participants ++ [{ name = name, mail = mail, partner = Nothing }]
      , newName = Nothing
      , newMail = Nothing
      }
    Just a -> model -- ignore participant with same name

newPartner : Model -> String -> String -> Model
newPartner model a b =
  { model |
    participants = (List.map (\p -> {p | partner = (setPartner a b p) }) model.participants)
  }

setPartner : String -> String -> Participant -> Maybe String
setPartner a b part =
  if part.partner == Just a && part.name /= b then Nothing
  else if part.partner == Just b && part.name /= a then Nothing
  else if part.name == a then Just b
  else if part.name == b then Just a
  else part.partner

delParticipant : Model -> String -> Model
delParticipant model name =
  { model |
    newName = Just name
  , newMail = model.participants |> List.filter (\p -> p.name == name) |> List.map (\p -> p.mail) |> List.head
  , participants = model.participants |> List.filter (\p -> p.name /= name) |> List.map (\p -> {p | partner = (if p.partner == Just name then Nothing else p.partner)})
  }
