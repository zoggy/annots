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

module J = Yojson.Safe

exception Bad_request of string
let bad_request msg = raise (Bad_request msg)

let json_field name l =
  try Some (List.assoc name l)
  with Not_found -> None

let mand_json_field name l =
  match json_field name l with
    None -> bad_request (Printf.sprintf "Missing mandatory field %S" name)
  | Some x -> x

let mand_str_json_field name l =
  match json_field name l with
    None -> bad_request (Printf.sprintf "Missing mandatory field %S" name)
  | Some (`String s) -> s
  | Some _ -> bad_request (Printf.sprintf "Expected a string in field %S" name)

let auth_challenges cfg db req json =
  Ann_http.result ~mime: Ann_http.mime_text "challenges not implemented yet"

let pubkey_of_json = function
  `Assoc l ->
    begin
      let id = mand_str_json_field "id" l in
      let key_kind = mand_str_json_field "kind" l in
      let key =
        match key_kind with
          s when s = Ann_challenges.key_kind_rsa ->
            let exponent = mand_str_json_field "exponent" l in
            let modulus = mand_str_json_field "modulus" l in
            Ann_challenges.Rsa
              { Nocrypto.RSA.e = Z.of_string exponent ; n = Z.of_string modulus }
      | _ -> bad_request (Printf.sprintf "Unhandled public key kind: %S" key_kind)
      in
      (id, key)
    end
| _ -> bad_request "Bad public key format"

let challenge_of_pubkey (id, key) =
  `Assoc ([ "id", `String id])

let auth_pubkeys cfg db req json =
  match json with
    `List l ->
      let keys = List.map pubkey_of_json l in
      let challenges = List.map challenge_of_pubkey keys in
      Ann_http.result_json (`List challenges)
  | _ -> bad_request "List of public keys expected."


let auth cfg db req path =
  try
    match path with
      ["pubkeys"] -> auth_pubkeys cfg db req (J.from_string req#body)
    | ["challenges"] -> auth_challenges cfg db req (J.from_string req#body)
    | _ -> Ann_http.result_not_found "No service here."
  with
    Yojson.Json_error msg
  | Bad_request msg ->
      Ann_http.result_bad_request msg
