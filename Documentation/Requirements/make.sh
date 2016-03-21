#!/bin/bash
pdflatex Requirements.tex
bibtex Requirements.aux
pdflatex Requirements.tex
