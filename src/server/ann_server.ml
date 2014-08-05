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

let result_by_mime cfg req funs =
  let accept = req#header ~name: "accept" in
  match accept, funs with
    _, [] -> assert false
  | "", (_, f) :: _ -> f ()
  | accept, _ ->
      let medias = Ann_http.accepted_medias accept in
      let mimes = List.map (fun m -> m.Ann_http.range) medias in
      match Ann_http.find_first_mime_match mimes funs with
        None -> Ann_http.result_not_acceptable cfg accept
      | Some f -> f ()

let route_users = Ann_server_users.route

let route_annots cfg db req = function
  _ -> Ann_http.result_not_implemented cfg

let route_groups cfg db req = function
  _ -> Ann_http.result_not_implemented cfg

let route_auth = Ann_auth.auth

let route_file cfg db req path =
  (* forbid using ".." in path, to prevent access to
     files out of webfiles directories *)
  let path = List.filter ((<>) Filename.parent_dir_name) path in
  let file = String.concat "/" path in
  let dirs = [
      Ann_xpage.webfiles_dir cfg ;
      Ann_install.webfiles_dir ;
    ]
  in
  try Ann_http.result_file (Ann_misc.find_in_dirs dirs file)
  with _ -> Ann_http.result_not_found cfg "No service here."

let route cfg db req = function
  "annots" :: q -> route_annots cfg db req q
| "users" :: q -> route_users cfg db req q
| "groups" :: q -> route_groups cfg db req q
| "auth" :: q -> route_auth cfg db req q
| [] -> 
    [ Ann_http.mime_html, (fun () -> Ann_http.result_page (Ann_xpage.welcome_page cfg db)) ;
      Ann_http.mime_text_plain, (fun () -> Ann_http.result "") ;
    ]
| path -> route_file cfg db req path

let get_useful_path =
  let rec iter = function
    [], p
  | [""], p -> Some p
  | rh::rq, h::q when rh = h -> iter (rq, q)
  | _ -> None
  in
  fun root_path path -> iter (root_path, path)

let past_cookie_date = "Wednesday, 09-Nov-99 23:12:40 GMT"

let header_of_cookie_action = function
  Ann_http.Set_cookie (k, v) ->
    ("Set-Cookie", Printf.sprintf "%s=%s, Path=/" k v)
| Ann_http.Unset_cookie k ->
    ("Set-Cookie", Printf.sprintf "%s=, Path=/, Expires=%s" k past_cookie_date)

let send_result res ouch =
  let body = res.Ann_http.body in
  let cookies = List.map header_of_cookie_action res.Ann_http.cookie_actions in
  let code = `Code res.Ann_http.code in
  let headers = cookies @ [ "content-type", Ann_http.string_of_mime res.Ann_http.mime ] in
  Http_daemon.respond ~code ~body ~headers ouch

let callback cfg db req ouch =
  let path = Ann_misc.split_string req#path ['/'] in
  let root_path = Rdf_iri.path cfg.root_iri in
  let results =
    match get_useful_path root_path path with
      None -> Ann_http.result_not_found cfg req#path
    | Some p -> route cfg db req p
  in
  let result = result_by_mime cfg req results in
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
