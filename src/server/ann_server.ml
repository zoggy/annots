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

open Ann_config

let route_annots cfg db req = function
  _ -> Ann_http.result "not implemented yet"

let route_users cfg db req = function
  _ -> Ann_http.result "not implemented yet"

let route_auth = Ann_auth.auth

let route_file cfg db req path =
  (* forbid using ".." in path, to prevent access to
     files out of webfiles directories *)
  let path = List.filter ((<>) Filename.parent_dir_name) path in
  let file = String.concat "/" path in
  let dirs = [
      Ann_http.webfiles_dir cfg ;
      Ann_install.webfiles_dir ;
    ]
  in
  try Ann_http.result_file (Ann_misc.find_in_dirs dirs file)
  with _ -> Ann_http.result_not_found "No service here."



let route cfg db req = function
  "annots" :: q -> route_annots cfg db req q
| "users" :: q -> route_users cfg db req q
| "auth" :: q -> route_auth cfg db req q
| [] -> Ann_xpage.welcome_page cfg db
| path -> route_file cfg db req path

let get_useful_path =
  let rec iter = function
    [], p
  | [""], p -> Some p
  | rh::rq, h::q when rh = h -> iter (rq, q)
  | _ -> None
  in
  fun root_path path -> iter (root_path, path)

let send_result res ouch =
  let (body, mime) = res.Ann_http.body in
  let code = `Code res.Ann_http.code in
  let headers = [ "content-type", mime ] in
  Http_daemon.respond ~code ~body ~headers ouch

let callback cfg db req ouch =
  let path = Ann_misc.split_string req#path ['/'] in
  let root_path = Rdf_iri.path cfg.root_iri in
  let result =
    match get_useful_path root_path path with
      None -> Ann_http.result_not_found req#path
    | Some p -> route cfg db req p
  in
  send_result result ouch

let on_exn e ouch =
  let msg =
    match e with
      Failure msg | Sys_error msg -> msg
    | _ -> Printexc.to_string e
  in
  prerr_endline msg;
  Http_daemon.respond_error ~code: (`Status (`Server_error `Internal_server_error))
    ~body: msg ouch

let serve cfg db =
  let port =
    match Rdf_iri.port cfg.root_iri with
      None -> 80
    | Some p -> p
  in
  let spec =
    { Http_daemon.default_spec with
      Http_types.mode = `Thread ;
      port ;
      root_dir = Some cfg.root_dir ;
      callback = callback cfg db ;
      exn_handler = Some on_exn ;
    }
  in
  Http_daemon.main spec
