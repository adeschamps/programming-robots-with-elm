.PHONY: help script clean

help: ## Prints a help guide
	@echo "Available tasks:"
	@grep -E '^[\%a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

all: script script-docx slides  ## Build everything

script: script.pdf ## Generate script as a PDF

script-docx: script.docx ## Generate script as a Microsoft Word document

slides: slides.html ## Generate revealjs slides

slides-pdf: slides.pdf ## Generate LaTeX beamer PDF slides



script.pdf: script.md
	pandoc -o $@ $< -V geometry:margin=1in -V papersize=a5

script.docx: script.md
	pandoc -o $@ $<

slides.html: slides.md Makefile
	pandoc -t revealjs -s -o slides.html slides.md -V revealjs-url=http://lab.hakim.se/reveal-js -V transition=fade --slide-level 2 -i --highlight-style zenburn

slides.pdf: slides.md
	pandoc -o $@ $< -t beamer

clean: ## Remove generated files
	rm -rf *.pdf *.docx *.html
