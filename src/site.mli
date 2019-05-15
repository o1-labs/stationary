open Async

(** This module allows you to construct a site. *)

(** A representation of your site. *)
type t

val create : File_system.t list -> t
(** Create a site with the given filesystem. *)

val build : t -> dst:string -> unit Deferred.t
(** Build a site at the specified path. *)
