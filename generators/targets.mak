all :: ${TARGETS}

menu : ${MENU_DST_DIR}/${DOC}.yaml

COLLECT_HEADING=${SCRIPTS}/collect-headings.rb

${MENU_DST_DIR}/${DOC}.yaml ${MENU_DST_DIR}/${DOC}-keywords.yaml :  ${SCRIPTS}/collect-headings.rb ${ALL:%=${HTML_DST_DIR}/%.html}
	-mkdir -p ${MENU_DST_DIR} 2> /dev/null
	rm -rf ${MENU_DST_DIR}/${DOC}.yaml ${MENU_DST_DIR}/${DOC}-keywords.yaml
	ruby ${SCRIPTS}/collect-headings.rb \
		--keywords-yaml ${MENU_DST_DIR}/${DOC}-keywords.yaml \
		--base-path ${DOCS_OUTPUT_DIR} \
		--yaml-out ${MENU_DST_DIR}/${DOC}.yaml \
		--html-out ${HTML_DST_DIR}/00-${DOC}.html \
		${ALL:%=${HTML_DST_DIR}/%.html}  

${KEYWORDS_YAML} : ${KEYWORDS_DOCS:%=${MENU_OUTPUT_DIR}/%}
	${__MKDIR_DATA}
	rm -f $@
	${SCRIPTS}/merge-keywords.rb --keywords-yaml $@ $^

.PHONY : menu	

info ::
	@echo DOC=${DOC}
	@echo TITLE=${TITLE}
	@echo SPECREV=${SPECREV} 
	@echo SPECMONTHYEAR=${SPECMONTHYEAR} 
	@echo TOP_DIR=${TOP_DIR}
	@echo SRC_DIR=${SRC_DIR}
	@echo KEYWORDS_YAML=${KEYWORDS_YAML}
	@echo KEYWORDS_DOCS=${KEYWORDS_DOCS}

all :: imgs

imgs : 
	-cp ${HTML_TMP0_DIR}/*.png ${HTML_DST_DIR}/ 2> /dev/null
	-cp ${HTML_TMP0_DIR}/*.svg ${HTML_DST_DIR}/ 2> /dev/null

${MENU_OUTPUT_DIR}/riscv-isa-manual/latest/user-keywords.yaml :
	${MAKE} DOC=user -C ../riscv-isa-manual menu

${MENU_OUTPUT_DIR}/riscv-isa-manual/latest/priv-keywords.yaml :
	${MAKE} DOC=priv -C ../riscv-isa-manual menu

${MENU_OUTPUT_DIR}/riscv-debug-spec/latest/debug-keywords.yaml :
	${MAKE} -C ../riscv-debug-spec menu

${MENU_OUTPUT_DIR}/riscv-v-spec/draft/vector-keywords.yaml :
	${MAKE} -C ../riscv-v-spec menu

${MENU_OUTPUT_DIR}/riscv-bitmanip/latest/bitmanip-keywords.yaml :
	${MAKE} -C ../riscv-bitmanip menu
