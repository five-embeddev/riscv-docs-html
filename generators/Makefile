
all : debug_gen text menu data

debug_gen:
	${MAKE} -C riscv-debug-spec VERSION=v0.13-release gen

text menu info : 
	cd ..; rd=`pwd`; for dir in `find external/ -name ".git" -type f  `; do  \
		echo "$$rd/`dirname $$dir`"; \
		git config --global --add safe.directory `pwd`/`dirname $$dir`; \
	done
	@echo "USER SPECS"
	${MAKE} OUTPUT_FORMAT=${OUTPUT_FORMAT} DOC=user -C riscv-isa-manual-adoc VERSION=latest-adoc $@
	${MAKE} OUTPUT_FORMAT=${OUTPUT_FORMAT} DOC=user -C riscv-isa-manual VERSION=latest-latex $@
	${MAKE} OUTPUT_FORMAT=${OUTPUT_FORMAT} DOC=user -C riscv-isa-manual VERSION=20181106-Base-Ratification $@
	${MAKE} OUTPUT_FORMAT=${OUTPUT_FORMAT} DOC=user -C riscv-isa-manual VERSION=riscv-user-2.2 $@
	${MAKE} OUTPUT_FORMAT=${OUTPUT_FORMAT} DOC=user -C riscv-isa-manual VERSION=IMFDQC-Ratification-20190305
	${MAKE} OUTPUT_FORMAT=${OUTPUT_FORMAT} DOC=user -C riscv-isa-manual VERSION=Priv-v1.12 $@
	@echo "PRIV SPECS"
	${MAKE} OUTPUT_FORMAT=${OUTPUT_FORMAT} DOC=priv -C riscv-isa-manual-adoc VERSION=latest-adoc $@
	${MAKE} OUTPUT_FORMAT=${OUTPUT_FORMAT} DOC=priv -C riscv-isa-manual VERSION=latest-latex $@
	${MAKE} OUTPUT_FORMAT=${OUTPUT_FORMAT} DOC=priv -C riscv-isa-manual VERSION=Priv-v1.12 $@
	${MAKE} OUTPUT_FORMAT=${OUTPUT_FORMAT} DOC=priv -C riscv-isa-manual VERSION=riscv-priv-1.10 $@
	@echo "OTHER SPECS"
	${MAKE} OUTPUT_FORMAT=${OUTPUT_FORMAT} -C riscv-v-spec  VERSION=v1.0 $@
	${MAKE} OUTPUT_FORMAT=${OUTPUT_FORMAT} -C riscv-v-spec  VERSION=0.7.1 $@
	${MAKE} OUTPUT_FORMAT=${OUTPUT_FORMAT} -C riscv-v-spec  VERSION=zvfh $@
	${MAKE} OUTPUT_FORMAT=${OUTPUT_FORMAT} -C riscv-debug-spec VERSION=v0.13-release $@
	${MAKE} OUTPUT_FORMAT=${OUTPUT_FORMAT} -C riscv-bitmanip VERSION=1.0.0 $@

data :
	${MAKE} -C riscv-csr
	${MAKE} -C riscv-opcodes

#info : 
#	${MAKE} -C riscv-csr info

