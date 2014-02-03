#!/bin/bash

abort() {
 if [ $1 -eq 1 ]; then
   echo "Error, aborting."
   exit 1
 fi
}

cleanup() {
  rm *.aux > /dev/null 2>&1
  rm *.bbl > /dev/null 2>&1
  rm *.log > /dev/null 2>&1
  rm *.blg > /dev/null 2>&1
  rm *.toc > /dev/null 2>&1
  rm *.out > /dev/null 2>&1
  rm *.dvi > /dev/null 2>&1
  rm *.bcf > /dev/null 2>&1
  rm *.lof > /dev/null 2>&1
  rm *.lot > /dev/null 2>&1
  rm *.run.xml > /dev/null 2>&1
  rm *.thm > /dev/null 2>&1
  rm *.figlist > /dev/null 2>&1
  rm *.makefile > /dev/null 2>&1
  rm images/*.dep > /dev/null 2>&1
  rm images/*.dpth > /dev/null 2>&1
  rm images/*.log > /dev/null 2>&1
  # index, nomenclature:
  rm *.ilg > /dev/null 2>&1
  rm *.nlo > /dev/null 2>&1
  rm *.nls > /dev/null 2>&1
}


DOC="$1"
if [ -z "$DOC" ]
  then
    DOC="main.tex"
fi

if [ "$DOC" != "title.tex" ] && [ "$2" != "lazy" ]
  then
    echo "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"
    echo "% Building titlepage..."
    #
    pdflatex -draftmode -halt-on-error title.tex
    abort $?
    pdflatex -draftmode -halt-on-error title.tex
    abort $?
    pdflatex -halt-on-error title.tex
    abort $?
fi
#
if [ "$2" != "lazy" ]
  then
    echo "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"
    echo "% Deleting left-over auxiliary files..."
    #
    cleanup
    rm ${DOC%.tex}.bbl > /dev/null 2>&1
    #
    echo "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"
    echo "% Collecting data..."
    #
    pdflatex -draftmode -halt-on-error ${DOC%.tex}
    abort $?
    #
    if [ "$2" = "full" ] || [ ! -f ${DOC%.tex}.bbl ] || [ -n "$(hg status chh.bib)" ] || [ -n "$(hg status literatur.bib)" ]
      then
        #
        echo "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"
        echo "% Building bibliography..."
        #
        for file in *.bcf ; do
          biber ${file%.aux}
          abort $?
        done
    fi
fi
#
if [ -f ${DOC%.tex}.nlo ]
  then
    #
    echo "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"
    echo "% Building nomenclature..."
    #
    makeindex ${DOC%.tex}.nlo -s nomencl.ist -o ${DOC%.tex}.nls
fi
#
echo "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"
echo "% Identifying modified TikZ files..."
#
for file in tikz/*.tex ; do
  if [ "$2" = "full" ] || [ -n "$(hg status $file)" ] && [ -f "images/$(basename ${file%.tex}).pdf" ];
    then
      # Delete corresponding PDF image
      rm images/$(basename ${file%.tex}).pdf
      abort $?
  fi
done
#
echo "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"
echo "% Building TikZ graphics simultaneously on available CPU cores..."
#
MF="${DOC%.tex}.makefile"
if [ -f $MF ]
  then
    make -j $(grep -c ^processor /proc/cpuinfo) -f $MF
    abort $?
fi
#
if [ "$2" != "lazy" ]
  then
  echo "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"
  echo "% Putting the pieces together..."
  #
  pdflatex -draftmode -halt-on-error ${DOC%.tex}
  abort $?
fi
#
echo "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"
echo "% Final run, this time without the draft option..."
#
pdflatex -halt-on-error ${DOC%.tex}
abort $?
#
if [ "$2" != "lazy" ]
  then
    echo "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"
    echo "% Compiling done, now deleting auxiliary files..."
    #
    cleanup
fi
#
echo "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"
echo "% Finished."
#