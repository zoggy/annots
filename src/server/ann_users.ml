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

type error =
| Login_exists of string
| Unknown_user of string

exception Error of error
let error e = raise (Error e)

let string_of_error = function
  Login_exists s -> Printf.sprintf "Login %S is already taken." s
| Unknown_user login -> Printf.sprintf "Unknown user %S" login

let login_exists db login = U.select db ~login () <> []

let get_by_id db id =
  match U.select db ~id () with
    [] -> error (Unknown_user ("#"^(string_of_int id)))
  | u :: _ -> u

let get db login =
  match U.select db ~login () with
    [] -> error (Unknown_user login)
  | u :: _ -> u

let add db ~name ~firstname ~login ~email ?home () =
  let f () =
    if login_exists db login then error (Login_exists login);
    let right_key = Ann_keys.new_right_key db in
    U.insert db ~name ~firstname ~login ~email ?home ~right_key ();
    get db login
  in
  Ann_misc.in_mutex mutex f ()

let list db = U.select db ()