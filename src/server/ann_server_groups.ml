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

module H = Ann_http
module G = Ann_groups
module U = Ann_users
module Gdb = Ann_db.Groups
module Udb = Ann_db.Users

let group_page cfg g =
  Ann_xpage.page cfg ~title: g.Gdb.name
    [Xtmpl.D "bla bla bla"]

let group_json g =
  `Assoc [
    "shortname", `String g.Gdb.shortname ;
    "name", `String g.Gdb.name ;
    "descr", `String g.Gdb.descr ;
  ]

let get_group cfg db shortname =
  try
    let g = G.get db shortname in
    [ H.mime_json, (fun () -> H.result_json (group_json g)) ;
      H.mime_html, (fun () -> H.result_page (group_page cfg g)) ;
    ]
  with
    G.Error e ->
      H.result_not_found cfg (G.string_of_error e)
(*
let handle_errors f x =
  try f x
  with e
    Ann_users.Unknown_user login ->
     [
*)
let route cfg db req = function
  [shortname] when req#meth = `GET -> get_group cfg db shortname
| _ -> []
