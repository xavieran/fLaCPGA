#!/bin/bash
pdflatex Requirements.tex
bibtex Requirements.aux
pdflatex Requirements.tex

pandoc -f latex -t markdown_github Requirements.tex > Requirements.md
