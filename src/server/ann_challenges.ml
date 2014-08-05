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

open Ann_types

let challenge_string_length = 128

let remove_padding s =
  let len = String.length s in
  let rec iter i =
    if i < len then
      match String.get s i with
        '\000' -> iter (i+1)
      | _ -> String.sub s i (len - i)
    else
      ""
  in
  iter 0

let key_kind_rsa = "rsa"

type key =
  Rsa of Nocrypto.RSA.pub

type challenge = {
    data : string ;
    right_key : Ann_types.right_key ;
  }

module C :
  sig
    type challenge_id = int
    val add_challenge : challenge -> challenge_id
    val check : challenge_id -> string -> challenge option
  end = struct
    type challenge_id = int
    let mutex = Mutex.create ()
    let challenge_id =
      let cpt = ref 0 in
      fun () -> incr cpt; !cpt

    let challenges = ref (Int_map.empty : challenge Int_map.t)
    let add_challenge c =
      Ann_misc.try_finalize
        (fun () ->
          Mutex.lock mutex;
          let id = challenge_id () in
          challenges := Int_map.add id c !challenges;
          id
        ) ()
        Mutex.unlock mutex

    let check id data =
      let data = remove_padding data in
      Ann_misc.try_finalize
        (fun () ->
          Mutex.lock mutex ;
          let res =
            try
              let c = Int_map.find id !challenges in
              challenges := Int_map.remove id !challenges ;
              (*
              prerr_endline (Printf.sprintf "c.data=%s\ndata=%s" c.data data);
              prerr_endline (Printf.sprintf "len(c.data)=%d\nlen(data)=%d" (String.length c.data) (String.length data));
              *)
              if c.data = data then
                Some c
              else
                None
            with Not_found -> None
          in
          res
        ) ()
        Mutex.unlock mutex
  end


let rsa_encrypt key data =
  let cs = Cstruct.of_string data in
  Cstruct.to_string (Nocrypto.RSA.encrypt ~key cs)

let encrypt = function
  Rsa key -> rsa_encrypt key

let random_string = Ann_misc.random_string challenge_string_length

let create_challenge right_key key =
  let data = random_string () in
  let challenge = { data ; right_key } in
  let challenge_id = C.add_challenge challenge in
  let enc_data = encrypt key data in
  (challenge_id, enc_data)

let check_challenge id data = C.check id data

