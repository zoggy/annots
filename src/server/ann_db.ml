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

let () = Dbf_mysql.debug_printer := prerr_endline ;;

module Make (D : Dbf_sql_driver.SqlDriver) =
  struct

    module Annot_readers = Ann_db_base.Annot_readers(D)
    module Annots = Ann_db_base.Annots(D)
    module Group_users = Ann_db_base.Group_users(D)
    module Groups = Ann_db_base.Groups(D)
    module Pubkeys = Ann_db_base.Pubkeys(D)
    module Users = Ann_db_base.Users(D)

    let set_charset db table =
      let q = "ALTER TABLE "^table^" CONVERT TO CHARACTER SET utf8;" in
      ignore(D.exec db q)

    let init db =
      try
        Annot_readers.create db ;
        Annots.create db ;
        Group_users.create db ;
        Groups.create db ;
        Pubkeys.create db ;
        Users.create db ;
        List.iter (set_charset db)
          [ "annot_readers" ; "annots" ; "group_users" ; "groups" ;
            "pubkeys" ; "users" ]
      with Dbf_sql_driver.Sql_error msg ->
          failwith msg

    let connect ~host ?port ~database ~user ~password () =
      try D.connect ~host ?port ~database ~user ~password ()
      with Dbf_sql_driver.Sql_error msg ->
        failwith msg
  end

module Driver = Dbf_mysql.MysqlDriver
include Make(Driver)
