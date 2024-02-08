export UID=$(shell id -u)
export GID=$(shell id -g)

CONTAINER_BASE=/project
DOCS_OUTPUT_DIR=references
MENU_OUTPUT_DIR=menu/
DATA_OUTPUT_DIR=external/riscv-isa-data/
OUTPUT_FORMAT?=plain

all data menu text info:
	docker compose build --progress=plain
	docker compose run generate \
		make \
			-C /project/generators  \
			DOCS_OUTPUT_DIR=${CONTAINER_BASE}/${DOCS_OUTPUT_DIR} \
			DATA_OUTPUT_DIR=${CONTAINER_BASE}/${DATA_OUTPUT_DIR} \
			MENU_OUTPUT_DIR=${CONTAINER_BASE}/${MENU_OUTPUT_DIR} \
			OUTPUT_FORMAT=${OUTPUT_FORMAT} \
			$@


v_spec : 
	docker compose run generate \
		make \
				-C /project/generators/riscv-v-spec  \
			DOCS_OUTPUT_DIR=${CONTAINER_BASE}/${DOCS_OUTPUT_DIR} \
			DATA_OUTPUT_DIR=${CONTAINER_BASE}/${DATA_OUTPUT_DIR} \
			MENU_OUTPUT_DIR=${CONTAINER_BASE}/${MENU_OUTPUT_DIR} \
			VERSION=v1.0 \
			text


shell:
	docker compose run shell



.PHONY: all data menu text info
