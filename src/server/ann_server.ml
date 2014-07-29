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

type mode = Init | Server
let mode = ref Server
let config_file = ref "config.txt"

let options =
  Arg.align
    [ "--init", Arg.Unit (fun () -> mode := Init), " Init database" ;
      "-c", Arg.String ((:=) config_file), "file read configuration from file; default is "^ !config_file ;
    ]


let init config_file =
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
      prerr_endline msg;
      exit 1
;;

let usage = Printf.sprintf "Usage: %s [options]\nwhere options are:" Sys.argv.(0);;

let main () =
  Arg.parse options (fun _ -> failwith (Arg.usage_string options usage)) usage;
  match !mode with
    Init -> init !config_file
  | Server -> ()

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
