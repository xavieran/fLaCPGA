#!/bin/bash
pdflatex ProgressReport.tex
bibtex ProgressReport.aux
pdflatex ProgressReport.tex

pandoc -f latex -t markdown_github ProgressReport.tex > ProgressReport.md
