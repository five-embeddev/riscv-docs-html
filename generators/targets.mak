all text :: ${TARGETS}

menu : ${MENU_DST_DIR}/menu.yaml

COLLECT_HEADING=${SCRIPTS}/collect-headings.rb

${MENU_DST_DIR}/menu.yaml ${MENU_DST_DIR}/${DOC}-keywords.yaml : \
			${COLLECT_HEADING} \
			${ALL:%=${HTML_DST_DIR}/%.html}
	-mkdir -p ${MENU_DST_DIR} 2> /dev/null
	rm -rf ${MENU_DST_DIR}/menu.yaml ${MENU_DST_DIR}/${DOC}-keywords.yaml
	ruby ${COLLECT_HEADING} \
		--keywords-yaml ${MENU_DST_DIR}/${DOC}-keywords.yaml \
		--base-path ${DOCS_OUTPUT_DIR} \
		--yaml-out ${MENU_DST_DIR}/menu.yaml \
		--html-out ${HTML_DST_DIR}/00-index.html \
		${ALL:%=${HTML_DST_DIR}/%.html}  

${KEYWORDS_YAML} : ${KEYWORDS_DOCS:%=${MENU_OUTPUT_DIR}/%}
	${__MKDIR_DATA}
	rm -f $@
	${SCRIPTS}/merge-keywords.rb --keywords-yaml $@ $^

.PHONY : menu	

info ::
	@echo "*** INFO(targets.mak) ${CURDIR}"
	@echo DOC=${DOC}
	@echo TITLE=${TITLE}
	@echo SPECREV=${SPECREV} 
	@echo SPECMONTHYEAR=${SPECMONTHYEAR} 
	@echo TOP_DIR=${TOP_DIR}
	@echo SRC_DIR=${SRC_DIR}
	@echo KEYWORDS_YAML=${KEYWORDS_YAML}
	@echo KEYWORDS_DOCS=${KEYWORDS_DOCS}
	@echo GITREV=$(GITREV)
	@echo GITURL=$(GITURL)
	cd ${SRC_DIR} && git remote get-url origin

VERSIONS_TEX=\
	latest-latex \
	20181106-Base-Ratification \
	riscv-user-2.2 \
	IMFDQC-Ratification-20190305 \
	Priv-v1.12 


VERSIONS_ADOC=latest-adoc

${VERSIONS_TEX:%=${MENU_OUTPUT_DIR}/riscv-user-isa-manual/%/user-keywords.yaml} :
	${MAKE} DOC=user -C ../riscv-isa-manual menu

${VERSIONS_TEX:%=${MENU_OUTPUT_DIR}/riscv-priv-isa-manual/%/priv-keywords.yaml} :
	${MAKE} DOC=priv -C ../riscv-isa-manual menu

${VERSIONS_ADOC:%=${MENU_OUTPUT_DIR}/riscv-user-isa-manual/$%/user-keywords.yaml} :
	${MAKE} DOC=user -C ../riscv-isa-manual menu

${VERSIONS_ADOC:%=${MENU_OUTPUT_DIR}/riscv-priv-isa-manual/%/priv-keywords.yaml} :
	${MAKE} DOC=priv -C ../riscv-isa-manual menu

${MENU_OUTPUT_DIR}/riscv-debug-spec/${VERSION_debug}/debug-keywords.yaml :
	${MAKE} -C ../riscv-debug-spec menu

${MENU_OUTPUT_DIR}/riscv-v-spec/${VERSION_vector}/vector-keywords.yaml :
	${MAKE} -C ../riscv-v-spec menu

${MENU_OUTPUT_DIR}/riscv-bitmanip/${VERSION_bitmanip}/bitmanip-keywords.yaml :
	${MAKE} -C ../riscv-bitmanip menu
