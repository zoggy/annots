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

(** Building xhtml pages. *)

module Iriset = Rdf_iri.Iriset

let web_dir cfg = Filename.concat cfg.Ann_config.root_dir "web"
let webtmpl_dir cfg = Filename.concat (web_dir cfg) "templates"
let webfiles_dir cfg = Filename.concat (web_dir cfg) "files"

let rec tmpl_file cfg file =
  let dirs =
    [ webtmpl_dir cfg ;
      Ann_install.webtmpl_dir ;
    ]
  in
  Ann_misc.find_in_dirs dirs file
;;

let fun_include cfg acc _env args subs =
  match Xtmpl.get_arg_cdata args ("", "file") with
    None -> failwith "Missing 'file' argument for include command";
  | Some file ->
      let file =
        if Filename.is_relative file then
          tmpl_file cfg file
        else
          file
      in
      let xml = [Xtmpl.xml_of_string (Ann_misc.string_of_file file)] in
      let args = Xtmpl.atts_one ~atts: args
        ("", "include-contents") subs
      in
      (acc, [Xtmpl.E (("", Xtmpl.tag_env), args, xml)])
;;
let fun_image acc _env args legend =
  let width = Xtmpl.opt_arg_cdata args ("", "width") in
  let src = Xtmpl.opt_arg_cdata args ("", "src") in
  let cls = Printf.sprintf "img%s"
    (match Xtmpl.get_arg_cdata args ("", "float") with
       Some "left" -> "-float-left"
     | Some "right" -> "-float-right"
     | Some s -> failwith (Printf.sprintf "unhandled image position: %s" s)
     | None -> ""
    )
  in
  let xmls =
    [
      Xtmpl.E (("", "div"), Xtmpl.atts_one ("", "class") [ Xtmpl.D cls ] ,
       (Xtmpl.E (("", "img"),
         Xtmpl.atts_of_list
           [ ("", "class"), [Xtmpl.D "img"] ;
             ("", "src"), [Xtmpl.D src] ;
             ("", "width"), [Xtmpl.D width] ;
           ],
           [])
       ) ::
         (match legend with
            [] -> []
          | xml -> [ Xtmpl.E (("", "div"), Xtmpl.atts_one ("", "class") [Xtmpl.D "legend"], xml) ]
         )
      )
    ]
  in
  (acc, xmls)
;;

(*
let highlight ~opts code =
  let code_file = Filename.temp_file "stog" "code" in
  Misc.file_of_string ~file: code_file code;
  let temp_file = Filename.temp_file "stog" "highlight" in
  let com = Printf.sprintf
    "highlight -O xhtml %s -f %s > %s"
    opts (Filename.quote code_file)(Filename.quote temp_file)
  in
  match Sys.command com with
    0 ->
      let code = Misc.string_of_file temp_file in
      Sys.remove code_file;
      Sys.remove temp_file;
      code
  | _ ->
      failwith (Printf.sprintf "command failed: %s" com)
;;


let fun_hcode ?(inline=false) ?lang acc _env args code =
  let language, language_options =
    match lang with
      None ->
        (
         let lang = Xtmpl.opt_arg_cdata args ~def: "txt" ("", "lang") in
         match lang with
           "txt" -> (lang, None)
         | _ -> (lang, Some (Printf.sprintf "--syntax=%s" lang))
        )
    | Some "ocaml" ->
        ("ocaml", Some (Printf.sprintf "--config-file=%s/ocaml.lang" (Filename.dirname Sys.argv.(0))))
    | Some lang ->
        (lang, Some (Printf.sprintf "--syntax=%s" lang))
  in
  let code =
    match code with
      [ Xtmpl.D code ] -> code
    | [] -> ""
    | _ -> failwith (Printf.sprintf "Invalid code: %s"
         (String.concat "" (List.map Xtmpl.string_of_xml code)))
  in
  let code = Misc.strip_string code in
  let xml_code =
    match language_options with
      None -> Xtmpl.D code
    | Some opts ->
        let code = highlight ~opts code in
        Xtmpl.xml_of_string code
  in
  let xmls =
    if inline then
      [ Xtmpl.E (("", "span"), Xtmpl.atts_one ("", "class") [Xtmpl.D "icode"], [xml_code]) ]
    else
      [ Xtmpl.E (("", "pre"),
         Xtmpl.atts_one ("", "class") [Xtmpl.D ("code-%s"^language)],
         [xml_code])
      ]
  in
  (acc, xmls)
;;

let fun_ocaml = fun_hcode ~lang: "ocaml";;
let fun_command_line = fun_hcode ~lang: "sh";;
let fun_icode = fun_hcode ~inline: true ;;
*)

let fun_section cls acc _env args body =
  let atts =
    match Xtmpl.get_arg_cdata args ("", "name") with
      None -> Xtmpl.atts_empty
    | Some name -> Xtmpl.atts_one ("", "id") [Xtmpl.D name]
  in
  let title =
    match Xtmpl.get_arg args ("", "title") with
      None -> []
    | Some t ->
        [Xtmpl.E (("", "div"),
           Xtmpl.atts_one ~atts ("", "class") [Xtmpl.D (cls^"-title")],
           t
          )]
  in
  (acc, [ Xtmpl.E (("", "div"),
      Xtmpl.atts_one ("", "class") [Xtmpl.D cls],
      title @ body) ])
;;

let fun_subsection = fun_section "subsection";;
let fun_section = fun_section "section";;

let fun_if acc env args subs =
  (*prerr_endline (Printf.sprintf "if: env=%s" (Xtmpl.string_of_env env));*)
  let pred (_,att) v =
    let (_, xmls) = Xtmpl.apply_to_string () env (Printf.sprintf "<%s/>" att) in
    let s = Xtmpl.string_of_xmls xmls in
    let sv = Xtmpl.string_of_xmls v in
    (*prerr_endline (Printf.sprintf "fun_if: pred: att=\"%s\", s=\"%s\", v=\"%s\"" att s v);*)
    s = sv
  in
  let cond = Xtmpl.Name_map.for_all pred args in
  let subs = List.filter
    (function Xtmpl.D _ -> false | _ -> true)
    subs
  in
  (*prerr_endline (Printf.sprintf "if: length(subs)=%d" (List.length subs));*)
  let xmls =
    match cond, subs with
    | true, [] -> failwith "<if>: missing children"
    | true, h :: _
    | false, _ :: h :: _ -> [h]
    | false, []
    | false, [_] -> []
  in
  (acc, xmls)
;;

let fun_site_url config acc _ _ _ =
  (acc, [ Xtmpl.D (Rdf_uri.string (Rdf_iri.to_uri config.Ann_config.root_iri)) ]);;
let fun_site_title config acc _ _ _ = (acc, [ Xtmpl.D config.Ann_config.site_title ]);;


let default_commands config =
  [
    ("", "if"), fun_if ;
    ("", "include"), fun_include config;
    ("", "image"), fun_image ;
(*
    ("", "hcode"), fun_hcode ~inline: false ?lang: None;
    ("", "icode"), fun_icode ?lang: None;
    ("", "ocaml"), fun_ocaml ~inline: false ;
    ("", "star"), fun_star ;
    ("", "command-line"), fun_command_line ~inline: false ;
**)
    ("", "section"), fun_section ;
    ("", "subsection"), fun_subsection ;
    ("", "site-url"), fun_site_url config;
    ("", "site-title"), fun_site_title config ;
    ]
;;

let page config ?env ~title ?javascript ?(wtitle=title) ?(navpath=[]) ?(error="") contents =
  let morehead =
    let code =
      match javascript with
        None -> "function onPageLoad() { }"
      | Some code -> code
    in
    [ Xtmpl.E (("", "script"),
       Xtmpl.atts_one ("", "type") [Xtmpl.D "text/javascript"],
       [Xtmpl.D code])
    ]
  in
  let env = Xtmpl.env_of_list ?env
    ((("", "page-title"), (fun acc _ _ _ -> (acc, [Xtmpl.xml_of_string title]))) ::
     (("", "window-title"), (fun acc _ _ _ -> (acc, [Xtmpl.D wtitle]))) ::
     (("", "navpath"), (fun acc _ _ _ -> (acc, navpath))) ::
     (("", "error"), (fun acc _ _ _ -> (acc, [Xtmpl.xml_of_string error]))) ::
     (("", "morehead"), (fun acc _ _ _ -> (acc, morehead))) ::
     (default_commands config))
  in
  let f () env args body = ((), contents) in
  let env = Xtmpl.env_of_list ~env [("", "contents"), f] in
  let tmpl_file = tmpl_file config "page.tmpl" in
  snd (Xtmpl.apply_to_file () env tmpl_file)
;;

let welcome_page cfg db =
  page cfg ~title: "Welcome to Annots" [Xtmpl.D "bla bla bla"]
