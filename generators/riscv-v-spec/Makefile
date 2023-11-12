TOP_DIR=../..

override SRC_REPO:=riscv-v-spec
override OUT_DOC:=${SRC_REPO}
override DOC:=vector

include ../vars.mak

override DOC_DIR:=${SRC_REPO}/${VERSION}
override SRC_DIR:=${TOP_DIR}/external/${DOC_DIR}

TITLE=RISC-V Base Vector Extension
CATEGORY=RISC-V ISA: User-Level

ADOC_FILES=${wildcard ${SRC_DIR}/v-spec.adoc}
HTML_FILES=${ADOC_FILES:${SRC_DIR}/%.adoc=%.html}
ALL=${ADOC_FILES:${SRC_DIR}/%.adoc=%}
TOP_FILE=${SRC_DIR}/v-spec.adoc
SPEC_DATE:=$(shell cd ${dir ${TOP_FILE}} &&  git show --pretty='%as' HEAD | head -n1)

TARGETS=${HTML_FILES:%=${HTML_DST_DIR}/%}


asciidoctor: ${TARGETS} 

include ../targets-adoc.mak

