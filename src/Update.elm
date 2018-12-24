module Update exposing (update)

import Model exposing (..)

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
      -- TODO clean previous couple
      ( { model | participants = (List.map (\p -> {p | partner = if p.name == a then Just b else if p.name == b then Just a else p.partner }) model.participants)
        }, Cmd.none )
    Next -> ( { model | state = case model.state of
        Participants -> Mail
        Mail -> Finished
        Finished -> Finished}, Cmd.none )

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
