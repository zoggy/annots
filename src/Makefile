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

INCLUDES=-I base -I stog
INCLUDES_CLIENT=-I base -I _client/stog -package xmldiff

COMPFLAGS_= -g -annot -rectypes -thread
COMPFLAGS=$(COMPFLAGS_) $(INCLUDES)
COMPFLAGS_CLIENT=$(COMPFLAGS_) $(INCLUDES_CLIENT)

LINKFLAGS=$(INCLUDES) -thread

# The executables and libraries to produce
LIB=erispub.cmxa
LIB_CMXS=$(LIB:.cmxa=.cmxs)
LIB_BYTE=$(LIB:.cmxa=.cma)


# Compilation
#############

BASE_CMOFILES= \
	base/eris_config.cmo

BASE_CMIFILES= $(BASE_CMOFILES:.cmo=.cmi)
BASE_CMXFILES= $(BASE_CMOFILES:.cmo=.cmx)

BASE_LIB=eris_base.cmxa
BASE_LIB_CMXS=$(BASE_LIB:.cmxa=.cmxs)
BASE_LIB_BYTE=$(BASE_LIB:.cmxa=.cma)

STOG_SESSION_CMOFILES= \
	stog/eris_stog_types.cmo \
	stog/eris_stog_common.cmo \
	stog/eris_stog_ws.cmo \
	stog/eris_stog_data.cmo \
	stog/eris_stog_server.cmo \
	stog/eris_stog.cmo
STOG_SESSION_CMIFILES= #$(STOG_SESSION_CMOFILES:.cmo=.cmi)
STOG_SESSION_CMXFILES= $(STOG_SESSION_CMOFILES:.cmo=.cmx)

STOG_CLIENT_FILES= \
	_client/stog/eris_stog_types.cmo \
	_client/stog/eris_stog_common.cmo \
	_client/stog/eris_stog_client.cmo \
	stog/eris_stog.eliom

STOG_LIB=eris_stog_session.cmxa
STOG_LIB_CMXS=$(STOG_LIB:.cmxa=.cmxs)
STOG_LIB_BYTE=$(STOG_LIB:.cmxa=.cma)
STOG_JS=eris-stog.js

all: opt byte
opt: $(BASE_LIB) $(STOG_LIB) $(STOG_LIB_CMXS)
byte: $(BASE_LIB_BYTE) $(STOG_LIB_BYTE) $(STOG_JS)

$(BASE_LIB): $(BASE_CMIFILES) $(BASE_CMXFILES)
	$(OCAMLFIND) ocamlopt -a -linkall -o $@ $(BASE_CMXFILES)

$(BASE_LIB_CMXS): $(BASE_CMIFILES) $(BASE_CMXFILES)
	$(OCAMLFIND) ocamlopt -linkall -shared -o $@ $(BASE_CMXFILES)

$(BASE_LIB_BYTE): $(BASE_CMIFILES) $(BASE_CMOFILES)
	$(OCAMLFIND) ocamlc -a -linkall -o $@ $(BASE_CMOFILES)

$(STOG_LIB): $(BASE_LIB) $(STOG_SESSION_CMIFILES) $(STOG_SESSION_CMXFILES)
	$(OCAMLFIND) ocamlopt $(OF_FLAGS) $(COMPFLAGS) -o $@ -a \
	$(STOG_SESSION_CMXFILES)

$(STOG_LIB_CMXS): $(BASE_LIB_BYTE) $(STOG_SESSION_CMIFILES) $(STOG_SESSION_CMXFILES)
	$(OCAMLFIND) ocamlopt $(OF_FLAGS) $(COMPFLAGS) -o $@ -shared \
	$(BASE_LIB) $(STOG_SESSION_CMXFILES)

$(STOG_LIB_BYTE): $(BASE_LIB) $(STOG_SESSION_CMIFILES) $(STOG_SESSION_CMOFILES)
	$(OCAMLFIND) ocamlc $(OF_FLAGS) $(COMPFLAGS) -o $@ -a \
	$(BASE_LIB_BYTE) $(STOG_SESSION_CMOFILES)

$(STOG_JS): $(STOG_CLIENT_FILES)
	js_of_eliom -verbose $(INCLUDES_CLIENT) -type-dir . -rectypes -package xtmpl,xmldiff -o $@ $^

# Documentation :
#################
dump.odoc: *.mli *.ml
	$(OCAMLFIND) ocamldoc $(OF_FLAGS) $(OCAMLPP) $(INCLUDES) -sort -dump dump.odoc \
	`ls $^ | grep -v example | grep -v test`

doc: dump.odoc
	$(MKDIR) ocamldoc
	$(OCAMLFIND) ocamldoc $(OF_FLAGS) $(OCAMLPP) \
	-t Eris-publish \
	-load $^ \
	-d ocamldoc -html -intro index.text
	#$(CP) ../web/style.css ocamldoc/

docg: dump.odoc
	$(MKDIR) ocamldoc
	ocamldoc $(OCAMLPP) \
	-t Eris-publish \
	-load $^ intro index.text \
	-d ocamldoc -g odoc_depgraph.cma -width 500 -height 600 -dot-options "-Gnodesep=\"0.12\" -Granksep=0.05"
	$(CP) ../web/style.css ocamldoc/

docstog: dump.odoc
	$(MKDIR) ../web/refdoc
	ocamldoc.opt $(OCAMLPP) \
	-t "Eris-publish reference documentation" \
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
	$(RM) *~ \#*\# */*~ \#*\#
	$(RM) *.cm* *.a *.o *.annot
	$(RM) */*.cm* */*.a */*.o */*.annot
	$(RM) _client/*/*.cm* _client/*/*.a _client/*/*.o _client/*/*.annot
	$(RM) dump.odoc
	$(RM) $(STOG_SESSION) $(STOG_SESSION_BYTE)
	$(RM) $(STOG_JS)

.depend_server .depend_client depend:
	$(RM) .depend_server .depend_client
	eliomdep -server -dir . */*.ml */*.mli > .depend_server
	eliomdep -client -dir . */*.ml */*.mli > .depend_client

dummy:

include .depend_server
include .depend_client

#################
# Installation
#################
install: all
	$(OCAMLFIND) install $(PACKAGE) META \
		$(LIB) $(BASE_CMXS) $(LIB:.cmxa=.a) $(BASE_CMIFILES) $(BASE_CMXFILES) $(BASE_BYTE)

uninstall: dummy
	$(OCAMLFIND) remove $(PACKAGE)

###########################
# additional dependencies
###########################

#stog/eris_stog_common.cmi: stog/eris_stog_common.mli
#	eliomc $(OF_FLAGS) $(COMPFLAGS) -c -o stog/eris_stog_common.cmi $<

stog/eris_stog_types.cmo stog/eris_stog_types.cmx: stog/eris_stog_types.cmi

stog/eris_stog_common.cmx: stog/eris_stog_common.eliom
	eliomopt $(OF_FLAGS) $(COMPFLAGS) -c -o stog/eris_stog_common.cmx $<
	eliomopt -type-dir . -infer $(OF_FLAGS) $(COMPFLAGS) $<

stog/eris_stog_common.cmo: stog/eris_stog_common.eliom
	eliomc $(OF_FLAGS) $(COMPFLAGS) -c -o stog/eris_stog_common.cmo $<
	eliomopt -type-dir . -infer $(OF_FLAGS) $(COMPFLAGS) $<

_client/stog/eris_stog_common.cmx: stog/eris_stog_common.eliom
	js_of_eliom $(OF_FLAGS) $(COMPFLAGS_CLIENT) -type-dir . -c -o _client/stog/eris_stog_common.cmx $<

_client/stog/eris_stog_common.cmo: stog/eris_stog_common.eliom
	js_of_eliom $(OF_FLAGS) $(COMPFLAGS_CLIENT) -type-dir . -c -o _client/stog/eris_stog_common.cmo $<

_client/stog/eris_stog_client.cmx: stog/eris_stog_client.ml
	js_of_eliom $(OF_FLAGS) $(COMPFLAGS_CLIENT) -type-dir . -c -o _client/stog/eris_stog_client.cmx $<

_client/stog/eris_stog_client.cmo: stog/eris_stog_client.ml
	js_of_eliom $(OF_FLAGS) $(COMPFLAGS_CLIENT) -type-dir . -c -o _client/stog/eris_stog_client.cmo $<

_client/stog/eris_stog_types.cmi: stog/eris_stog_types.mli
	$(OCAMLFIND) ocamlc $(OF_FLAGS) $(COMPFLAGS_CLIENT) -c -o $@ $<

_client/stog/eris_stog_types.cmx: stog/eris_stog_types.ml _client/stog/eris_stog_types.cmi
	$(OCAMLFIND) ocamlopt $(OF_FLAGS) $(COMPFLAGS_CLIENT) -c -o $@ $<

_client/stog/eris_stog_types.cmo: stog/eris_stog_types.ml _client/stog/eris_stog_types.cmi
	$(OCAMLFIND) ocamlc $(OF_FLAGS) $(COMPFLAGS_CLIENT) -c -o $@ $<



stog/eris_stog_server.cmx: stog/eris_stog_server.ml
	eliomopt $(OF_FLAGS) $(COMPFLAGS) -c -o stog/eris_stog_server.cmx $<

#stog/eris_stog_server.mli: stog/eris_stog_server.ml
#	eliomopt $(OF_FLAGS) $(COMPFLAGS) -infer > stog/eris_stog_server.mli $<

stog/eris_stog_server.cmo: stog/eris_stog_server.ml
	eliomc $(OF_FLAGS) $(COMPFLAGS) -c -o stog/eris_stog_server.cmo $<

.PRECIOUS: stog/eris_stog_server.mli

stog/eris_stog.cmx stog/eris_stog.cmi: stog/eris_stog.eliom
	eliomopt $(OF_FLAGS) $(COMPFLAGS) -c -o stog/eris_stog.cmx $<
	eliomopt -type-dir . -infer $(OF_FLAGS) $(COMPFLAGS) $<


stog/eris_stog.cmo stog/eris_stog.cmi: stog/eris_stog.eliom
	eliomc $(OF_FLAGS) $(COMPFLAGS) -c -o stog/eris_stog.cmo $<
