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

let get_useful_path =
  let rec iter = function
    [], p
  | [""], p -> Some p
  | rh::rq, h::q when rh = h -> iter (rq, q)
  | _ -> None
  in
  fun root_path path -> iter (root_path, path)

let callback cfg req ouch =
  let path = Ann_misc.split_string req#path ['/'] in
  let root_path = Rdf_iri.path cfg.root_iri in
  match get_useful_path root_path path with
    None -> Http_daemon.respond_not_found ~url: req#path ouch
  | Some p ->
     Http_daemon.respond ~body:(String.concat "/" p) ouch

let serve cfg db =
  let iri = cfg.root_iri in
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
      callback = callback cfg ;
    }
  in
  Http_daemon.main spec
