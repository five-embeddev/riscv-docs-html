# user or priv spec
DOC ?= user

# Configuratin for targets.mak
VERSION=latest
TOP_DIR=../../
SRC_REPO=riscv-isa-manual
OUT_DOC_user=riscv-user-isa-manual
OUT_DOC_priv=riscv-priv-isa-manual
OUT_DOC=${OUT_DOC_${DOC}}
SRC_DIR=${TOP_DIR}/external/${SRC_REPO}/${VERSION}/src
BIB_FILES=riscv-spec.bib

TITLE_user="RISC-V Instruction Set Manual, Volume I: RISC-V User-Level ISA"
CATEGORY_user="RISC-V ISA: User-Level"
TOP_user=riscv-spec

TITLE_priv="The RISC-V Instruction Set Manual, Volume II: Privileged Architecture"
CATEGORY_priv="RISC-V ISA: Privileged"
TOP_priv=riscv-privileged

TITLE=${TITLE_${DOC}}
CATEGORY=${CATEGORY_${DOC}}
TOP=${TOP_${DOC}}


include ../vars.mak


PREFACE=${PREFACE_${DOC}}
CHAPTERS=${CHAPTERS_${DOC}}
APPENDIX=${APPENDIX_${DOC}}
ALL=${TOP} ${PREFACE} ${CHAPTERS} ${APPENDIX}

SPECREV_user:=$(shell grep '{\\specrev}' ${SRC_DIR}/${TOP_user}.tex | cut -f 4 -d'{' | cut -f1 -d'}' )
SPECMONTHYEAR_user:=$(shell grep '{\\specmonthyear}' ${SRC_DIR}/${TOP}.tex | cut -f 4 -d'{' | cut -f1 -d'}' )
SPECREV_priv:=$(shell grep '{\\privrev}' ${SRC_DIR}/${TOP_priv}.tex | cut -f 3 -d'{' | cut -f1 -d'}' )
SPECMONTHYEAR_priv:=$(shell grep '{\\privmonthyear}' ${SRC_DIR}/${TOP}.tex | cut -f 4 -d'{' | cut -f1 -d'}' )
#/usr/share/texlive/texmf-dist/tex/latex/graphics/graphicx.sty

SPECREV=${SPECREV_${DOC}}
SPECMONTHYEAR=${SPECMONTHYEAR_${DOC}}

PREAMBLE_FILES=\
	${SCRIPTS}/new-commands.tex \
	pandoc-preamble.tex \
	${HTML_TMP0_DIR}/version.tex
IMG_PREAMBLE_FILES=\
	${SCRIPTS}/img-modules.tex \
	${SCRIPTS}/new-commands.tex \
	img-preamble.tex \
	${HTML_TMP0_DIR}/version.tex

# File config, user
PREFACE_user=\
   preface

CHAPTERS_user=\
   intro \
   rv32 \
   zifencei \
   zihintpause \
   rv32e \
   rv64 \
   rv128 \
   m \
   a \
   csr \
   counters \
   f \
   d \
   q \
   zfh \
   rvwmo \
   c \
   b \
   j \
   p \
   v \
   zam \
   zfinx \
   ztso \
   gmaps \
   extensions \
   naming \
   history
APPENDIX_user=\
   dep-table \
   opcode-map \
   instr-table \
   rvc-opcode-map \
   rvc-instr-table \
   memory \
   memory-model-alloy \
   memory-model-herd \
   memory-model-operational

CHAPTERS_priv = \
   priv-intro \
   priv-csrs \
   machine \
   supervisor \
   hypervisor \
   cfgstr \
   plic \
   priv-insns \
   priv-history 

APPENDIX_priv=\
   priv-instr-table

TEX_EXTRA_FILES=\
	${HTML_TMP0_DIR}/riscv-spec.bib.yaml \
	post-process.re \
	${HTML_TMP0_DIR}/html-links.re

PREAMBLE=${SRC_DIR}/preamble.tex

TARGETS=${ALL:%=${HTML_DST_DIR}/%.html} ${MENU_DST_DIR}/${DOC}.yaml

include ../targets-tex.mak

rev:
	echo ${SPECREV_priv}
	echo ${SPECREV_user}

${HTML_TMP0_DIR}/version.tex:
	${__MKDIR_TMP}
	rm -f $@
	echo '\\newcommand{\\specrev}{${SPECREV_user}}' >> $@
	echo '\\newcommand{\\privrev}{${SPECREV_priv}}' >> $@
	echo '\\newcommand{\\specmonthyear}{${SPECMONTHYEAR_user}}' >> $@
	echo '\\newcommand{\\privmonthyear}{${SPECMONTHYEAR_priv}}' >> $@
