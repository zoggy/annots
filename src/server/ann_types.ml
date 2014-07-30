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

module Ordered_int = struct
    type t = int
    let compare (a : int) (b : int) = a - b
  end
module Int_set = Set.Make(Ordered_int)
module Int_map = Map.Make(Ordered_int)
module Str_map = Map.Make(String)

type right_key = int
let public_right_key = 0
module Right_key_set = Int_set
let right_key_of_int x = x
let int_of_right_key x = x
let sql2right_key f x = right_key_of_int (f x)
let right_key2sql f x = f (int_of_right_key x)

let iri2sql f x = f (Rdf_iri.string x)
let sql2iri f x = Rdf_iri.iri (f x)