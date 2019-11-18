
The `microtype` package
=======================

**Subliminal refinements towards typographical perfection**

  (v2.7d -- 2019/11/18)


Overview
--------

The `microtype` package provides a LaTeX interface to the micro-typographic
extensions that were introduced by pdfTeX and have since also propagated to
LuaTeX and XeTeX: most prominently, character protrusion and font expansion,
furthermore the adjustment of interword spacing and additional kerning, as
well as hyphenatable letterspacing (tracking) and the possibility to disable
all or selected ligatures.

These features may be applied to customisable sets of fonts, and all 
micro-typographic aspects of the fonts can be configured in a straight-forward
and flexible way. Settings for various fonts are provided.

*Note that character protrusion requires pdfTeX (version 0.14f or later),
LuaTeX, or XeTeX (at least version 0.9997). Font expansion works with pdfTeX
(version 1.20 for automatic expansion) or LuaTeX. The package will by default
enable protrusion and expansion if they can safely be assumed to work.
Disabling ligatures requires pdfTeX (at least version 1.30) or LuaTeX, while
the adjustment of interword spacing and of kerning only works with pdfTeX
(at least 1.40). Letterspacing is available with pdfTeX (1.40) or LuaTeX (0.62).*

The alternative package `letterspace`, which also works with plain TeX,
provides the user commands for letterspacing only, omitting support for all
other extensions.

The documentation can be found in `microtype.pdf`.


Installation
------------

To install the package, use one of the following methods
(in decreasing order of simplicity):

- Use the package manager of your TeX system 
  (TeXLive: `tlmgr install microtype`;
   MiKTeX: MiKTeX Package Manager).
 
- Download `microtype.tds.zip` from CTAN, 
  extract it in the root of one of your TDS trees, 
  and update the filename database.

- Get the source (`microtype.zip`) from CTAN and extract it,
  run `latex` on `microtype.ins` to generate the package and configuration files,
  and move all generated files into a directory where LaTeX will find them,
  e.g., `TEXMF/tex/latex/microtype/`.


License
-------

This work may be distributed and/or modified under the conditions of the
LaTeX Project Public License, either version 1.3c of this license or (at
your option) any later version. The latest version of this license is in:
http://www.latex-project.org/lppl.txt, and version 1.3c or later is part
of all distributions of LaTeX version 2005/12/01 or later.

This work has the LPPL maintenance status 'author-maintained'.

This work consists of the files `microtype.dtx` and `microtype.ins` and the
derived files `microtype.sty`, `microtype-pdftex.def`, `microtype-luatex.def`,
`microtype-xetex.def`, `microtype.lua` and `letterspace.sty`.

Modified versions of the configuration files (`*.cfg`) may be distributed
provided that: (1) the original copyright statement is not removed, and
(2) the identification string is changed.

------------------------------------------------------
Copyright (c) 2004--2019  R Schlicht `<w.m.l@gmx.net>`
------------------------------------------------------
