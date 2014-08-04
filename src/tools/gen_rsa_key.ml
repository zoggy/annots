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

let binary = ref None

let () =
  let t  = Unix.gettimeofday () in
  let cs = Cstruct.create 8 in
  Cstruct.BE.set_uint64 cs 0 Int64.(of_float (t *. 1000.)) ;
  Nocrypto.Rng.reseed cs

let options = [
    "-b", Arg.String (fun s -> binary := Some s),
    "<file> output marshalled OCaml value of type Nocrypto.RSA.priv)\n\tand exponent,modulus on stderr"]

let () = Arg.parse options (fun _ -> ())
  (Printf.sprintf "Usage: %s [options]\nwhere options are:" Sys.argv.(0))

let k = Nocrypto.RSA.generate 1024

let () =
  match !binary with
    Some file ->
      let oc = open_out_bin file in
      Marshal.to_channel oc k [] ;
      close_out oc;
      prerr_string (Printf.sprintf "%s,%s" (Z.to_string k.e) (Z.to_string k.n))

  | None ->
    Printf.printf "e: %s
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
(*
let s = Cstruct.to_string (Nocrypto.RSA.encrypt (Nocrypto.RSA.pub_of_priv k) (Cstruct.of_string "helloworld!"))
let s = Ann_misc.base64_of_string s
let s = Ann_misc.string_of_base64 s
let s = Cstruct.to_string (Nocrypto.RSA.decrypt k (Cstruct.of_string s))
let () = prerr_endline s
*)