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

let web_dir cfg = Filename.concat cfg.Ann_config.root_dir "web"
let webtmpl_dir cfg = Filename.concat (web_dir cfg) "templates"
let webfiles_dir cfg = Filename.concat (web_dir cfg) "files"

type result = { code : int ; body : string * string }

let mime_text = "text/plain"
let mime_html = "text/html"
let mime_javascript = "application/javascript"
let mime_css = "text/css"
let mime_svg = "image/svg+xml"

let result_not_found url = { code = 404 ; body = (url, mime_text) }
let result_forbidden url = { code = 403 ; body = (url, mime_text) }
let result ?(code=200) ?(mime=mime_html) contents =
  { code ; body = (contents, mime) }

let result_page ?code ?mime xmls = result ?code ?mime (Xtmpl.string_of_xmls xmls)

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
  with Not_found -> mime_text


let result_file file =
  let contents = Ann_misc.string_of_file file in
  let mime = file_mime_type file in
  result ~mime contents

     