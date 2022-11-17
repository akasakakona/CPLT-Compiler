#!/bin/bash

bison -v -d --file-prefix=y compilot.y
flex compilot.lex
gcc -o cplt y.tab.c lex.yy.c -lfl