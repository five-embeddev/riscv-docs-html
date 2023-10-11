# -*- Makefile -*-

include ${TOP_DIR}/generators/vars.mak

# Local paths
TEX_LIBRARY_DIR=${THIS_DIR}/tex
# Change this depending on backend 
PANDOC_TEMPLATE_plain=${TEMPLATES}/pandoc/template_static.html
PANDOC_TEMPLATE_jekyll=${TEMPLATES}/pandoc/template_liquid.html
PANDOC_TEMPLATE=${PANDOC_TEMPLATE_${OUTPUT_FORMAT}}

# Generated files
HTML_TARGETS=${ALL:%=${HTML_DST_DIR}/%.html} 

TARGETS=${HTML_TARGETS} \
		${MENU_DST_DIR}/${DOC}.yaml

include ${THIS_DIR}/targets.mak

dep : ${TEX_EXTRA_FILES} ${PREAMBLE_FILES} ${IMG_PREAMBLE_FILES}


info ::
	@echo CHAPTERS=${CHAPTERS}
	@echo BIB_FILES=${BIB_FILES:%=${HTML_TMP0_DIR}/%.yaml}
	@echo TARGETS=${TARGETS}
	@echo ALL=${ALL}
	@echo PREAMBLE_FILES=${PREAMBLE_FILES}

#new-commands.tex :
#	grep  newcommand ${ALL:%=${SRC_DIR}/%.tex} | cut -f2- -d: > $@

${HTML_TMP0_DIR}/html-links.re : Makefile
	${__MKDIR_TMP}
	cd ${SRC_DIR}/; grep '\\label' *.tex > ${CURDIR}/$@.src
	cd ${SRC_DIR}/; grep '\\label' *.tex | perl -p -e 's@([\w\-\_]+)\.tex\:.*?\\label\{(.*?)\}.*@s|href="#$$2"|href="$$1.html#$$2"|;@' > ${CURDIR}/$@
	for sec in ${ALL} ; do  \
		echo "s|href=\"#$${sec}\"|href=\"$${sec}.html\"|;" >> $@; \
		echo "s|href=\"#$${sec}\.tex\"|href=\"$${sec}.html\"|;" >> $@; \
	done

${HTML_TMP0_DIR}/%.tex : ${SRC_DIR}/%.tex  \
						 ${IMG_PREAMBLE_FILES}  \
						 ${SCRIPTS}/pre-process.rb 
	${__MKDIR_TMP}
	-cp ${TEX_LIBRARY_DIR}/*.sty ${HTML_TMP0_DIR}/
	-cp ${TEX_LIBRARY_DIR}/*.def ${HTML_TMP0_DIR}/
	-cp tex/*.sty ${HTML_TMP0_DIR}/
	-cp tex/*.def ${HTML_TMP0_DIR}/
	-cp *.sty ${HTML_TMP0_DIR}/
	-cp *.def ${HTML_TMP0_DIR}/
	-cp ${COPY_FILES} ${HTML_TMP0_DIR}/
	if [ ! -L ${HTML_TMP0_DIR}/figs ] ; then \
		if [ -d ${SRC_DIR}/figs ] ; then \
			ln -s ../${SRC_DIR}/figs ${HTML_TMP0_DIR}/ ; \
		fi; \
	fi
	if [ ! -L ${HTML_TMP0_DIR}/fig ] ; then \
		if [ -d ${SRC_DIR}/fig ] ; then \
			ln -s ../${SRC_DIR}/fig ${HTML_TMP0_DIR}/; \
		fi; \
	fi
	ruby ${SCRIPTS}/pre-process.rb $< ${IMG_PREAMBLE_FILES} ${HTML_TMP0_DIR}/
	-rm -f ${HTML_TMP0_DIR}/${*}_*_tmp.png 2> /dev/null
	-rm -f ${HTML_TMP0_DIR}/${*}_*_tmp.svg 2> /dev/null


${HTML_TMP0_DIR}/%.html : \
		${HTML_TMP0_DIR}/%.tex \
		${PANDOC_TEMPLATE} \
		${BIB_FILES:%=${HTML_TMP0_DIR}/%.yaml} \
		${PREAMBLE_FILES} 
	rm -rf $@ 2> /dev/null
	${__MKDIR_DST}
	${__MKDIR_TMP}
	pandoc \
		-f latex \
		-t html \
		--template=${PANDOC_TEMPLATE:%.html=%} \
		--strip-empty-paragraphs \
		--wrap=preserve \
		--output=${HTML_TMP0_DIR}/${@F} \
		--verbose \
		--variable title=${TITLE} \
		--variable specdoc=${DOC} \
		--variable category=${CATEGORY} \
		--variable order=${shell ruby -e 'v=%w{${CHAPTERS}}; i=1; i=v.index("${*}") if v.include?("${*}"); print i;'} \
		--variable specrev="${SPECREV}" \
		--variable specmonthyear="${SPECMONTHYEAR}" \
		--variable source="$(shell cd ${SRC_DIR} &&  git rev-parse --show-prefix)${notdir $<}" \
		--variable gitrev="$(GITREV)" \
		--variable giturl="$(GITURL)" \
		--variable convert_date="${CONVERT_DATE}" \
		${BIB_FILES:%=--metadata-file=${HTML_TMP0_DIR}/%.yaml} \
		${shell ruby -e 'v=%w{${CHAPTERS}}; print "--number-sections --number-offset=#{v.index("${*}")}" if v.include?("${*}")'} \
		${PREAMBLE_FILES} $< 2> ${HTML_TMP0_DIR}/${@F}.log


#		 --filter pandoc-citeproc \


${HTML_DST_DIR}/%.html : ${HTML_TMP0_DIR}/%.html ${SCRIPTS}/post-process.re ${HTML_TMP0_DIR}/html-links.re
	${__MKDIR_DST}
	perl -p  ${SCRIPTS}/post-process.re ${HTML_TMP0_DIR}/${@F} > ${HTML_TMP0_DIR}/${@F}.1
	perl -p  ${HTML_TMP0_DIR}/html-links.re ${HTML_TMP0_DIR}/${@F}.1 > $@
	-cp ${HTML_TMP0_DIR}/${*}_*.png ${@D}/ 2> /dev/null
	-cp ${HTML_TMP0_DIR}/${*}_*.svg ${@D}/ 2> /dev/null


${ALL} :
	${MAKE} ${HTML_DST_DIR}/$@.html

${HTML_TMP0_DIR}/%.bib.yaml : ${SRC_DIR}/%.bib
	${__MKDIR_TMP}
	perl -p -e 's@month=([\w+\\\/]+)@month={$1}@' ${SRC_DIR}/${*}.bib  > ${HTML_TMP0_DIR}/${*}.bib
	pandoc-citeproc -y -f bib  ${HTML_TMP0_DIR}/${*}.bib  > $@


do-% :
	${MAKE} ${HTML_DST_DIR}/${*}.html

.PRECIOUS : ${HTML_TMP0_DIR}/%.tex ${HTML_TMP0_DIR}/%.html


clean : 
	rm -rf ${HTML_TMP0_DIR}
	rm  -f ${TARGETS}
