
all : text menu data

text :
	${MAKE} DOC=user -C riscv-isa-manual
	${MAKE} DOC=priv -C riscv-isa-manual
	${MAKE} -C riscv-v-spec 
	${MAKE} -C riscv-debug-spec gen
	${MAKE} -C riscv-debug-spec
	${MAKE} -C riscv-bitmanip

menu :
	${MAKE} DOC=user -C riscv-isa-manual menu
	${MAKE} DOC=priv -C riscv-isa-manual menu
	${MAKE} -C riscv-v-spec menu
	${MAKE} -C riscv-debug-spec menu
	${MAKE} -C riscv-bitmanip menu

data :
	${MAKE} -C riscv-csr
	${MAKE} -C riscv-opcodes


info : 
	${MAKE} -C riscv-csr info

