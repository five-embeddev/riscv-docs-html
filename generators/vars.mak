# Set by parent:
# TOP_DIR=../../ (of this git repo)
# SRC_REPO=riscv-foo-spec (of the original tex document)
# SRC_DIR=location of tex or adoc source
# VERSION=latest (TBD - allow multi versions)
# DOC=foo (name of debug doc)
# TITLE=The Foo Spec (inserted into template.html $title$)
# CATEGORY=The Foo Category (inserted into template.html $category$)
# SPECREV=Foo Revision (inserted into template.html $specrev$)
# SPECMONTHYEAR=Spec Release Date (inserted into template.html $specmonthyear$)
# ALL= .. tex files ... (files to convert to HTML files)
# COPY_FILES=other files to copy to working dir but not converted
# PREAMBLE_FILES= inserted in generated html and figure tex files
# IMG_PREAMBLE_FILES= inserted in generated figure tex files
# BIB_FILES= tex bib file

# Paths
THIS_DIR=${TOP_DIR}/generators/
SCRIPTS=${THIS_DIR}/scripts/
TEMPLATES=${THIS_DIR}/templates/
DOCS_OUTPUT_DIR=${TOP_DIR}/references
MENU_OUTPUT_DIR=${TOP_DIR}/data
DATA_OUTPUT_DIR=${TOP_DIR}/data
OUTPUT_FORMAT?=plain

#VERSION_user=riscv-user-2.2
VERSION_user=Priv-v1.12
VERSION_priv=Priv-v1.12
VERSION_vector=v1.0
VERSION_debug=v0.13-release
VERSION_bitmanip=1.0.0

SPECREV?=${VERSION}

#VERSION?=${VERSION_${DOC}}


# Output paths
HTML_DST_DIR=${DOCS_OUTPUT_DIR}/${OUT_DOC}/${VERSION}
MENU_DST_DIR=${MENU_OUTPUT_DIR}/${OUT_DOC}/${VERSION}

SRC_DOCS=\
	riscv-user-isa-manual/${VERSION_user}/user \
	riscv-priv-isa-manual/${VERSION_priv}/priv \
	riscv-debug-spec/${VERSION_debug}/debug \
	riscv-v-spec/${VERSION_vector}/vector \
	riscv-bitmanip/${VERSION_bitmanip}/bitmanip

# Common data files
KEYWORDS_YAML=${DATA_OUTPUT_DIR}/keywords.yaml
KEYWORDS_DOCS=${SRC_DOCS:%=%-keywords.yaml}
CSR_YAML=${DATA_OUTPUT_DIR}/csr.yaml
OPCODE_YAML=${DATA_OUTPUT_DIR}/opcodes.yaml
DOCS_OPCODE_YAML=${DOCS_OUTPUT_DIR}/opcodes.yaml

# Helper Vars
CONVERT_DATE:=${shell date +%Y/%m/%d}
GITSRC:=$(shell cd ${SRC_DIR} && git rev-parse --show-prefix)
GITREV:=$(shell cd ${SRC_DIR} && git describe --tags HEAD || git rev-parse --short HEAD | tr '_' '-')
GITURL:=$(shell cd ${SRC_DIR} && git remote get-url origin)
SPECREV=${GITREV}
SPEC_DATE:=$(shell cd ${SRC_DIR} && git log --format=%ad --date=format:'%Y/%m/%d' | head -n1)
SPECMONTHYEAR:=${SPEC_DATE}

# Helper commands
HTML_TMP0_DIR=tmp.${VERSION}
__MKDIR_DST=-if [ ! -d ${HTML_DST_DIR} ] ; then mkdir -p ${HTML_DST_DIR} ; fi
__MKDIR_TMP=-if [ ! -d ${HTML_TMP0_DIR} ] ; then mkdir -p ${HTML_TMP0_DIR} ; fi
__MKDIR_DATA=-if [ ! -d ${DATA_OUTPUT_DIR} ] ; then mkdir -p ${DATA_OUTPUT_DIR} ; fi

# Misc paths
ISA_MANUAL_DIR=${TOP_DIR}/generators/riscv-isa-manual/

