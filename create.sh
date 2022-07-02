#!/bin/bash
mkdir -p dump
mkdir -p fun
mkdir -p tmp
cd dump/
yacc ../calc.y
yacc -d ../calc.y
lex ../calc.l
gcc lex.yy.c y.tab.c -lm -o ../calc
