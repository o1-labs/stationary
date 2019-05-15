open Core
open Async

type t =
  | Text of string
  | Markdown of string
  | Load of string
  | Literal of string
  | Node of string * Attribute.t list * t list
  | No_close of string * Attribute.t list
[@@deriving sexp]

let node tag attrs children = Node (tag, attrs, children)

let markdown s = Markdown s

let load s = Load s

let literal s = Literal s

let text s = Text s

let hr attrs = No_close ("hr", attrs)

let link ~href =
  No_close
    ( "link"
    , [ Attribute.create "rel" "stylesheet"
      ; Attribute.create "type" "text/css"
      ; Attribute.create "href" href ] )

(* TODO *)
let escape_for_html s = s

let inline =
  String.Set.of_list
    [ "a"
    ; "abbr"
    ; "acronym"
    ; "audio"
    ; "b"
    ; "bdi"
    ; "bdo"
    ; "big"
    ; "br"
    ; "button"
    ; "canvas"
    ; "cite"
    ; "code"
    ; "data"
    ; "datalist"
    ; "del"
    ; "dfn"
    ; "em"
    ; "embed"
    ; "i"
    ; "iframe"
    ; "img"
    ; "input"
    ; "ins"
    ; "kbd"
    ; "label"
    ; "map"
    ; "mark"
    ; "meter"
    ; "noscript"
    ; "object"
    ; "output"
    ; "picture"
    ; "progress"
    ; "q"
    ; "ruby"
    ; "s"
    ; "samp"
    ; "script"
    ; "select"
    ; "slot"
    ; "small"
    ; "span"
    ; "strong"
    ; "sub"
    ; "sup"
    ; "svg"
    ; "template"
    ; "textarea"
    ; "time"
    ; "u"
    ; "tt"
    ; "var"
    ; "video"
    ; "wbr" ]

let rec to_lines =
  let indent_lines = List.map ~f:(sprintf "  %s") in
  function
  | Load path -> (
      let _, ext = Filename.split_extension path in
      match ext with
      | Some "markdown" | Some "md" ->
          Process.run_lines_exn ~prog:"pandoc" ~args:[path; "--katex"] ()
      | Some _ | None ->
          Reader.file_lines path )
  | Markdown s ->
      let%bind proc = Process.create_exn ~prog:"pandoc" ~args:["--katex"] () in
      let stdin = Process.stdin proc in
      Writer.write stdin s ;
      let%bind () = Writer.close stdin in
      let lines = Reader.lines (Process.stdout proc) in
      Pipe.to_list lines
  | Literal s ->
      return [s]
  | No_close (tag, attrs) ->
      return
        [ sprintf "<%s %s>" tag
            (String.concat ~sep:" " (List.map ~f:Attribute.to_string attrs)) ]
  | Text s ->
      return [escape_for_html s]
  | Node (tag, attrs, children) ->
      if Set.mem inline tag then
        let opening =
          match attrs with
          | [] ->
              sprintf "<%s>" tag
          | _ :: _ ->
              sprintf "<%s %s>" tag
                (String.concat ~sep:" " (List.map ~f:Attribute.to_string attrs))
        in
        let%map children =
          Deferred.List.concat_map children ~f:(fun t -> to_lines t)
        in
        [opening ^ String.concat ~sep:"" children ^ sprintf "</%s>" tag]
      else
        let%map children =
          Deferred.List.concat_map children ~f:(fun t ->
              Deferred.map ~f:indent_lines (to_lines t) )
        in
        let opening =
          match attrs with
          | [] ->
              sprintf "<%s>" tag
          | _ :: _ ->
              sprintf "<%s %s>" tag
                (String.concat ~sep:" " (List.map ~f:Attribute.to_string attrs))
        in
        (opening :: children) @ [sprintf "</%s>" tag]

let to_string t = Deferred.map ~f:(String.concat ~sep:"\n") (to_lines t)
