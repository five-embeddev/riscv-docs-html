# user or priv spec
DOC ?= user
VERSION ?= latest-adoc

TOP_DIR=../..

SRC_REPO=riscv-isa-manual
OUT_DOC_user=riscv-user-isa-manual
OUT_DOC_priv=riscv-priv-isa-manual
OUT_DOC=${OUT_DOC_${DOC}}

include ../vars.mak

override DOC_DIR:=${SRC_REPO}/${VERSION}
override SRC_DIR:=${TOP_DIR}/external/${DOC_DIR}/src

TITLE_user=RISC-V Instruction Set Manual, Volume I: RISC-V User-Level ISA
CATEGORY_user=RISC-V ISA: User-Level
TOP_user=riscv-unprivileged

TITLE_priv=The RISC-V Instruction Set Manual, Volume II: Privileged Architecture
CATEGORY_priv=RISC-V ISA: Privileged
TOP_priv=riscv-privileged

TITLE=${TITLE_${DOC}}
CATEGORY=${CATEGORY_${DOC}}
TOP=${TOP_${DOC}}

TOP_FILE=${SRC_DIR}/${TOP}.adoc
ADOC_INCLUDES=${TOP}-a.adoc ${shell egrep '^include:' ${TOP_FILE} | cut -f3 -d: | cut -f1 -d[}
ADOC_FILES=${SRC_DIR}/${TOP}-a.adoc ${ADOC_INCLUDES:%=${SRC_DIR}/%}
HTML_FILES=${ADOC_INCLUDES:%.adoc=%.html}
ALL=${ADOC_FILES:${SRC_DIR}/%.adoc=%}


TARGETS=${HTML_FILES:%=${HTML_DST_DIR}/%} \
			${MENU_DST_DIR}/menu.yaml


ASCIIDOCTOR_FLAGS=\
	   	--require=asciidoctor-bibtex 

asciidoctor: ${TARGETS} 

include ../targets-adoc.mak

${SRC_DIR}/%-a.adoc : ${SRC_DIR}/%.adoc
	grep -v '^include:' $< > $@
