#################################################################################
#                Annots                                                         #
#                                                                               #
#    Copyright (C) 2014 Institut National de Recherche en Informatique          #
#    et en Automatique. All rights reserved.                                    #
#                                                                               #
#    This program is free software; you can redistribute it and/or modify       #
#    it under the terms of the GNU General Public License version               #
#    3 as published by the Free Software Foundation.                            #
#                                                                               #
#    This program is distributed in the hope that it will be useful,            #
#    but WITHOUT ANY WARRANTY; without even the implied warranty of             #
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the              #
#    GNU General Public License for more details.                               #
#                                                                               #
#    You should have received a copy of the GNU General Public License          #
#    along with this program; if not, write to the Free Software                #
#    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA                   #
#    02111-1307  USA                                                            #
#                                                                               #
#    Contact: Maxence.Guesdon@inria.fr                                          #
#                                                                               #
#################################################################################

include ../master.Makefile

OF_FLAGS=-package $(PACKAGES)
INCLUDES=-I server `$(OCAMLFIND) query -i-format opium`

COMPFLAGS=$(INCLUDES) -annot -thread -g $(MT_FLAGS) #-annot

LINKFLAGS=$(INCLUDES) `$(OCAMLFIND) query opium`/opium.cmxa

# The executables and libraries to produce
LIB_ANNOTS=annots.cmxa
LIB_ANNOTS_CMXS=rdf.cmxs
LIB_ANNOTS_BYTE=$(LIB_ANNOTS:.cmxa=.cma)

ANNOTS_SERVER=annots
ANNOTS_SERVER_BYTE=$(ANNOTS_SERVER).byte

# Compilation
#############

LIB_ANNOTS_CMOFILES= \
	server/ann_config.cmo \
	server/ann_types.cmo \
	server/ann_misc.cmo

LIB_ANNOTS_CMIFILES= $(LIB_ANNOTS_CMOFILES:.cmo=.cmi)
LIB_ANNOTS_CMXFILES= $(LIB_ANNOTS_CMOFILES:.cmo=.cmx)

ANNOTS_LIBS=$(LIB_ANNOTS) $(LIB_ANNOTS_CMXS)
ANNOTS_LIBS_BYTE=$(LIB_ANNOTS_BYTE)

all: opt byte
opt: $(ANNOTS_LIBS) $(ANNOTS_SERVER)
byte: $(ANNOTS_LIBS_BYTE) $(ANNOTS_SERVER_BYTE)

$(LIB_ANNOTS): $(LIB_ANNOTS_CMIFILES) $(LIB_ANNOTS_CMXFILES)
	$(OCAMLFIND) ocamlopt -a -linkall -o $@ $(LIB_ANNOTS_CMXFILES)

$(LIB_ANNOTS_CMXS): $(LIB_ANNOTS_CMIFILES) $(LIB_ANNOTS_CMXFILES)
	$(OCAMLFIND) ocamlopt -linkall -shared -o $@ $(LIB_ANNOTS_CMXFILES)

$(LIB_ANNOTS_BYTE): $(LIB_ANNOTS_CMIFILES) $(LIB_ANNOTS_CMOFILES)
	$(OCAMLFIND) ocamlc -a -linkall -o $@ $(LIB_ANNOTS_CMOFILES)

$(ANNOTS_SERVER): $(LIB_ANNOTS) server/ann_server.cmx
	$(OCAMLFIND) ocamlopt $(OF_FLAGS) -linkpkg -o $@ -linkall $(LINKFLAGS) $^

$(ANNOTS_SERVER_BYTE): $(LIB_ANNOTS_BYTE) server/ann_server.cmo
	$(OCAMLFIND) ocamlc $(OF_FLAGS) -linkpkg -o $@ -linkall $(LINKFLAGS) $^

# Documentation :
#################
dump.odoc: server/*.mli server/*.ml
	$(OCAMLFIND) ocamldoc $(OF_FLAGS) $(MT_FLAGS) $(INCLUDES) -sort -dump dump.odoc \
	-syntax camlp4o -package lwt.syntax \
	`ls $^ | grep -v example | grep -v test | grep -v "_parser.ml" | grep -v "lex.ml" `

doc: dump.odoc
	$(MKDIR) ocamldoc
	$(OCAMLFIND) ocamldoc $(OF_FLAGS) \
	-t Annots \
	-load $^ \
	-d ocamldoc -html -intro index.text
	#$(CP) ../web/style.css ocamldoc/

docg: dump.odoc
	$(MKDIR) ocamldoc
	ocamldoc \
	-t Annots \
	-load $^ intro index.text \
	-d ocamldoc -g odoc_depgraph.cma -width 500 -height 600 -dot-options "-Gnodesep=\"0.12\" -Granksep=0.05"
	$(CP) ../web/style.css ocamldoc/

docstog: dump.odoc
	$(MKDIR) ../web/refdoc
	ocamldoc.opt \
	-t "Annots reference documentation" \
	-load $^ -intro index.text \
	-d ../web/refdoc -g odoc_stog.cmxs \
	-g odoc_depgraph.cmxs -width 500 -height 600 -dot-options "-Gnodesep=\"0.12\" -Granksep=0.05"

dot: dep.dot
dep.dot: dump.odoc
	$(OCAMLDOC) -load $< -o $@ -dot -dot-reduce
dep.ps:dep.dot
	dot -Tps -o $@ $<

# backup, clean and depend :
############################

distclean: clean

clean:: dummy
	$(RM) *~ \#*\# *.cm* *.a *.o *.annot
	(cd server && $(RM) *~ \#*\# *.cm* *.a *.o *.annot)
	$(RM) dump.odoc

.depend depend:
	$(RM) .depend
	$(OCAMLFIND) ocamldep server/*.ml server/*.mli > .depend

dummy:

include .depend

#################
# Installation
#################
install: all
	$(OCAMLFIND) install $(PACKAGE) META \
		$(LIB_ANNOTS) $(LIB_ANNOTS_CMXS) $(LIB_ANNOTS:.cmxa=.a) $(LIB_ANNOTS_CMIFILES) $(LIB_ANNOTS_CMXFILES) $(LIB_ANNOTS_BYTE)

uninstall: dummy
	$(OCAMLFIND) remove $(PACKAGE)

###########################
# additional dependencies
###########################



