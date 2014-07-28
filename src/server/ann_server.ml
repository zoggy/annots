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

open Core.Std
open Async.Std
open Opium.Std

let hello =
  get "/"
  (fun req -> `String "Hello World" |> respond')


let init config_file () =
  try
    let cfg = Ann_config.read_config config_file in
    let db = Ann_config.(
       Ann_db.connect ~host:cfg.db_host ~user: cfg.db_user
         ~password: cfg.db_passwd ?port: cfg.db_port
         ~database: cfg.db_name ()
      )
    in
    Ann_db.init db
  with
    Failure msg ->
      Pervasives.prerr_endline msg;
      Pervasives.exit 1
;;

let () =
  App.empty
  |> hello
  |> fun app ->
    let server = App.command app in
    let init = Command.basic
      ~summary: "Initialize database from the given config file"
      Command.Spec.(
        empty +>
        anon ("config-file" %: file)
      )
      init
    in
    let main = Command.group "Web annotation server"
      [ "server", server ; "init", init ]
    in
    Command.run ~version: Ann_install.version main
