module Model exposing (..)

import Dict exposing (Dict)
import Http

type StateNav = Participants | Mail | Finished

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
  , mailSubject: Maybe String
  , mailBody: Maybe String
  , mapping: Dict String (List String)
  }

type Msg = NewParticipant
         | NewName String
         | NewMail String
         | DelParticipant String
         | NewPartner String String
         | GoToMailTemplate
         | NewSubject String
         | NewBody String
         | SendMail
         | MailSent (Result Http.Error String)