module Update exposing (update)

import Model exposing (..)
import Http exposing (header)
import Json.Encode as Encode exposing (..)

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    NewParticipant ->
      case [model.newName, model.newMail] of
          [Just name, Just mail] -> (newParticipant model name mail, Cmd.none )
          _ -> ( model, Cmd.none ) -- ignore add if no name or no mail
    NewName name -> ( { model | newName = (noEmpty name)}, Cmd.none )
    NewMail mail -> ( { model | newMail = (noEmpty mail)}, Cmd.none )
    DelParticipant name -> (delParticipant model name, Cmd.none )
    NewPartner a b -> ( newPartner model a b, Cmd.none )
    NewSubject subject -> ( { model | mailSubject = (noEmpty subject) }, Cmd.none )
    NewBody body -> ( { model | mailBody = (noEmpty body) }, Cmd.none )
    GoToMailTemplate -> ( { model | state = case model.state of
      Participants -> Mail
      _ -> model.state}, Cmd.none )
    SendMail -> sendRequest model
    MailSent a -> ( model, Cmd.none )

noEmpty : String -> Maybe String
noEmpty a = if a == "" then Nothing else Just a

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

-- TODO "" should be Nothing
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

sendRequest : Model -> (Model, Cmd Msg)
sendRequest model =
  (
    { model | state = if model.state == Mail then Finished else model.state }
  , Http.request
      { method = "POST"
      , url = "/api/tirage"
      , headers = [header "Content-Type" "application/json; charset=utf-8"]
      , body = Http.jsonBody (queryEncode model)
      , expect = Http.expectString MailSent
      , timeout = Nothing
      , tracker = Nothing
      }
  )

queryEncode : Model -> Encode.Value
queryEncode model =
  Encode.object
    [ ("subject", Encode.string (Maybe.withDefault "" model.mailSubject)) -- TODO should not be valid
    , ("body", Encode.string (Maybe.withDefault "" model.mailBody)) -- TODO should not be valid
    , ("participants", Encode.list encodeParticipant model.participants)
    ]

encodeParticipant : Participant -> Encode.Value
encodeParticipant participant =
  Encode.object
    (
      [ ("name", Encode.string participant.name)
      , ("mail", Encode.string participant.mail)
      ]
      ++
      (Maybe.withDefault [] (Maybe.map (\p -> [("partner", Encode.string p)]) participant.partner))
    )