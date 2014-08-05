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

type mode = Init | Server | Add_user of string
let mode = ref Server
let config_file = ref "config.txt"

let options =
  Arg.align
    [ "--init", Arg.Unit (fun () -> mode := Init), " init database" ;
      "-c", Arg.String ((:=) config_file), "file read configuration from file; default is "^ !config_file ;

      "--add-user", Arg.String (fun s -> mode := Add_user s), " login,name,firstname,email,home add user" ;

    ]

let connect cfg = Ann_config.(
   Ann_db.connect ~host:cfg.db_host ~user: cfg.db_user
     ~password: cfg.db_passwd ?port: cfg.db_port
     ~database: cfg.db_name ()
  )

let init config_file =
  try
    let cfg = Ann_config.read_config config_file in
    let db = connect cfg in
    Ann_db.init db
  with
    Failure msg ->
      prerr_endline msg;
      exit 1
;;

let add_user config_file s =
  let cfg = Ann_config.read_config config_file in
  let db = connect cfg in
  match Ann_misc.split_string s [','] with
  | [login ; name ; firstname ; email ; home] ->
      begin
        try
          let home = Some (Rdf_iri.iri home) in
          ignore(Ann_users.add db ~login ~name ~firstname ~email ~home ())
        with
        Ann_users.Error e ->
            prerr_endline (Ann_users.string_of_error e);
            exit 1
      end
  | _ -> failwith "wrong number of fields in --add-user; use -help to get help"

let usage = Printf.sprintf "Usage: %s [options]\nwhere options are:" (Filename.basename Sys.argv.(0));;

let main () =
  Arg.parse options (fun _ -> failwith (Arg.usage_string options usage)) usage;
  match !mode with
    Init -> init !config_file
  | Add_user s -> add_user !config_file s
  | Server ->
      let cfg = Ann_config.read_config !config_file in
      let db = connect cfg in
      Ann_server.serve cfg db

(*c==v=[Misc.safe_main]=1.0====*)
let safe_main main =
  try main ()
  with
    Failure s
  | Sys_error s ->
      prerr_endline s;
      exit 1
(*/c==v=[Misc.safe_main]=1.0====*)

let () = safe_main main
