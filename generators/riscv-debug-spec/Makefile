
# Configuratin for targets.mak
VERSION=latest

TOP_DIR=../../
SRC_REPO=riscv-debug-spec
OUT_DOC:=${SRC_REPO}
TEX_SRC_DIR=external/${SRC_REPO}/${VERSION}
SRC_DIR=${TOP_DIR}/${TEX_SRC_DIR}
DOC=debug

TOP=riscv-debug-spec

# Config for template header
TITLE="RISC-V External Debug Support"
CATEGORY="RISC-V ISA: Debug-Level"

include ../vars.mak

SPECREV:=$(shell grep '{\\versionnum}' ${SRC_DIR}/${TOP}.tex | cut -f 3 -d'{' | cut -f1 -d'\' ) # '

# Source files
TEX_INC_FILES:=${shell grep '^\\input' img-preamble.tex | cut -f2 -d'{' | cut -f1 -d'}'}
TEX_INC_COPY_FILES:=${TEX_INC_FILES:%=${SRC_DIR}/%}
COPY_FILES=${TEX_INC_FILES:%=${SRC_DIR}/%}

PREAMBLE_FILES=\
	${SCRIPTS}/new-commands.tex \
	${HTML_TMP0_DIR}/version.tex \
	pandoc-preamble.tex \
	${HTML_TMP0_DIR}/registers.tex
IMG_PREAMBLE_FILES=\
	${SCRIPTS}/img-modules.tex \
	${SCRIPTS}/new-commands.tex \
	img-preamble.tex 

# Local Vars
PREFACE=\
   preface
CHAPTERS=\
	introduction \
	reading_order \
	overview \
	debug_module 

CHAPTERS+=\
	core_debug \
	trigger

#CHAPTERS+=\
#    Sdext \
#    Sdtrig 

CHAPTERS+=\
	dtm \
	jtagdtm
APPENDIX=\
	implementations \
	debugger_implementation 

OTHER_TEX = vc.tex changelog.tex

REGISTERS_TEX = jtag_registers.tex
REGISTERS_TEX += core_registers.tex
REGISTERS_TEX += hwbp_registers.tex
REGISTERS_TEX += dm_registers.tex
REGISTERS_TEX += sample_registers.tex
REGISTERS_TEX += abstract_commands.tex
REGISTERS_TEX += sw_registers.tex
REGISTERS_TEX += serial.tex

#	future
TEX_EXTRA_FILES=\
	${HTML_TMP0_DIR}/riscv-spec.bib.yaml \
	post-process.re \
	${HTML_TMP0_DIR}/html-links.re

PREAMBLE=${SRC_DIR}/preamble.tex

ALL=${TOP} ${PREFACE} ${CHAPTERS} ${APPENDIX} ${REGISTERS_TEX:%.tex=%} ${OTHERS_TEX:%.tex=%}

GEN_REGISTERS=${REGISTERS_TEX:%=${SRC_DIR}/%} 
GEN_FILES=${OTHER_TEX:%=${SRC_DIR}/%}

include ../targets-tex.mak

${HTML_TARGETS} : ${GEN_REGISTERS} ${GEN_FILES}

gen : ${GEN_REGISTERS}

${GEN_FILES} : 
	${MAKE} -C ${SRC_DIR} 

${GEN_REGISTERS} :
	cd ${SRC_DIR} && \
		./registers.py \
			--custom --definitions ${@F}.inc \
			--cheader $(basename ${@F}).h ${@F:%.tex=xml/%.xml} > ${@F}.tmp && cp ${@F}.tmp ${@F}

clean_gen:
	rm -f ${GEN_REGISTERS}

deps::
	pip3 install sympy

info ::
	@echo GEN_FILES=${GEN_FILES}

${HTML_TMP0_DIR}/riscv-debug-spec.tex : ${SRC_DIR}/riscv-debug-spec.tex Makefile
	${__MKDIR_TMP}
	cat  $< | egrep -v 'defregname|deffieldname|registers\.tex\.inc' > $@


${HTML_TMP0_DIR}/version.tex:
	${__MKDIR_TMP}
	rm -f $@
	echo '\\newcommand{\\versionnum}{${SPECREV}}' >> $@


# Remove duplicates
${HTML_TMP0_DIR}/registers.tex: ${TEX_INC_COPY_FILES}
	${__MKDIR_TMP}
	rm -f $@
	sort -u ${TEX_INC_COPY_FILES} >$@

${TOP_DIR}/.git/modules/${TEX_SRC_DIR}/logs/HEAD :

${SRC_DIR}/vc.tex: ${TOP_DIR}/.git/modules/${TEX_SRC_DIR}/logs/HEAD
	# https://thorehusfeldt.net/2011/05/13/including-git-revision-identifiers-in-latex/
	echo "%%% This file is generated by Makefile." > $@
	echo "%%% Do not edit this file!\n%%%" >> $@
	-cd ${@D} && git log -1 --format="format:\
	    \\gdef\\GITHash{%H}\
	    \\gdef\\GITAbrHash{%h}\
	    \\gdef\\GITAuthorDate{%ad}\
	    \\gdef\\GITAuthorName{%an}" >> vc.tex

${SRC_DIR}/changelog.tex: ${TOP_DIR}/.git/modules/${TEX_SRC_DIR}/logs/HEAD Makefile
	echo "%%% This file is generated by Makefile." > $@
	echo "%%% Do not edit this file!\n%%%" >> $@
	cd ${@D} && git log --no-merges --date=short --pretty="format:vhEntry{%h}{%ad}{%an}{%s}" | \
	    sed -e "s,\\\\,{\\\\textbackslash},g" -e "s,[_#^],\\\\&,g" -e s/^/\\\\/ >> changelog.tex

