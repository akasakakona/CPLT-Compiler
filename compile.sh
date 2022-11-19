#!/bin/bash
if [[ $OSTYPE == *"linux-gnu"* ]]; then
    bison -v -d --file-prefix=y compilot.y
    flex compilot.lex
    gcc -o cplt y.tab.c lex.yy.c -lfl
elif [[ $OSTYPE == *"darwin"* ]]; then
    bison -v -d --file-prefix=y compilot.y
    flex compilot.lex
    gcc -o cplt y.tab.c lex.yy.c -ll
else
    echo "OS not supported"
fi
