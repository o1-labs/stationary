(** This module allows you to generate HTML pages for a site at
    site compilation time.
    For example, suppose you wanted to have a page which contained
    all the images that are in a particular directory on disk.
    You could programmatically create such a page using this module.
*)

open Async

(** The type of an HTML tree *)
type t [@@deriving sexp]

val node : string -> Attribute.t list -> t list -> t
(** Create an HTML node with the given tag, attributes and children.
    For example, [node "div" [] []] creates an empty div with no
    attributes and no children. *)

val literal : string -> t
(** For [s : string], [literal s] just considers the string [s] to be
    a piece of HTML. The important property is that for [t : t] containing
    [literal s], [s] will appear verbatim in [to_string t].

    This is useful for example in the following situation. Suppose you've got
    a markdown post on disk that you'd like to include as an HTML page in
    your site. You can do so by shelling out to a markdown compiler to convert
    it to a string representing HTML, and then using that string as a [t] by
    using [literal].
*)

val load : string -> t

val markdown : string -> t

val text : string -> t
(** Creates an HTML text node. *)

val to_string : t -> string Deferred.t
(** Convert the given HTML to a string. *)

val link : href:string -> t
(** Creates a [link] element, as used for css. *)

val hr : Attribute.t list -> t
(** Creates an [hr] element. *)
