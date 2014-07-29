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

module CF = Config_file

type t =
  {
    db_name : string ;
    db_user : string ;
    db_passwd : string ;
    db_host : string ;
    db_port : int option ;
    root_iri : Rdf_iri.iri ;
    root_dir : string ;
  }

let read_config file =
  let group = new CF.group in
  let dbname_cp = new CF.string_cp ~group ["db"; "name"] "annots" "" in
  let dbuser_cp = new CF.string_cp ~group ["db"; "user"] "annots" "" in
  let dbhost_cp = new CF.string_cp ~group ["db"; "host"] "localhost" "" in
  let dbpasswd_cp = new CF.string_cp ~group ["db"; "password"] "" "" in
  let dbport_cp = new CF.string_cp ~group ["db"; "port"] "" "" in
  let root_iri_cp = new CF.string_cp ~group ["root_iri"] "http://localhost:8082/" "do not forget ending /" in
  begin
    try group#read file
    with Stream.Error _ ->
      failwith (Printf.sprintf "Syntax error in config file %S" file)
  end;
  let root_iri =
    let s = root_iri_cp#get in
    let s = Ann_misc.strip_string s in
    let len = String.length s in
    if len <= 0 || s.[len-1] <> '/' then s^"/" else s
  in
  let db_port =
    match Ann_misc.strip_string dbport_cp#get with
      "" -> None
    | s ->
      try Some (int_of_string s)
      with _ -> failwith ("Invalid port: "^s)
  in
  {
    db_name = dbname_cp#get ;
    db_user = dbuser_cp#get ;
    db_host = dbhost_cp#get ;
    db_passwd = dbpasswd_cp#get ;
    db_port ;
    root_iri = Rdf_iri.iri root_iri ;
    root_dir = Filename.dirname file ;
  }

let string_of_config c =
  let b = Buffer.create 256 in
  Printf.bprintf b "db_name=%s\n" c.db_name ;
  Printf.bprintf b "db_user=%s\n" c.db_user ;
  Printf.bprintf b "db_host=%s\n" c.db_host ;
  Printf.bprintf b "db_passwd=%s\n" c.db_passwd ;
  Printf.bprintf b "root_iri=%s\n" (Rdf_iri.string c.root_iri);
  Printf.bprintf b "root_dir=%s\n" c.root_dir ;
  Buffer.contents b
;;

