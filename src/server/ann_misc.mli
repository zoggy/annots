(*********************************************************************************)
(*                Annots                                                         *)
(*                                                                               *)
(*    Copyright (C) 2014 Institut National de Recherche en Informatique          *)
(*    et en Automatique. All rights reserved.                                    *)
(*                                                                               *)
(*    This program is free software; you can redistribute it and/or modify       *)
(*    it under the terms of the GNU General Public License version               *)
(*    3 as published by the Free Software Foundation.                            *)
(*                                                                               *)
(*    This program is distributed in the hope that it will be useful,            *)
(*    but WITHOUT ANY WARRANTY; without even the implied warranty of             *)
(*    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the              *)
(*    GNU General Public License for more details.                               *)
(*                                                                               *)
(*    You should have received a copy of the GNU General Public License          *)
(*    along with this program; if not, write to the Free Software                *)
(*    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA                   *)
(*    02111-1307  USA                                                            *)
(*                                                                               *)
(*    Contact: Maxence.Guesdon@inria.fr                                          *)
(*                                                                               *)
(*********************************************************************************)

(** Utilities. *)

(*i==v=[String.strip_string]=1.0====*)
(** [strip_string s] removes all leading and trailing spaces from the given string.
@@author Maxence Guesdon
@@version 1.0
@@cgname String.strip_string*)
val strip_string : string -> string
(*/i==v=[String.strip_string]=1.0====*)

(*i==v=[String.split_string]=1.2====*)
(** Separate the given string according to the given list of characters.
@@author Maxence Guesdon
@@version 1.2
@@param keep_empty is [false] by default. If set to [true],
   the empty strings between separators are kept.
@@cgname String.split_string*)
val split_string : ?keep_empty:bool -> string -> char list -> string list
(*/i==v=[String.split_string]=1.2====*)


(*i==v=[File.string_of_file]=1.0====*)
(** [string_of_file filename] returns the content of [filename]
   in the form of one string.
@@author Maxence Guesdon
@@version 1.0
@@raise Sys_error if the file could not be opened.
@@cgname File.string_of_file*)
val string_of_file : string -> string
(*/i==v=[File.string_of_file]=1.0====*)

(** @raise Failure if the file is not found in any of the given directories. *)
val find_in_dirs : string list -> string -> string

val string_of_base64 : string -> string
val base64_of_string : string -> string

(*i==v=[Misc.try_finalize]=1.0====*)
(** [try_finalize f x g y] applies [f] to [x] and return
   the result or raises an exception, but in all cases
   [g] is applied to [y] before returning or raising the exception.
@@author Didier Remy
@@version 1.0
@@cgname Misc.try_finalize*)
val try_finalize : ('a -> 'b) -> 'a -> ('c -> unit) -> 'c -> 'b
(*/i==v=[Misc.try_finalize]=1.0====*)

val in_mutex : Mutex.t -> ('a -> 'b) -> 'a -> 'b

val random_string : int -> (unit -> string)

(*i==v=[File.file_of_string]=1.1====*)
(** [file_of_string ~file str] creates a file named
   [filename] whose content is [str].
@@author Fabrice Lefessant
@@version 1.1
@@raise Sys_error if the file could not be opened.
@@cgname File.file_of_string*)
val file_of_string : file:string -> string -> unit
(*/i==v=[File.file_of_string]=1.1====*)


(*i==v=[String.string_of_opt]=1.0====*)
(** [string_of_opt s_opt] returns the empty string if
   [s_opt = None] or [s] if [s_opt = Some s].
@@version 1.0
@@cgname String.string_of_opt*)
val string_of_opt : string option -> string
(*/i==v=[String.string_of_opt]=1.0====*)

val map_opt : ('a -> 'b) -> 'a option  -> 'b option
