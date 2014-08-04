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

type token_id = string

type token = {
  token_exp_date : float option ;
  token_rights : Right_key_set.t ;
  }

let tokens = ref (Str_map.empty : token Str_map.t);;

let random_string =
  let f = Ann_misc.random_string 40 in
  fun () -> Ann_misc.base64_of_string (f())

let mutex = Mutex.create ()

let on_mutex f x =
  Mutex.lock mutex ;
  Ann_misc.try_finalize
    f x
    Mutex.unlock mutex

let do_add key t = tokens := Str_map.add key t !tokens
let do_remove key = tokens := Str_map.remove key !tokens

let add_token ?exp_date rights =
  let s = random_string () in
  on_mutex (do_add s)
    { token_exp_date = exp_date ; token_rights = rights };
  s

let remove_token s = on_mutex do_remove s
