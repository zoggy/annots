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

(** Generate and print RSA keys. *)

open Nocrypto.RSA

let () =
  let t  = Unix.gettimeofday () in
  let cs = Cstruct.create 8 in
  Cstruct.BE.set_uint64 cs 0 Int64.(of_float (t *. 1000.)) ;
  Nocrypto.Rng.reseed cs

let k = Nocrypto.RSA.generate 1024

let () = Printf.printf "e: %s
d: %s
n: %s
p: %s
q: %s
dp: %s
dq: %s
q': %s
"
  (Z.to_string k.e)
  (Z.to_string k.d)
  (Z.to_string k.n)
  (Z.to_string k.p)
  (Z.to_string k.q)
  (Z.to_string k.dp)
  (Z.to_string k.dq)
  (Z.to_string k.q')
