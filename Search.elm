module Search (Model, init, update, view) where
import Char
import Effects exposing (Effects, Never)
import Html exposing (..)
import Html.Attributes as Attributes exposing (..)
import Html.Events exposing (onKeyPress, onClick, on, targetValue, onBlur)
import Signal exposing (Address)
import Http
import Json.Decode as Json
import Task
import Time 

(=>) = (,)

getAcUrl term page perPage=  {
  url = "http://localhost:3000/word/" ++ term
  , params= [
    ("page" , page)
    , ("perPage" , perPage)
      ]
  } 

type alias Model = 
  {
  searchTerm : String 
  , terms: List String
  , response: List String
  , loading: Bool
  }

type Action
  = KeyPress Int 
  | KeyInput String 
  | Blur 
  | DeleteTerm String
  | Response (Maybe (List String))


termToUrl: String -> String
termToUrl topic =
  let rec = getAcUrl topic "0" "10" in Http.url rec.url rec.params 


decodeAutocompleteResponse: Json.Decoder (List String)
decodeAutocompleteResponse =
    Json.list Json.string


getAutocomplete: String -> Effects Action
getAutocomplete topic =
  Http.get decodeAutocompleteResponse (termToUrl topic)
    |> Task.toMaybe
    |> Task.map Response 
    |> Effects.task

update : Action -> Model -> (Model, Effects Action)
update action model =
  case action of
    KeyPress keyCode ->
      let 
          term = model.searchTerm ++ toString (Char.fromCode keyCode)
      in
          case keyCode of
            38 -> -- up arrow
              ( {model | loading=False } , Effects.none)
            40 -> -- down arrow
              ( {model | loading=False } , Effects.none)
            13 -> -- enter
              ( {model | loading=False } , Effects.none)
            9 ->  -- tab 
              ( {model | loading=False } , Effects.none)
            _ ->
              ( {model | searchTerm = term, loading=True, response=[]} 
              , getAutocomplete term)
    KeyInput term ->
      ( {model | searchTerm = term, response = []}
      , if model.searchTerm == "" then Effects.none else getAutocomplete term)
    Blur ->
      ( {model | loading= False, response = []}
      , Effects.none )
    DeleteTerm term->
      (model, 
      Effects.none)
    Response maybeList ->
      ( {model | loading=False, response = (Maybe.withDefault model.response maybeList) }
      , Effects.none)

init : String -> (Model, Effects Action)
init searchTerm =
 (
   { searchTerm = searchTerm
   , terms= []
   , response=[]
   , loading=False
   }
  , Effects.none)
  
view address model =
  let 
      tags = (List.map (wordView address) model.terms) 
      resView = if model.loading == True then  div [ ] [text "loading..."] else responseView model.response
  in
  div [][
    div [][
      input
        [ type' "text"
          , placeholder "type here to start search.."
          , value model.searchTerm
          , onKeyPress address KeyPress 
          , onBlur address Blur 
          , on "input" targetValue (Signal.message address << KeyInput)
          , style [("fontSize", "16px"), ("padding", "4px"), ("width", "200px"), ("marginBottom", "6px")]
          ] tags
      ]
    , resView
    ]

responseView res =
  div [] (List.map responseItemView res)

responseItemView item =
  div [] [text item]

wordView address word =
  span
    [ style
        [ ("border", "solid 1px #4CAE4C")
        , ("background", "#5CB85C")
        , ("color", "white")
        , ("display", "inline-block")
        , ("padding", "4px")
        , ("borderRadius", "2px")
        , ("paddingLeft", "12px")
        , ("paddingRight", "12px")
        , ("marginLeft", "4px")
        , ("marginBottom", "6px")
        ]
    ]
    [ span [ style [("marginRight", "10px")] ]
       [ a [ style clickable, onClick address (DeleteTerm word) ] [ text "×" ] ]
    , span [] [ text word ]
    ]

clickable =
  [ ("cursor", "pointer") ]

