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
module U = Ann_users
module Udb = Ann_db.Users

let user_page cfg u =
  Ann_xpage.page cfg ~title: (Printf.sprintf "%s %s" u.Udb.firstname u.Udb.name)
    [Xtmpl.D "bla bla bla"]

let user_json u =
  `Assoc [
    "login", `String u.Udb.login ;
    "firstname", `String u.Udb.firstname ;
    "name", `String u.Udb.name ;
    "email", `String u.Udb.email ;
    "home", `String (Ann_misc.string_of_opt (Ann_misc.map_opt Rdf_iri.string u.Udb.home)) ;
  ]

let get_user cfg db login =
  try
    let u = U.get db login in
    [ H.mime_json, (fun () -> H.result_json (user_json u)) ;
      H.mime_html, (fun () -> H.result_page (user_page cfg u)) ;
    ]
  with
    U.Error e ->
      H.result_not_found cfg (U.string_of_error e)
(*
let handle_errors f x =
  try f x
  with e
    Ann_users.Unknown_user login ->
     [
*)
let route cfg db req = function
  [login] when req#meth = `GET -> get_user cfg db login
| _ -> []
