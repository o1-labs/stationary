open Async

(** This module provides a type which represents a specification of a file
    that should appear in the filesystem that is your site. *)

(** This type represents a file in the filesystem that is your site. *)
type t

val of_text : name:string -> string -> t
(** Specify that there ought to be a file with the given name containing
    the given text. *)

val of_html : name:string -> Html.t -> t
(** Specify that there ought to be a file with the given name containing
    the given HTML. *)

val of_html_path : name:string -> Html.t -> t
(** Specify that there ought to be a file with the given path containing
    the given HTML. *)

val of_path : ?name:string -> string -> t
(** Specify that there ought to be a copy of the file at the given path
    with the given name. If no name is provided the basename of the path
    will be used. *)

val collect_output : name:string -> prog:string -> args:string list -> t
(** Generate the contents of a file by running the given program with
    the given arguments. *)

val build : t -> in_directory:string -> unit Deferred.t
(** Instantiates the file specification in the given directory. You should
    not typically need to call this directly and instead should just use
    [Site.build] which calls this. *)
