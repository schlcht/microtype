# Makefile for microtype 
# (lots of it stolen from fontspec)

SHELL = /bin/sh
.SUFFIXES:

# Redefine this to print output if you need:
REDIRECT = > /dev/null

help:
	@echo 'microtype makefile targets:'
	@echo ' '
	@echo '            help - (this message)'
	@echo '          unpack - extract all files'
	@echo '             doc - compile documentation'
	@echo '            docc - compile base documentation only'
	@echo '          utfdoc - compile Unicode documentation'
	@echo '            ctan - generate archive for CTAN'
	@echo '             all - unpack & doc'
	@echo '           world - all & ctan'
	@echo '     mostlyclean - remove all intermediary files'
	@echo '           clean - remove all generated and built files'
	@echo ' '
	@echo '         install - install the complete package into your home texmf tree'
	@echo '     sty-install - install the package code only'
	@echo ' install TEXMFROOT=<texmf> - install the package into the path <texmf>'
	@echo ' '
	@echo '     test        - run the test suite'
	@echo '     testerrors  -    ...  or a'
	@echo '     testunknown -    ...  part'
	@echo '     testoutput  -    ...  of it'
	@echo ' test... COMPAT=<TeX Live> - test with other TeX Live release'
	@echo ' test... DEV=1 - test with current developer version'

NAME = microtype
DOC  = $(NAME).pdf
INS  = $(NAME).ins
DTX  = $(NAME).dtx
README = README.md
UTFDOC = $(NAME)-utf.pdf
UTFDTX = $(NAME)-utf.dtx
ALLDTX = $(DTX) $(UTFDTX)

# Files grouped by generation mode
COMPILED = $(DOC)
UNPACKED = microtype.sty letterspace.sty microtype.lua microtype.cfg \
	   microtype-pdftex.def microtype-luatex.def microtype-xetex.def \
	   mt-bch.cfg mt-blg.cfg mt-cmr.cfg mt-euf.cfg mt-eur.cfg mt-eus.cfg \
	   mt-msa.cfg mt-msb.cfg mt-pad.cfg mt-ppl.cfg mt-pmn.cfg mt-ptm.cfg \
	   mt-ugm.cfg mt-mvs.cfg mt-zpeu.cfg \
	   mt-CharisSIL.cfg mt-LatinModernRoman.cfg mt-Palatino.cfg \
	   test-microtype.tex
SOURCE    = $(ALLDTX) $(INS) $(README)
GENERATED = $(UNPACKED) $(COMPILED)

CTAN_FILES = $(SOURCE) $(COMPILED)

# Files grouped by installation location
UNPACKED_DOC = test-microtype.tex
RUNFILES = $(filter-out $(UNPACKED_DOC), $(UNPACKED))
DOCFILES = $(COMPILED) $(UNPACKED_DOC) $(README)
SRCFILES = $(ALLDTX) $(INS)

ALL_FILES = $(RUNFILES) $(DOCFILES) $(SRCFILES)

# Installation locations
FORMAT = latex
RUNDIR = $(TEXMFROOT)/tex/$(FORMAT)/$(NAME)
DOCDIR = $(TEXMFROOT)/doc/$(FORMAT)/$(NAME)
SRCDIR = $(TEXMFROOT)/source/$(FORMAT)/$(NAME)
TEXMFROOT = $(shell kpsewhich --var-value TEXMFHOME)

CTAN_ZIP = $(NAME).zip
TDS_ZIP  = $(NAME).tds.zip
ZIPS     = $(CTAN_ZIP) $(TDS_ZIP)

DO_PDFLATEX  = pdflatex --interaction=nonstopmode $< $(REDIRECT)
DO_LUALATEX  = lualatex --interaction=nonstopmode $< $(REDIRECT)
DO_MAKEINDEX = touch $(subst .dtx,.glo,$(ALLDTX)) && \
	       makeindex -s microtype-gind.ist $(subst .dtx,,$<) $(REDIRECT)  2>&1 && \
	       makeindex -s gglo.ist -t $(subst .dtx,.glg,$<) -o $(subst .dtx,.gls,$<) \
	                 $(subst .dtx,.glo,$(ALLDTX)) $(REDIRECT)  2>&1

all: $(GENERATED)
doc:    make-doc-sty $(COMPILED) make-normal-sty
utfdoc: make-doc-sty $(UTFDOC)   make-normal-sty
unpack: docstrip.cfg $(UNPACKED) 
ctan:   $(CTAN_ZIP)
tds:    $(TDS_ZIP)
world:  all ctan

.PHONY: help install sty-install manifest mostlyclean clean \
	test testerrors testunknown testoutput

# for the documentation we need the debug version of microtype.sty 
# as well as microtype-doc.sty and microtype-gind.ist
make-doc-sty: $(INS) $(DTX) docstrip.cfg  
	@echo "Creating doc sty"
	@sed -i '' '/\\def\\DEBUG/s/^%//'   $<
	@sed -i '' '/microtype-gind/s/^%//' $<
	@sed -i '' '/microtype-doc/s/^%//'  $<
	@pdflatex --interaction=nonstopmode $< $(REDIRECT)
	@touch make-doc-sty

# undo
make-normal-sty: $(INS) $(DTX) docstrip.cfg  
	@echo "Creating normal sty"
	@sed -i '' '/\\def\\DEBUG/s/^\\/%\\/'   $<
	@sed -i '' '/microtype-doc/s/^\\/%\\/'  $<
	@sed -i '' '/microtype-gind/s/^\\/%\\/' $<
	@pdflatex --interaction=nonstopmode $< $(REDIRECT)
	@touch make-doc-sty
	@touch make-normal-sty

$(DOC): $(DTX) $(UTFDOC) 
	@echo "Compiling documentation (including Unicode part)"
	@$(DO_MAKEINDEX)
	@$(DO_PDFLATEX)
	@while `grep 'Rerun to get \|pdfTeX warning (dest)' $(NAME).log > /dev/null` ; do \
		echo "Re-compiling documentation" ; \
		$(DO_MAKEINDEX) ; \
		$(DO_PDFLATEX) ; \
	done
	@touch $(NAME)-utf.tmp
	@touch $(UTFDOC)
	@touch $(DOC)

$(UTFDOC): $(UTFDTX) $(NAME)-utf.tmp 
	@echo "Compiling Unicode documentation"
	@$(DO_LUALATEX)

# microtype-utf.tmp is used to communicate counters
# from microtype.dtx to microtype-utf.dtx
$(NAME)-utf.tmp: $(DTX) 
	@echo "Compiling documentation (without Unicode part)"
	-@$(DO_PDFLATEX)
	@if ! grep -i '* Checksum passed *' $(NAME).log > /dev/null ; then \
		if grep 'has no checksum\|Checksum not passed' $(NAME).log ; then \
			false ; \
		fi ; \
	fi
	@echo "Re-compiling documentation"
	@$(DO_MAKEINDEX)
	@$(DO_PDFLATEX)

docc:	$(DTX)
	@echo "Compiling documentation"
	@$(DO_MAKEINDEX)
	@$(DO_PDFLATEX) -draft
	@echo "Re-compiling documentation"
	@$(DO_MAKEINDEX)
	@$(DO_PDFLATEX)
	@while `grep 'Rerun to get \|pdfTeX warning (dest)' $(NAME).log > /dev/null` ; do \
		echo "Re-compiling documentation" ; \
		$(DO_MAKEINDEX) ; \
		$(DO_PDFLATEX) ; \
	done

$(UNPACKED): $(INS) $(DTX) docstrip.cfg 
	@echo "Extracting package"
	@$(DO_PDFLATEX)
	@if test ! -f $@ ; then \
		echo "!! $@ not created!" ; \
		false ; \
	fi

docstrip.cfg:
	@echo "\\\\askforoverwritefalse" > docstrip.cfg

$(CTAN_ZIP): manifest doc $(CTAN_FILES) $(TDS_ZIP)
	@echo "Making $@ for CTAN upload."
	@$(RM) -- $@
	@mkdir ./$(NAME)
	@cp $(CTAN_FILES) ./$(NAME)
	@zip -9 -r $@ ./$(NAME) $(TDS_ZIP) $(REDIRECT)
	@$(RM) -r ./$(NAME)
	@unzip -l $@

define run-install
@mkdir -p $(RUNDIR) && cp $(RUNFILES) $(RUNDIR)
@mkdir -p $(DOCDIR) && cp $(DOCFILES) $(DOCDIR)
@mkdir -p $(SRCDIR) && cp $(SRCFILES) $(SRCDIR)
endef

define run-sty-install
@mkdir -p $(RUNDIR) && cp $(RUNFILES) $(RUNDIR)
endef

$(TDS_ZIP): TEXMFROOT=./tmp-texmf
$(TDS_ZIP): $(ALL_FILES)
	@echo "Making TDS-ready archive $@."
	@$(RM) -- $@
	$(run-install)
	@cd $(TEXMFROOT) && zip -9 ../$@ -r . $(REDIRECT)
	@$(RM) -r -- $(TEXMFROOT)

install: doc $(ALL_FILES)
	@if test ! -n "$(TEXMFROOT)" ; then \
		echo "Cannot locate your home texmf tree. Specify manually with\n\n    make install TEXMFROOT=/path/to/texmf\n" ; \
		false ; \
	fi ;
	@echo "Installing in '$(TEXMFROOT)'."
	$(run-install)

sty-install: $(RUNFILES)
	@if test ! -n "$(TEXMFROOT)" ; then \
		echo "Cannot locate your home texmf tree. Specify manually with\n\n    make install TEXMFROOT=/path/to/texmf\n" ; \
		false ; \
	fi ;
	@echo "Installing in '$(TEXMFROOT)'."
	$(run-sty-install)

manifest: $(SOURCE) 
	@echo "=== Source files ==="
	@LANG=C && sed -n '/%<\*package|letterspace|m-t|pdftex-def|luatex-def|xetex-def>$$/{N;s/.*\[\(.*\)$$/-- \1 ($(DTX))/p;}' $(DTX)
	@LANG=C && sed -n '/ *version *= *.*$$/{N;s/^.*= *"\(.*\)",.*date *= *"\(.*\)",/  (\2 v\1 (microtype.lua))/p;}' $(DTX)
	@sed -n '/%<\*driver>$$/{N;/{\\jobname\.dtx}/ s/^.*\[\(.*\)\]$$/-- \1 ($(UTFDTX))/p;}' $(UTFDTX)
	@sed -n 's/^ *(\(v[^ ]*\) *-- *\([^ ]*\))$$/-- \2 \1 ($(README))/p' $(README)
	@echo ""
	@echo "=== Derived files ==="
	@for f in $(UNPACKED); do echo "$$f"; done
	@echo "----------------------------"
	@if grep '\-\-'`date -v-1y +%Y` $(SOURCE); then echo "!!!! Copyright strings not up to date !!!!" ; fi

mostlyclean:
	@$(RM) -- *.log *.aux *.toc *.idx *.ind *.ilg *.glo *.gls *.glg *.lot *.out *.synctex* *.tmp *.pl *.mtx \
		docstrip.cfg $(UTFDOC) microtype-doc.sty microtype-gind.ist make-*-sty 

clean: mostlyclean
	@$(RM) -- $(GENERATED) $(ZIPS)

# testing the package
TESTDIR = ./testsuite
WORDCOUNT = ~/texmf/scripts/wordcount/wordcount.sh
COMPAT = $(shell which tlmgr | sed 's/.*\/\(.*\)\/bin\/.*/\1/')
TLPATH = ~/Library/texlive/$(COMPAT)/bin/x86_64-darwin
test: testerrors testunknown testoutput
	@$(RM) $(TESTDIR)/*.log
	@$(RM) $(TESTDIR)/*.aux
	@$(RM) $(TESTDIR)/*.pdf
	@$(RM) $(TESTDIR)/*.tmp
	@$(RM) $(TESTDIR)/*.4ct
	@$(RM) $(TESTDIR)/*.4tc
	@$(RM) $(TESTDIR)/*.dvi
	@$(RM) $(TESTDIR)/*.xref
#	@$(RM) $(TESTDIR)/*.1
#	@$(RM) $(TESTDIR)/*.1R
	@$(RM) $(TESTDIR)/*.pgf

testerrors: $(wildcard $(TESTDIR)/error-*.tex)
	@echo "* Errors:"
	@cd $(TESTDIR) && \
		$(foreach file,$^,$(call run-test-file,error,$(notdir $(basename $(file)))))
	@echo " - wordcount"
	@cd $(TESTDIR) && \
		if ! `$(WORDCOUNT) errorx-wordcount > /dev/null` ; \
	        	then $(not-ok) ; \
		fi

testunknown: $(wildcard $(TESTDIR)/unknown-*.tex)
	@echo "* Unknown slots:"
	@cd $(TESTDIR) && \
		$(foreach file,$^,$(call run-unknown-file,$(notdir $(basename $(file)))))

testoutput: $(wildcard $(TESTDIR)/output-*.tex)
	@echo "* Output:"
	@cd $(TESTDIR) && \
		$(foreach file,$^,$(call run-output-file,$(notdir $(basename $(file)))))

ifdef DEV
override DEV=-dev
endif
# parts of the filename after `_' signify an engine other than pdflatex
run-test-file = \
	echo " - $(subst $1-,,$2)" | sed 's/\(.*\)_\(.*\)/\1 (\2)/' ; \
	if ! `$(if $(shell echo $2 | grep _),\
		   $(TLPATH)/$(shell echo $2 | sed -n 's/.*_\(.*\)/\1/p' | sed -e '/latex/s/$$/$(DEV)/'),\
		   $(TLPATH)/pdflatex$(DEV)) --interaction=batchmode $2 > /dev/null` ; \
		then $(not-ok) ; \
	fi ;

# there mustn't be unknown slots
run-unknown-file = \
	$(call run-test-file,unknown,$1) \
	if `grep 'Unknown slot number' $1.log > /dev/null` ; \
		then $(not-ok) ; \
	fi ;

# the test files themselves contain the relevant grep command
run-output-file = \
	$(call run-test-file,output,$1) \
	if ! $$(eval $$(grep grep $1.tex) $1.log > /dev/null) ; \
		then $(not-ok) ; \
	fi ; 

not-ok = echo "  ... NOT OK !!! <-------" 

