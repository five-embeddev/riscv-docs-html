# -*- Makefile -*-

include ${TOP_DIR}/generators/vars.mak

ASCIIDOCTOR=asciidoctor
ADOC_TEMPLATE_plain=${TEMPLATES}/asciidoctor/static/
ADOC_TEMPLATE_jekyll=${TEMPLATES}/asciidoctor/jekyll/
ADOC_TEMPLATE=${ADOC_TEMPLATE_${OUTPUT_FORMAT}}

ADOC_ATTRIBUTES=$(shell egrep '^:' ${TOP_FILE} \
			| perl -pi -e 's@^\:([\w\-]+)\:\s*(.+?)$$@--attribute=$$1=\"$$2\" @'  | grep -- --attribute    )


include ${THIS_DIR}/targets.mak

__MKDIR_TMP=-if [ ! -d ${HTML_TMP0_DIR} ] ; then mkdir ${HTML_TMP0_DIR} ; fi
HTML_TMP0_DIR=tmp.${VERSION}

info ::
	@echo "*** INFO(targets-adoc.mak) AT ${CURDIR} ***"
	@echo ADOC_FILES=${ADOC_FILES}
	@echo HTML_FILES=${HTML_FILES}
	@echo DST_DIR=${DST_DIR}
	@echo HTML_FILES=${HTML_FILES:%=${DST_DIR}/%}
	@echo TOP_FILE=${TOP_FILE}
	@echo DST_DIR=${DST_DIR}/%.html
	@echo SPECREV=${SPECREV}
	@echo "SPEC_DATE=${SPEC_DATE}"
	@echo GITSRC=$(GITSRC)
	@echo GITREV=$(GITREV)
	@echo GITURL=$(GITURL)
	@echo ADOC_ATTRIBUTES=${ADOC_ATTRIBUTES}

# 		--no-header-footer \


${HTML_DST_DIR}/%.html : ${SRC_DIR}/%.adoc ${HEADER}
	${__MKDIR_TMP}
	${__MKDIR_DST}
	perl -pi -e 's/:toc: left//' $<
	cd ${SRC_DIR}; ${ASCIIDOCTOR} \
	   	--require=asciidoctor-diagram \
		${ASCIIDOCTOR_FLAGS} \
		--backend=html \
		--verbose \
		--section-numbers \
		--template-dir=${CURDIR}/${ADOC_TEMPLATE} \
		--template-engine=erb \
		--destination-dir=${@D} \
		--out-file=${@F} \
		--attribute=title="${TITLE}" \
		--attribute=specdoc=${DOC} \
		--attribute=category="${CATEGORY}" \
		--attribute=order=${shell ruby -e 'v=%w{${CHAPTERS}}; i=1; i=v.index("${*}") if v.include?("${*}"); print i;'} \
		--attribute=specrev="${SPECREV}" \
		--attribute=specmonthyear="${SPECMONTHYEAR}" \
		--attribute=source="$(GITSRC)${notdir $<}" \
		--attribute=gitrev="$(GITREV)" \
		--attribute=giturl="$(GITURL)" \
		--attribute=data-uri="" \
		--attribute=convert_date="${CONVERT_DATE}" \
		--trace \
		${ADOC_ATTRIBUTES} \
		$*.adoc

npm :
	rm -rf ${DST_DIR}
	mkdir -p ${DST_DIR}
	cd ${SRC_DIR}; npm i
	cd ${SRC_DIR}; npm run build
	cp -rf ${SRC_DIR}/public ${DST_DIR}


