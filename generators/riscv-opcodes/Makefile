TOP_DIR=../../

include ../vars.mak

CONVERT_RB=${SCRIPTS}/convert_opcodes.rb

SRC_DIR=${TOP_DIR}/external/riscv-isa-manual/latest

OPCODE_PATH=${TOP_DIR}/external/riscv-opcodes/
FS_MANUAL_PATH=${TOP_DIR}/external/riscv-isa-manual/latest/src/

DEFAULT_MANUAL_PATH=/riscv-isa-manual/${VERSION}/

TARGETS=${OPCODE_YAML}

include ../targets.mak

${OPCODE_YAML} : ${CONVERT_RB}
	${__MKDIR_DATA}
	ruby ${CONVERT_RB} \
	    --opcode-path ${OPCODE_PATH} \
		--manual-path ${DEFAULT_MANUAL_PATH} \
		--html-path ${DOCS_OUTPUT_DIR} \
		--output-file ${OPCODE_YAML}

clean : 
	rm -f ${OPCODE_YAML}

