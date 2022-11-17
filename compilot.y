//2-3pm wch116

%{
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

int yylex();
void yyerror(const char *s);
char* mycont(char* a, char* b);

struct Bucket {
	char name[16];
	char type[16];
	char value[125];
	struct Bucket* next;
};

struct CodeNode{
	char code[1024];
	char name[16];
	char type[16];
};

int hash(char* a){
	int i;
	int sum = 0;
	for(i = 0; i < strlen(a); i++){
		sum += a[i];
	}
	return sum % 50;
}

void delSymbole(char* a, struct Bucket* table[]){
	int i = hash(a);
	struct Bucket* temp = table[i];
	struct Bucket* prev = NULL;
	while(temp != NULL){
		if(strcmp(temp->name, a) == 0){
			if(prev == NULL){
				table[i] = temp->next;
			}
			else{
				prev->next = temp->next;
			}
			free(temp);
			return;
		}
		prev = temp;
		temp = temp->next;
	}
}

void addSymbol(char* name, char* type, char* value, struct Bucket* table[]){
	int i = hash(name);
	struct Bucket* temp = table[i];
	while(temp != NULL){
		if(strcmp(temp->name, name) == 0){
			strcpy(temp->type, type);
			strcpy(temp->value, value);
			return;
		}
		temp = temp->next;
	}
	struct Bucket* new = (struct Bucket*)malloc(sizeof(struct Bucket));
	strcpy(new->name, name);
	strcpy(new->type, type);
	strcpy(new->value, value);
	new->next = table[i];
	table[i] = new;
}

struct Bucket* findSymbol(char* name, struct Bucket* table[]){
	int i = hash(name);
	struct Bucket* temp = table[i];
	while(temp != NULL){
		if(strcmp(temp->name, name) == 0){
			return temp;
		}
		temp = temp->next;
	}
	return NULL;
}

struct Bucket* symbolTable[50];

FILE* fp;

%}

%union {
    char *str;
}
/* declare tokens */
%token NUMBER
%token PLUS MINUS MULT DIV
%token ASSIGN
%token STRING
%token EOL
%token END
%type<str> NUMBER STRING
%token STRING_LITERAL
%token INTEGER
%token BOOLEAN
%token COMMA
%token WHILE
%token IF
%token ELSE
%token ELSE_IF
%token BREAK
%token RETURN
%token DIGIT
%token L_PAREN 
%token R_PAREN
%token L_BRACE
%token R_BRACE
%token L_BRACK
%token R_BRACK
%token ID
%token EQUAL NE SE BE SMALLER BIGGER
%token FUNCTION
%token TRUE
%token FALSE
%token COMMENT

%%
program: stmt
| program EOL stmt
;

stmt: 
 | BREAK {printf(" break\n");}
 | declaration_stmt {printf(" declaration_stmt\n");}
 | ID L_PAREN parameter R_PAREN {printf(" function_call\n");}
 | if_stmt {printf(" if_stmt\n");}
 | while_stmt {printf(" while_stmt\n");}
 | RETURN expression {printf(" return\n");}
 | assignment_stmt {printf(" assignment_stmt\n");}
 | datatype FUNCTION ID L_PAREN arguments R_PAREN L_BRACE EOL program EOL R_BRACE EOL {printf(" function\n");}
 | COMMENT {printf(" comment\n");}
 ;

assignment_stmt: ID ASSIGN assignment;

assignment: expression
| array
;

declaration_stmt: datatype declaration
| datatype L_BRACK R_BRACK declaration;

declaration: ID
| ID ASSIGN expression
| ID ASSIGN array
;

datatype: INTEGER{
}
| BOOLEAN
| STRING
;

expression: math_expr
| STRING_LITERAL
| ID L_PAREN parameter R_PAREN //funct_call
| TRUE
| FALSE
| ID L_BRACK math_expr R_BRACK //array access
;

math_expr: term addop math_expr
| term 
; 

bool_expr: math_expr boolop math_expr
| TRUE
| FALSE
| ID
| ID L_PAREN parameter R_PAREN //funct_call
;

boolop: EQUAL 
| NE
| SE
| BE
| SMALLER
| BIGGER
;

addop : PLUS
| MINUS
;

term: term mulop factor
| factor
;

mulop: MULT
| DIV
;

factor: L_PAREN math_expr R_PAREN
| NUMBER
| ID
;

array: L_BRACE data data_ R_BRACE;

data : NUMBER
| STRING_LITERAL
;


data_: 
| COMMA data data_
;

if_stmt : IF L_PAREN bool_expr R_PAREN L_BRACE EOL program EOL R_BRACE else_if_stmt else_stmt;

else_stmt :
| ELSE L_BRACE EOL program EOL R_BRACE

else_if_stmt: 
| ELSE_IF L_PAREN bool_expr R_PAREN L_BRACE EOL program EOL R_BRACE else_if_stmt
;

while_stmt : WHILE L_PAREN bool_expr R_PAREN L_BRACE EOL program EOL R_BRACE
;


arguments: datatype ID arguments_
;

arguments_ :  
| COMMA datatype ID arguments_
;

parameter : 
| NUMBER parameter_ 
| STRING_LITERAL parameter_ | ID parameter_ | array parameter_
;

parameter_ : 
| COMMA NUMBER parameter_ 
| COMMA STRING_LITERAL parameter_ 
| COMMA ID parameter_ 
| COMMA array parameter_
;

%%

void yyerror(const char *s) {
	fprintf(stderr, "%s\n", s);
	printf("error");
};

char* mycont(char* a, char* b){

	strcat(a,b);
	return a;
}

int main(int argc, char **argv)
{
	int i = 0;
	for(i = 0; i < 50; i++){
		symbolTable[i] = NULL;
	} //initialize symbol table
	fp = fopen("output.txt", "w");
	yyparse();
	fclose(fp);
	return 0;

}
