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


let key_kind_rsa = "rsa"

type key =
  Rsa of Nocrypto.RSA.pub

let strings_of_pubkey = function
  Rsa k ->
    (key_kind_rsa,
     Printf.sprintf "%s,%s" (Z.to_string k.Nocrypto.RSA.e) (Z.to_string k.Nocrypto.RSA.n)
    )

let find_pubkey db key =
  let (kind, pubkey) = strings_of_pubkey key in
  match Ann_db.Pubkeys.select db ~kind ~pubkey () with
    [] -> None
  | h :: _ -> Some h

let mutex = Mutex.create ()

let new_right_key db =
  let query = "select MAX(id)+1 FROM (
    SELECT MAX(right_key) AS id FROM users
    UNION ALL
    SELECT MAX(right_key) AS id FROM pubkeys
    UNION ALL
    SELECT MAX(right_key) AS id FROM groups
   ) foo"
  in
  let module D = Ann_db.Driver in
  let f () =
    try
      let id =
        match D.exec db ~query with
          D.R_Empty | D.R_Ok -> Ann_types.right_key_of_int 1
        | D.R_Fetch cursor ->
            match D.fetch_row ~fm: D.FM_Array cursor with
            | Some (D.FR_Array [| Some s |]) -> Ann_types.sql2right_key D.sql2int s
            | _ -> Ann_types.right_key_of_int 1
      in
      id
    with
      Dbf_sql_driver.Sql_error s -> failwith s
  in
  Ann_misc.in_mutex mutex f ()
