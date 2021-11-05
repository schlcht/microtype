# microtype makefile

SHELL = /bin/sh
.SUFFIXES:

# path
ARCH     := x86_64-darwinlegacy
COMPAT   := $(shell which tlmgr | sed 's/.*\/\(.*\)\/bin\/.*/\1/')
ifeq ($(shell expr $(COMPAT) \< 2021 ),1)
  ARCH := x86_64-darwin
endif
ifeq ($(shell expr $(COMPAT) \< 2014 ),1)
  ARCH := universal-darwin
endif
TLPATH := ~/Library/texlive/$(COMPAT)/bin/$(ARCH)

ifdef DEV
  override DEV=-dev
endif

TESTDIR = ./testsuite
WORDCOUNT = ~/texmf/scripts/wordcount/wordcount.sh
# Redefine to print output:
REDIRECT = > /dev/null

help:
	@echo 'microtype makefile targets:'
	@echo ' '
	@echo '            help - (this message)'
	@echo '          unpack - extract all files'
	@echo '             doc - compile user and code documentation'
	@echo '         userdoc - compile user documentation'
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
	@echo ' test... DEV=1 - test with development version'

NAME    = microtype
NAMEC   = $(NAME)-code
NAMEU   = $(NAME)-utf
DOC     = $(NAME).pdf
CODEDOC = $(NAMEC).pdf
UTFDOC  = $(NAMEU).pdf
INS     = $(NAME).ins
DTX     = $(NAME).dtx
UTFDTX  = $(NAMEU).dtx
ALLDTX  = $(DTX) $(UTFDTX)
README  = README.md

# Files grouped by generation mode
COMPILED = $(DOC) $(CODEDOC)
UNPACKED = microtype.sty letterspace.sty microtype.lua microtype.cfg \
	   microtype-pdftex.def microtype-luatex.def microtype-xetex.def \
	   mt-bch.cfg mt-blg.cfg mt-cmr.cfg mt-euf.cfg mt-eur.cfg mt-eus.cfg \
	   mt-msa.cfg mt-msb.cfg mt-EBGaramond.cfg mt-ppl.cfg mt-pmn.cfg mt-ptm.cfg \
	   mt-ugm.cfg mt-mvs.cfg mt-zpeu.cfg \
	   mt-CharisSIL.cfg mt-LatinModernRoman.cfg mt-NewComputerModern.cfg mt-Palatino.cfg \
	   mt-TU-basic.cfg mt-TU-empty.cfg \
	   microtype-show.sty test-microtype.tex
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

DO_PDFLATEX_DOC  = pdflatex --interaction=nonstopmode $(DTX) $(REDIRECT)
DO_PDFLATEX_CODE = pdflatex --jobname=$(NAMEC) --interaction=nonstopmode $(DTX) $(REDIRECT) || \
   if ! grep -i '* Checksum passed *' $(NAMEC).log > /dev/null ; then \
      if grep 'has no checksum\|Checksum not passed' $(NAMEC).log ; then \
         false ; \
      fi ; \
   fi
DO_LUALATEX      = lualatex --interaction=nonstopmode $(UTFDTX) $(REDIRECT)
DO_MAKEINDEX_DOC  = \
   makeindex -s microtype-gind.ist -t $(NAME).ilg -o $(NAME).ind $(NAME).idx $(REDIRECT) 2>&1 && \
   echo "Creating user index"
DO_MAKEINDEX_CODE = \
   makeindex -r -s microtype-gind.ist -t $(NAMEC).ilg -o $(NAMEC).ind \
             $(NAME).idx $(NAMEC).idx $(NAMEU).idx $(NAME).cdx $(REDIRECT) 2>&1 && \
   makeindex -s gglo.ist -t $(NAMEC).glg -o $(NAMEC).gls \
             $(NAME).glo $(NAMEC).glo $(NAMEU).glo $(REDIRECT) 2>&1 && \
   echo "Creating code index"

all:     $(GENERATED)
doc:     make-doc-sty $(COMPILED) make-normal-sty
userdoc: make-doc-sty $(DOC)      make-normal-sty
unpack:  docstrip.cfg $(UNPACKED)
ctan:    $(CTAN_ZIP)
tds:     $(TDS_ZIP)
world:   all ctan

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

RERUN_STR = 'Rerun to get \|pdfTeX warning (dest)'

define rerun-check
@while `grep $(RERUN_STR) $(NAMEU).log > /dev/null` ; do \
   echo "Re-compiling Unicode documentation" ; \
   $(DO_LUALATEX) ; \
done
@while `grep $(RERUN_STR) $(NAMEC).log > /dev/null` ; do \
   shasum $(NAME).glo $(NAMEC).glo $(NAMEU).glo $(NAME).idx $(NAMEC).idx $(NAMEU).idx $(NAME).cdx > $(NAMEC)-stamp2 ; \
   if cmp -s $(NAMEC)-stamp2 $(NAMEC)-stamp; then rm $(NAMEC)-stamp2; \
   else mv -f $(NAMEC)-stamp2 $(NAMEC)-stamp; $(DO_MAKEINDEX_CODE); fi ; \
   echo "Re-compiling code documentation" ; \
   $(DO_PDFLATEX_CODE) ; \
   shasum $(NAME).idx > $(NAME)-stamp2 ; \
   if cmp -s $(NAME)-stamp2 $(NAME)-stamp; then rm $(NAME)-stamp2; \
   else mv -f $(NAME)-stamp2 $(NAME)-stamp; $(DO_MAKEINDEX_DOC); fi ; \
   echo "Re-compiling user documentation" ; \
   $(DO_PDFLATEX_DOC) ; \
done
@while `grep $(RERUN_STR) $(NAME).log > /dev/null` ; do \
   shasum $(NAME).idx > $(NAME)-stamp2 ; \
   if cmp -s $(NAME)-stamp2 $(NAME)-stamp; then rm $(NAME)-stamp2; \
   else mv -f $(NAME)-stamp2 $(NAME)-stamp; $(DO_MAKEINDEX_DOC); fi ; \
   echo "Re-compiling user documentation" ; \
   $(DO_PDFLATEX_DOC) ; \
done
endef

$(DOC): $(DTX) $(NAME).ind
	@if `grep $(RERUN_STR) $(NAME).log > /dev/null` ; then \
		echo "Re-compiling user documentation" ; \
		$(DO_PDFLATEX_DOC) ; \
	fi

$(CODEDOC): $(DTX) $(UTFDOC) $(NAMEC).gls $(NAMEC).ind
	@echo "Compiling code documentation (including Unicode part)"
	@$(DO_PDFLATEX_CODE)
	$(rerun-check)

$(UTFDOC): $(UTFDTX) $(NAMEC).tmp
	@echo "Compiling Unicode documentation"
	@$(DO_LUALATEX)
	@if `grep $(RERUN_STR) $(NAMEU).log > /dev/null` ; then \
		echo "Re-compiling Unicode documentation" ; \
		$(DO_LUALATEX) ; \
	fi

$(NAME).idx: $(DTX)
	@echo "Compiling user documentation (idx)"
	@$(DO_PDFLATEX_DOC)

$(NAME).ind: $(NAME)-stamp
	@echo "Compiling user documentation (ind)"
	@$(DO_MAKEINDEX_DOC)

$(NAME)-stamp: $(NAME).idx
	@shasum $^ > $@2
	@if cmp -s $@2 $@; then rm $@2; else mv -f $@2 $@; fi

$(NAMEC).idx $(NAMEC).glo: $(DTX)
	@echo "Compiling code documentation (idx,glo)"
	@$(DO_PDFLATEX_CODE)

$(NAMEC).ind $(NAMEC).gls: $(NAMEC)-stamp
	@echo "Compiling code documentation (ind,gls)"
	@$(DO_MAKEINDEX_CODE)

$(NAMEC)-stamp: $(NAME).glo $(NAMEC).glo $(NAMEU).glo $(NAME).idx $(NAMEC).idx $(NAMEU).idx $(NAME).cdx
	@shasum $^ > $@2
	@if cmp -s $@2 $@; then rm $@2; else mv -f $@2 $@; fi

# microtype-code.tmp is used to communicate counters
# from microtype.dtx (code) to microtype-utf.dtx
$(NAMEC).tmp:
	@echo "Compiling code documentation (for Unicode part)"
	@$(DO_PDFLATEX_CODE)
	@if `grep $(RERUN_STR) $(NAMEC).log > /dev/null` ; then \
		echo "Re-compiling code documentation (for Unicode part)" ; \
		$(DO_MAKEINDEX_CODE) ; \
		$(DO_PDFLATEX_CODE) ; \
	fi

$(UNPACKED): $(INS) $(DTX) $(UTFDTX) docstrip.cfg
	@echo "Extracting package"
	@pdflatex $^ $(REDIRECT)
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
	@LANG=C && sed -n '/%<\*package|letterspace|m-t|pdf-|lua-|xe-|show>$$/{N;s/.*\[\(.*\)$$/-- \1 ($(DTX))/p;}' $(DTX)
	@LANG=C && sed -n '/ *version *= *.*$$/{N;s/^.*= *"\(.*\)",.*date *= *"\(.*\)",/  (\2 v\1 (microtype.lua))/p;}' $(DTX)
	@sed -n '/%<\*driver>$$/{N;/{\\jobname\.dtx}/ s/^.*\[\(.*\)\]$$/-- \1 ($(UTFDTX))/p;}' $(UTFDTX)
	@sed -n 's/^ *(\(v[^ ]*\) *-- *\([^ ]*\))$$/-- \2 \1 ($(README))/p' $(README)
	@echo ""
	@echo "=== Derived files ==="
	@for f in $(UNPACKED); do echo "$$f"; done
	@echo "----------------------------"
	@if grep '\-\-'`date -v-1y +%Y` $(SOURCE); then echo "!!!! Copyright strings not up to date !!!!" ; fi

mostlyclean:
	@$(RM) -- *.log *.aux *.toc *.idx *.cdx *.ind *.ilg *.glo *.gls *.glg *.lot *.out *.synctex* *.tmp *.pl *.mtx \
		docstrip.cfg $(UTFDOC) microtype-doc.sty microtype-gind.ist make-*-sty *-stamp

clean: mostlyclean
	@$(RM) -- $(GENERATED) $(ZIPS)

# testing the package

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

