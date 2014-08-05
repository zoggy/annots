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

type cookie_action = Set_cookie of string * string | Unset_cookie of string


type mime = MimeType of string * string | MimeSub of string | MimeAny
let string_of_mime = function
  MimeType (t, s) -> Printf.sprintf "%s/%s" t s
| MimeSub t -> t^"/*"
| MimeAny -> "*/*"

let mime_type t s = MimeType (t, s)
let mime_sub t = MimeSub t
let mime_text = mime_type "text"
let mime_app = mime_type "application"
let mime_image = mime_type "image"

let mime_text_plain = mime_text "plain"
let mime_html = mime_text "html"
let mime_javascript = mime_app "javascript"
let mime_css = mime_text "css"
let mime_svg = mime_image "svg+xml"
let mime_json = mime_app "json"

type result = {
    code : int ;
    mime : mime ;
    body : string ;
    cookie_actions : cookie_action list ;
  }

type result_by_mime = (mime * (unit -> result)) list

let result ?(code=200) ?(cookie_actions=[]) ?(mime=mime_text_plain) body =
 { code ; mime ; body ; cookie_actions }

let result_json ?code ?cookie_actions ?(mime=mime_json) json =
  result ?code ~mime ?cookie_actions (Yojson.Safe.to_string json)

let result_page ?code ?cookie_actions ?(mime=mime_html) xmls =
  result ?code ?cookie_actions ~mime (Xtmpl.string_of_xmls xmls)

let error_page cfg msg =
  Ann_xpage.page cfg ~title: "Error"
    [Xtmpl.E (("","div"), Xtmpl.atts_one ("","class") [Xtmpl.D "alert alert-error"], [Xtmpl.D msg])]

let result_error ~code cfg msg =
  [ mime_text_plain, (fun () -> result ~code msg) ;
    mime_json, (fun () -> result_json ~code (`Assoc ["error", `String msg])) ;
    mime_html, (fun () -> result_page (error_page cfg msg)) ;
  ]

let result_not_found = result_error ~code: 404
let result_forbidden = result_error ~code: 403
let result_bad_request = result_error ~code: 400
let result_not_implemented cfg = result_error ~code: 501 cfg "Not implemented"
let result_not_acceptable cfg accept = result ~code: 406
  ("Unable to provide content in any accepted format: "^accept)




let file_extension s =
  try
    let p = String.rindex s '.' in
    String.sub s (p + 1) (String.length s - (p+1))
  with _ -> ""

let file_mime_types =
  [ ".css", mime_css ;
    ".js", mime_javascript ;
    ".svg", mime_svg ;
  ]
let file_mime_type file =
  try List.assoc (file_extension file) file_mime_types
  with Not_found -> mime_text_plain


let result_file file =
  let contents = Ann_misc.string_of_file file in
  let mime = file_mime_type file in
  [ mime, (fun () -> result ~mime contents) ]

type media = { range : mime ; q : float ; exts : (string * string) list }
let compare_media_ranges r1 r2 =
  match r1, r2 with
    _, MimeAny -> 1
  | MimeAny, _ -> -1
  | _, MimeSub _ -> 1
  | MimeSub _, _ -> -1
  | MimeType _, MimeType _ -> 0

let compare_medias m1 m2 =
  match compare m1.q m2.q with
    0 ->
      begin
        match compare_media_ranges m1.range m2.range with
          0 -> compare (List.length m1.exts) (List.length m2.exts)
        | n -> n
      end
  | n -> n

let accepted_medias s =
  let groups = Ann_misc.split_string s [','] in
  let f_range s =
    match Ann_misc.split_string s ['/'] with
    | [] -> assert false
    | "*" :: "*" :: _ -> MimeAny
    | [typ]
    | typ :: "*" :: _ -> MimeSub typ
    | typ :: subtyp :: _ -> MimeType (typ, subtyp)
  in
  let f_part acc s =
    match Ann_misc.split_string s ['='] with
      [] -> acc
    | [range] -> { acc with range = f_range range }
    | "q" :: v :: _ ->
        (
         try { acc with q = float_of_string v }
         with _ -> acc
        )
    | k :: v :: _ -> { acc with exts = (k, v) :: acc.exts }
  in
  let f g =
    let l = Ann_misc.split_string g [';' ; ' '] in
    List.fold_left f_part { range = MimeAny ; q = 1.0; exts = [] } l
  in
  let l = List.map f groups in
  List.rev (List.sort compare_medias l)

let mime_match pat v =
  match pat, v with
    MimeAny, _ -> true
  | MimeSub t, MimeType (t2,_)
  | MimeSub t, MimeSub t2 -> t = t2
  | MimeType (t,s), MimeType (t2, s2) -> t = t2 && s = s2
  | _ -> false

let find_first_mime_match patterns avail =
  let pred pat (m,_) = mime_match pat m in
  let rec iter = function
    [] -> None
  | pat :: q ->
      try Some (snd (List.find (pred pat) avail))
      with Not_found -> iter q
  in
  iter patterns
