export UID=$(shell id -u)
export GID=$(shell id -g)

CONTAINER_BASE=/project
DOCS_OUTPUT_DIR=references
MENU_OUTPUT_DIR=menu/
DATA_OUTPUT_DIR=external/riscv-isa-data/

all data menu text info:
	#docker compose build --progress=plain
	docker compose run generate \
		make \
			-C /project/generators  \
			DOCS_OUTPUT_DIR=${CONTAINER_BASE}/${DOCS_OUTPUT_DIR} \
			DATA_OUTPUT_DIR=${CONTAINER_BASE}/${DATA_OUTPUT_DIR} \
			MENU_OUTPUT_DIR=${CONTAINER_BASE}/${MENU_OUTPUT_DIR} \
			$@

shell:
	docker compose run shell



.PHONY: all data menu text info
