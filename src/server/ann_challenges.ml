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

let () = Random.self_init()
let challenge_string_length = 40

let key_kind_rsa = "rsa"

type key =
  Rsa of Nocrypto.RSA.pub

type challenge = {
    data : string ;
    right_key : Ann_types.right_key ;
  }

(*c==v=[Misc.try_finalize]=1.0====*)
let try_finalize f x finally y =
  let res =
    try f x
    with exn -> finally y; raise exn
  in
  finally y;
  res
(*/c==v=[Misc.try_finalize]=1.0====*)

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
      try_finalize
        (fun () ->
          Mutex.lock mutex;
          let id = challenge_id () in
          challenges := Int_map.add id c !challenges;
          Mutex.unlock mutex;
          id
        ) ()
        Mutex.unlock mutex

    let check id data =
      try_finalize
        (fun () ->
          Mutex.lock mutex ;
          let res =
            try
              let c = Int_map.find id !challenges in
              challenges := Int_map.remove id !challenges ;
              if c.data = data then
                Some c
              else
                None
            with Not_found -> None
          in
          Mutex.unlock mutex ;
          res
        ) ()
        Mutex.unlock mutex
  end


let rsa_encrypt key data =
  let cs = Cstruct.of_string data in
  Cstruct.to_string (Nocrypto.RSA.encrypt ~key cs)

let encrypt = function
  Rsa key -> rsa_encrypt key

let random_string =
  let s = String.create challenge_string_length in
  let f _ = Char.chr (Random.int 255) in
  fun () -> String.map f s

let create_challenge right_key key =
  let data = random_string () in
  let challenge = { data ; right_key } in
  let challenge_id = C.add_challenge challenge in
  let enc_data = encrypt key data in
  (challenge_id, enc_data)

let check_challenge id data = C.check id data

