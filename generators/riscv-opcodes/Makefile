TOP_DIR=../../

include ../vars.mak

CONVERT_RB=${SCRIPTS}/convert_opcodes.rb

SRC_DIR=${TOP_DIR}/external/riscv-isa-manual/latest

OPCODE_PATH=${TOP_DIR}/external/riscv-opcodes/

#FS_USER_MANUAL_PATH=${TOP_DIR}/external/riscv-user-isa-manual/latest/src/
#FS_PRIV_MANUAL_PATH=${TOP_DIR}/external/riscv-priv-isa-manual/latest/src/

DEFAULT_USER_MANUAL_PATH=/riscv-user-isa-manual/${VERSION_user}/
DEFAULT_PRIV_MANUAL_PATH=/riscv-priv-isa-manual/${VERSION_priv}/
DEFAULT_VECTOR_MANUAL_PATH=/riscv-v-spec/${VERSION_vector}/

TARGETS=${OPCODE_YAML} ${DOCS_OPCODE_YAML}

include ../targets.mak

${OPCODE_YAML} : ${CONVERT_RB}
	${__MKDIR_DATA}
	ruby ${CONVERT_RB} \
	    --opcode-path ${OPCODE_PATH} \
		--user-manual-path ${DEFAULT_USER_MANUAL_PATH} \
		--priv-manual-path ${DEFAULT_PRIV_MANUAL_PATH} \
		--vector-manual-path ${DEFAULT_VECTOR_MANUAL_PATH} \
		--html-path ${DOCS_OUTPUT_DIR} \
		--output-file ${OPCODE_YAML}

# Keep a copy with the docs output for use in generating a reference that corrosponds to the html files 1:1
${DOCS_OPCODE_YAML} : ${OPCODE_YAML}
	cp $< $@

clean : 
	rm -f ${OPCODE_YAML}

