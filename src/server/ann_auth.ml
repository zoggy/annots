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

let token_cookie = "ANNOTS_TOKEN_ID"

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


let rights_of_challenges acc (id, data) =
  match Ann_challenges.check_challenge id data with
    None -> acc
  | Some c -> Ann_types.Right_key_set.add c.Ann_challenges.right_key acc

let challenge_of_json acc = function
  `Assoc l ->
    begin
      try
        let challenge_id = int_of_string (mand_str_json_field "challenge_id" l) in
        let data = mand_str_json_field "data" l in
        (challenge_id, data) :: acc
      with _ -> acc
    end
| _ -> acc

let auth_post_challenges cfg db req = function
  `List l ->
    begin
      let challenges = List.fold_left challenge_of_json [] l in
      let rights = List.fold_left rights_of_challenges Ann_types.Right_key_set.empty challenges in
      let token_id = Ann_token.add_token rights in
      Ann_http.result_json ~cookie_actions: [Ann_http.Set_cookie (token_cookie, token_id)]
        (`Assoc [(token_cookie, `String token_id)])
    end
| _ -> bad_request "List of challenge responses expected."

let pubkey_of_json = function
  `Assoc l ->
    begin
      try
        let id = mand_str_json_field "id" l in
        try
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
          (id, `Key key)
        with
          Bad_request msg -> (id, `Error msg)
        | e -> (id, `Error (Printexc.to_string e))
      with Bad_request msg -> ("?", `Error msg)
    end
| _ -> ("?", `Error "Bad public key format")

let challenge_of_pubkey db (id, res) =
  let json_assocs =
    match res with
      `Error msg -> ["error", `String msg]
    | `Key key ->
        try
          match Ann_keys.find_pubkey db key with
            None -> ["unknown", `Bool true]
          | Some t ->
              let (challenge_id, enc_data) =
                Ann_challenges.create_challenge t.Ann_db.Pubkeys.right_key key
              in
              [ "challenge_id", `Int challenge_id ;
                "data", `String (Ann_misc.base64_of_string enc_data) ;
              ]
        with
          e ->
            let msg = match e with
              | Invalid_argument msg
              | Failure msg -> msg
              | _ -> Printexc.to_string e
            in
            [ "error",  `String msg]
  in
  `Assoc (("id", `String id) :: json_assocs)

let auth_get_challenges cfg db req json =
  match json with
    `List l ->
      let keys = List.map pubkey_of_json l in
      let challenges = List.map (challenge_of_pubkey db) keys in
      Ann_http.result_json (`List challenges)
  | _ -> bad_request "List of public keys expected."


let auth cfg db req path =
  try
    match path, req#meth with
      ["pubkeys"], `POST -> auth_get_challenges cfg db req (J.from_string req#body)
    | ["challenges"], `POST -> auth_post_challenges cfg db req (J.from_string req#body)
    | _ -> Ann_http.result_not_found "No service here."
  with
    Yojson.Json_error msg
  | Bad_request msg ->
      Ann_http.result_bad_request msg
