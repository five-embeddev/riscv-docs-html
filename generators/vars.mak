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
OUTPUT_FORMAT=plain

# Output paths
HTML_DST_DIR=${DOCS_OUTPUT_DIR}/${OUT_DOC}/${VERSION}
MENU_DST_DIR=${MENU_OUTPUT_DIR}/${OUT_DOC}/${VERSION}

SRC_DOCS=\
	riscv-user-isa-manual/latest/user \
	riscv-priv-isa-manual/latest/priv \
	riscv-debug-spec/latest/debug \
	riscv-v-spec/draft/vector \
	riscv-bitmanip/draft/bitmanip

# Common data files
KEYWORDS_YAML=${DATA_OUTPUT_DIR}/keywords.yaml
KEYWORDS_DOCS=${SRC_DOCS:%=%-keywords.yaml}
CSR_YAML=${DATA_OUTPUT_DIR}/csr.yaml
OPCODE_YAML=${DATA_OUTPUT_DIR}/opcodes.yaml

# Helper Vars
CONVERT_DATE:=${shell date +%Y/%m/%d}
GITREV:=$(shell cd ${SRC_DIR} && git describe --tags HEAD || git rev-parse --short HEAD)
GITURL:=$(shell cd ${SRC_DIR} && git remote get-url origin)
SPEC_REV=${GITREV}

# Helper commands
HTML_TMP0_DIR=tmp.${VERSION}
__MKDIR_DST=-if [ ! -d ${HTML_DST_DIR} ] ; then mkdir -p ${HTML_DST_DIR} ; fi
__MKDIR_TMP=-if [ ! -d ${HTML_TMP0_DIR} ] ; then mkdir -p ${HTML_TMP0_DIR} ; fi
__MKDIR_DATA=-if [ ! -d ${DATA_OUTPUT_DIR} ] ; then mkdir -p ${DATA_OUTPUT_DIR} ; fi

