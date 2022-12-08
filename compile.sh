#!/bin/bash
if [[ $OSTYPE == *"linux-gnu"* ]]; then
    flex compilot.lex
    bison -v -d --file-prefix=y compilot.y
    g++ -std=c++11 -o cplt y.tab.c lex.yy.c -lfl
elif [[ $OSTYPE == *"darwin"* ]]; then
    flex compilot.lex
    bison -v -d --file-prefix=y compilot.y
    g++ -std=c++11 -o cplt y.tab.c lex.yy.c -ll
else
    echo "OS not supported"
fi
