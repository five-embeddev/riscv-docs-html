
all : debug_gen text menu data

debug_gen:
	${MAKE} -C riscv-debug-spec VERSION=v0.13-release gen

text menu : 
	${MAKE} DOC=user -C riscv-isa-manual-adoc VERSION=latest-adoc $@
	${MAKE} DOC=user -C riscv-isa-manual VERSION=latest-latex $@
	${MAKE} DOC=user -C riscv-isa-manual VERSION=20181106-Base-Ratification $@
	${MAKE} DOC=user -C riscv-isa-manual VERSION=riscv-user-2.2 $@
	${MAKE} DOC=user -C riscv-isa-manual VERSION=IMFDQC-Ratification-20190305
	${MAKE} DOC=user -C riscv-isa-manual VERSION=Priv-v1.12 $@

	${MAKE} DOC=priv -C riscv-isa-manual-adoc VERSION=latest-adoc $@
	${MAKE} DOC=priv -C riscv-isa-manual VERSION=latest-latex $@
	${MAKE} DOC=priv -C riscv-isa-manual VERSION=Priv-v1.12 $@
	${MAKE} DOC=priv -C riscv-isa-manual VERSION=riscv-priv-1.10 $@
	${MAKE} -C riscv-v-spec  VERSION=v1.0 $@
	${MAKE} -C riscv-v-spec  VERSION=0.7.1 $@
	${MAKE} -C riscv-v-spec  VERSION=zvfh $@
	${MAKE} -C riscv-debug-spec VERSION=v0.13-release $@
	${MAKE} -C riscv-bitmanip VERSION=1.0.0 $@

data :
	${MAKE} -C riscv-csr
	${MAKE} -C riscv-opcodes

info : 
	${MAKE} -C riscv-csr info

