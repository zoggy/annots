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

(** *)

module U = Ann_db.Users

let mutex = Mutex.create ()

exception Login_exists of string
exception Unknown_user of string

let login_exists db login = U.select db ~login () <> []

let get_by_id db id =
  match U.select db ~id () with
    [] -> raise (Unknown_user ("#"^(string_of_int id)))
  | u :: _ -> u

let get db login =
  match U.select db ~login () with
    [] -> raise (Unknown_user login)
  | u :: _ -> u

let add db ~name ~firstname ~login ~email ?home () =
  let f () =
    if login_exists db login then raise (Login_exists login);
    U.insert db ~name ~firstname ~login ~email ?home ();
    get db login
  in
  Ann_misc.in_mutex mutex f ()

let list db = U.select db ()