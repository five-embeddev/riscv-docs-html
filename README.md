# RISCV Docs to HTML

RISC-V ISA Specs Converted to HTML and YAML.

(See http://five-embeddev.com/riscv-isa-manual/)

Build Environment
-----------------

A Docker environment is used to install all dependencies and build the
documents.

The files are:

    Dockerfile          - Create an environment with all documentation tools
                          and scripting languages installed.  
    docker-compose.yaml - Configuration used to run Docker.
    Gemfile             - Dependencies for ruby.


Build Modes
-----------

plain 
: HTML output for gh-pages.

jekyll 
: HTML output jekyll based static web page. (e.g <http://five-embeddev.com/riscv-isa-manual/>)

Folders
-------

     external/     - Submodules linking to official documentation repos.
     generators/   - Generate HTML and YAML from source in external/
     tex/          - Quick and dirty patch for some tex files.

Generator Scripts
----------------

    Makefile - Top level build script
    generators/
       var.mak - Common build vars/paths etc.
       targets.mak - Common build targets.
       targets-tex.mak - Recipes to convert tex to html.
       targets-adoc.mak - Recipes to convert asciidoc to html.
       scripts/
           convert_csrs.py - Import CSRs from riscv-opcodes repo
           convert_csrs.rb - Generate CSR definition YAML file from 
                              riscv-opcodes and riscv-isa-manual
           convert_opcodes.rb - Generate Opcodes YAML 
           html_extract.rb - Helper module to extract opcode info from HTML.
           collect-headings.rb - Create YAML file to be used as menu data
           pre-process.rb - Extract images and tables that pandoc can't 
                            render and convert them via tex to SVG or PNG.
           post-process.rb - A set of perl regular expressions to 
                             clean up pandoc output.
           img-modules.tex - Tex dependencies for images extracted 
                             by pre-process.rb.
           new-commands.tex - Tex commands for pandoc generation.
