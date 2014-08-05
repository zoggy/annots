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

let () =
  let t  = Unix.gettimeofday () in
  let cs = Cstruct.create 8 in
  Cstruct.BE.set_uint64 cs 0 Int64.(of_float (t *. 1000.)) ;
  Nocrypto.Rng.reseed cs

let () = Curl.global_init Curl.CURLINIT_GLOBALALL

let writer b data =
  Buffer.add_string b data;
  String.length data
;;

let handle_curl_error f x =
  try f x
  with Curl.CurlException (curl_code, n, reason) ->
    failwith ("Curl: " ^ reason)

let get_challenges cfg key =
  let json = `List
    [
      `Assoc [
        ("id", `String "0") ;
        ("kind", `String "rsa") ;
        ("exponent", `String (Z.to_string key.Nocrypto.RSA.e)) ;
        ("modulus", `String (Z.to_string key.Nocrypto.RSA.n)) ;
      ]
    ]
  in
  let buf = Buffer.create 1024 in
  let url = Rdf_iri.string cfg.Ann_config.root_iri in
  let pubkeys = url^"auth/pubkeys" in
  let connection = handle_curl_error Curl.init () in
  let f () =
    Curl.set_post connection true ;
    Curl.set_postfields connection (Yojson.Safe.to_string json);
    Curl.set_httpheader connection ["content-type: application/json"];
    Curl.set_writefunction connection (writer buf);
    Curl.set_url connection pubkeys;
    Curl.perform connection;
    match Curl.get_httpcode connection with
      200 ->
        let s = Buffer.contents buf in
        Curl.cleanup connection;
        Yojson.Safe.from_string s
    | n ->
        failwith (Printf.sprintf "Code %d:\n%s" n (Buffer.contents buf))
  in
  handle_curl_error f ()

let send_challenges cfg json =
  let url = Rdf_iri.string cfg.Ann_config.root_iri in
  let challenges = url^"auth/challenges" in
  let buf = Buffer.create 1024 in
  let connection = handle_curl_error Curl.init () in
  let f () =
    Curl.set_post connection true ;
    Curl.set_postfields connection (Yojson.Safe.to_string json);
    Curl.set_httpheader connection ["content-type: application/json"];
    Curl.set_writefunction connection (writer buf);
    Curl.set_url connection challenges;
    Curl.perform connection;
    match Curl.get_httpcode connection with
      200 ->
        let s = Buffer.contents buf in
        Curl.cleanup connection;
        Yojson.Safe.from_string s
    | n ->
        failwith (Printf.sprintf "Code %d:\n%s" n (Buffer.contents buf))
  in
  handle_curl_error f ()

let go config_file keyfile =
  let cfg = Ann_config.read_config config_file in
  let key =
    let ic = open_in_bin keyfile in
    let k = Marshal.from_channel ic in
    close_in ic;
    k
  in
  let json = get_challenges cfg key in
  match json with
    `List [ `Assoc l] ->
      begin
        let challenge_id =
          try List.assoc "challenge_id" l
          with Not_found ->
              failwith ("Missing challenge_id in JSON: "^(Yojson.Safe.to_string json))
        in
        prerr_endline (Yojson.Safe.to_string json);
        let data = List.assoc "data" l in
        match data with
          `String s ->
            prerr_endline ("received encoded data="^s);
            let s = Ann_misc.string_of_base64 s in
            let s = Cstruct.to_string (Nocrypto.RSA.decrypt ~key (Cstruct.of_string s)) in
            prerr_endline (Printf.sprintf "decoded data=%S" s);
            let s = Ann_misc.base64_of_string s in
            prerr_endline ("sending decoded data="^s);
            let json = `List [ `Assoc [ "challenge_id", challenge_id ; ("data", `String s)] ] in
            let json = send_challenges cfg json in
            prerr_endline (Yojson.Safe.to_string json)
        | _ -> failwith ("Invalid JSON for enc_data: "^(Yojson.Safe.to_string data))
      end
  | _ -> failwith ("Invalid JSON for challenges: "^(Yojson.Safe.to_string json))

let config_file = ref "config.txt"

let options =
 [ "-c", Arg.Set_string config_file, "file load config from <file>" ;
 ]


let remain = ref []

let () = Arg.parse (Arg.align options)
  (fun s -> remain := !remain @ [s])
  (Printf.sprintf "Usage: %s [options] key.pub\nwhere options are:" Sys.argv.(0))

let () =
  try
    match !remain with
      [] -> failwith "Please give a marshalled pubkey file"
    | file :: _ -> go !config_file file
  with
    Failure msg | Sys_error msg -> prerr_endline msg; exit 1

