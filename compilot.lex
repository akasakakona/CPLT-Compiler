%{
	#include<stdio.h>
	#include<stdlib.h>
    extern "C" int yylex();
	#include "y.tab.h"
    void yyerror(const char *s);
	int num = 0;
%}

%option noyywrap noinput nounput yylineno

COMMENT (@.*|@@(.|\n)*@@)
INTEGER itg
FUNCTION fnc
BOOLEAN bln
WHILE whl
IF if
ELSE els
ELSE_IF elf
BREAK brk
RETURN ret
OUT out
IN in
/*AND [&]
OR [|]
NOT [!]*/

L_PAREN \(
R_PAREN \)
L_BRACE \{
R_BRACE \}
L_BRACK \[
R_BRACK \]

EQUAL ==
NE !=
SE <=
BE >=
SMALLER <
BIGGER >
TRUE true
FALSE false
PLUS [+]
MULT [*]
DIV [/]
MINUS [-]
ASSIGN [=]
COMMA [,]

ID [a-zA-Z][a-zA-Z0-9]*
DIGIT [0-9]
NUMBER {DIGIT}*
EOL \n

%%

[ \t]+	{}
{COMMENT} {printf("Comment\n"); return COMMENT;}
{EOL}	{printf("EOL\n"); return EOL;}
{INTEGER} {printf("Integer\n"); return INTEGER;}
{FUNCTION} {printf("Function\n"); return FUNCTION;}
{BOOLEAN} {printf("Boolean\n"); return BOOLEAN;}
{WHILE} {printf("While\n"); return WHILE;}
{IF} {printf("If\n"); return IF;}
{ELSE} {printf("Else\n"); return ELSE;}
{ELSE_IF} {printf("Else If\n"); return ELSE_IF;}
{BREAK} {printf("Break\n"); return BREAK;}

{L_PAREN} {printf("Left Parent\n"); return L_PAREN;}
{R_PAREN} {printf("Right Parent\n"); return R_PAREN;}
{L_BRACE} {printf("Left Brace\n"); return L_BRACE;}
{R_BRACE} {printf("Right Brace\n"); return R_BRACE;}
{L_BRACK} {printf("Left Bracket\n"); return L_BRACK;}
{R_BRACK} {printf("Right Bracket\n"); return R_BRACK;}

{EQUAL} {printf("Equal\n"); return EQUAL;}
{NE} {printf("Not Equal\n"); return NE;}
{SE} {printf("Smaller or Equal\n"); return SE;}
{BE} {printf("Bigger or Equal\n"); return BE;}
{SMALLER} {printf("Smaller\n"); return SMALLER;}
{BIGGER} {printf("Bigger\n"); return BIGGER;}
{TRUE} {printf("true\n"); return TRUE;}
{FALSE} {printf("false\n"); return FALSE;}

{PLUS} {printf("Plus\n"); return PLUS;}
{MULT} {printf("Multiply\n"); return MULT;}
{DIV} {printf("Division\n"); return DIV;}
{MINUS} {printf("Minus\n"); return MINUS;}
{ASSIGN} {printf("Assign\n"); return ASSIGN;}
{COMMA} {printf("Comma\n"); return COMMA;}
{RETURN} {printf("Return\n"); return RETURN;}
{OUT} {printf("Out\n"); return OUT;}
{IN} {printf("In\n"); return IN;}
%{/*
{AND} {printf("And\n"); return AND;}
{OR} {printf("Or\n"); return OR;}
{NOT} {printf("Not\n"); return NOT;}
*/
%}

{ID} {yylval.string = strdup(yytext);printf("ID %s\n", yytext); return ID;}
{NUMBER}	{yylval.string = strdup(yytext);printf("NUMBER %d\n", atoi(yytext)); return NUMBER;}
{DIGIT}*{ID}	{printf("Error %s", yytext); return 1;}
.		{printf("Error %s", yytext); return 1;}

%%