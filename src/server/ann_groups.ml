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

module G = Ann_db.Groups
module U = Ann_db.Users
module GU = Ann_db.Group_users

let mutex = Mutex.create ()

type error =
  Group_exists of string
| Unknown_group of string
| Invalid_shortname of string

exception Error of error

let error e = raise (Error e)

let string_of_error = function
  Group_exists s -> Printf.sprintf "Group %S already exists." s
| Unknown_group s -> Printf.sprintf "Unknown group %S." s
| Invalid_shortname s -> Printf.sprintf "Invalid group shortname %S." s

let group_exists db shortname = G.select db ~shortname () <> []

let is_valid_shortname s =
  let f = function
    'a'..'z' | 'A'..'Z' | '-' | '|' | '0'..'9' -> ()
  | _ -> failwith ""
  in
  try String.iter f s; true
  with Failure _ -> false

let get_by_id db id =
  match G.select db ~id () with
    [] -> error (Unknown_group ("#"^(string_of_int id)))
  | g :: _ -> g

let get db shortname =
  match G.select db ~shortname () with
    [] -> error (Unknown_group shortname)
  | g :: _ -> g

let add db ~name ~shortname ~descr () =
  if not (is_valid_shortname shortname) then error (Invalid_shortname shortname);
  let f () =
    if group_exists db shortname then error (Group_exists shortname);
    let right_key = Ann_keys.new_right_key db in
    G.insert db ~name ~shortname ~descr ~right_key ();
    get db shortname
  in
  Ann_misc.in_mutex mutex f ()

let list db = G.select db ()

let is_member db g u =
  GU.select db ~id_group: g.G.id ~id_user: u.U.id () <> []

let add_member db g u =
  let f () =
    if not (is_member db g u) then
      GU.insert db ~id_group: g.G.id ~id_user: u.U.id ()
    else
      ()
  in
  Ann_misc.in_mutex mutex f ()

let members db g = GU.select db ~id_group: g.G.id ()

let member_users db g =
  let members = members db g in
  List.map (fun gu -> Ann_users.get_by_id db gu.GU.id_user) members

