TOP_DIR=../../

include ../vars.mak

CONVERT_RB=${SCRIPTS}/convert_csrs.rb
CONVERT_PY=${SCRIPTS}/convert_csrs.py

TEX_SRC=${TOP_DIR}/external/riscv-isa-manual/${VERSION_priv}/src/priv-csrs.tex
PYTHON_SRC=${TOP_DIR}/external/riscv-opcodes/constants.py
CSR_SRC=$(wildcard ${TOP_DIR}/external/riscv-opcodes/*.csv)

TARGETS=${CSR_YAML}

include ../targets.mak

${CSR_YAML} : \
		${CONVERT_RB} \
		${TEX_SRC} \
		${KEYWORDS_YAML} \
		${PYTHON_SRC} \
		${CSR_SRC}
	${__MKDIR_DATA}
	cp ${CSR_SRC} .
	ruby ${CONVERT_RB} \
	  --csr-spec-tex ${TEX_SRC} \
	  --keywords-yaml-out ${KEYWORDS_YAML} \
	  --parse-opcodes ${PYTHON_SRC} \
	  --csr-yaml-in ${CSR_YAML} \
	  --csr-yaml-out ${CSR_YAML} \
	  --convert-py ${CONVERT_PY}

clean :
	rm -rf  ${CSR_YAML} convert_csr_info.py


