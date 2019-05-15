open Core
open Async
open Stationary_std_internal

type t =
  | Html of string * Html.t
  | Text of {filename: string; contents: string}
  | Collect_output of {prog: string; args: string list; name: string}
  | Of_path of {path: string; name: string}

let of_text ~name contents =
  validate_filename name ;
  Text {filename= name; contents}

let of_html ~name html =
  validate_filename name ;
  Html (name, html)

let of_html_path ~name html = Html (name, html)

let of_path ?name path =
  let name =
    match name with Some name -> name | None -> Filename.basename path
  in
  Of_path {path; name}

let collect_output ~name ~prog ~args = Collect_output {name; prog; args}

let build t ~in_directory =
  match t with
  | Text {filename; contents} ->
      let filename = in_directory ^/ filename in
      let dir = Filename.dirname filename in
      let%bind () = Async.Unix.mkdir ~p:() dir in
      Writer.save filename ~contents
  | Html (name, html) ->
      let%bind contents = Html.to_string html in
      let filename = in_directory ^/ name in
      let dir = Filename.dirname filename in
      let%bind () = Async.Unix.mkdir ~p:() dir in
      Writer.save filename ~contents:("<!DOCTYPE html>\n" ^ contents)
  | Of_path {name; path} ->
      Process.run_expect_no_output_exn ~prog:"cp"
        ~args:[path; in_directory ^/ name]
        ()
  | Collect_output {name; prog; args} ->
      Process.create ~prog ~args ()
      >>= fun proc ->
      let proc = Or_error.ok_exn proc in
      Writer.open_file (in_directory ^/ name)
      >>= fun writer ->
      Reader.transfer (Process.stdout proc) (Writer.pipe writer)
