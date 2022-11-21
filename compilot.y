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

char* newTemp(){
	static int i = 0;
	char* temp = (char*)malloc(8);
	sprintf(temp, "t%d", i);
	i++;
	return temp;
}

struct Bucket* symbolTable[50];

FILE* fp;

%}

%union {
    char* str;
	struct CodeNode* node;
}
/* declare tokens */
%token NUMBER
%token PLUS MINUS MULT DIV
%token ASSIGN
%token STRING
%token EOL
%token END
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

%type <node> datatype bool_expr math_expr boolop term addop mulop data expression assignment
%type <str> TRUE FALSE ID STRING_LITERAL

%%
program: stmt
| program EOL stmt
;

stmt: 
 | BREAK {printf("break");}
 | declaration_stmt {printf(" declaration_stmt\n");}
 | ID L_PAREN parameter R_PAREN {printf(" function_call\n");}
 | if_stmt {printf(" if_stmt\n");}
 | while_stmt {printf(" while_stmt\n");}
 | RETURN expression {printf(" return\n");}
 | RETURN
 | assignment_stmt {printf(" assignment_stmt\n");}
 | datatype FUNCTION ID L_PAREN arguments R_PAREN L_BRACE EOL program EOL R_BRACE EOL {printf(" function\n");}
 | COMMENT {printf(" comment\n");}
 ;

assignment_stmt: ID ASSIGN assignment;

assignment: expression {
	$$ = malloc(sizeof(struct CodeNode));
	strcpy($$->name, newTemp());
	$$->code = $1->code;
}
| array {
	$$ = malloc(sizeof(struct CodeNode));
	strcpy($$->name, newTemp());
	$$->code = $1->code;
}
;

declaration_stmt: datatype ID declaration
| datatype L_BRACK R_BRACK ID declaration;

declaration: 
| ASSIGN expression
| ASSIGN array
;

datatype: INTEGER{
	$$ = malloc(sizeof(struct CodeNode));
	strcpy($$->type, "int");
}
| BOOLEAN{
	$$ = malloc(sizeof(struct CodeNode));
	strcpy($$->type, "bool");
}
| STRING{
	$$ = malloc(sizeof(struct CodeNode));
	strcpy($$->type, "str");
}
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

bool_expr: math_expr boolop math_expr{
	$$ = malloc(sizeof(struct CodeNode));
	if(strcmp($1->type, $3->type) != 0){
		yyerror("type mismatch");
	}
	strcpy($$->name, newTemp());
	strcpy($$->code, $1->code); //get the code for the first math_expr
	strcat($$->code, "\n");
	strcat($$->code, $3->code); //get the code for the second math_expr
	strcat($$->code, "\n");
	strcat($$->code, $2->name); //get the comparison operator from boolop, we store the comparison operator in the name field of the CodeNode
	strcat($$->code, " ");
	strcat($$->code, $$->name); //get the variable name for the result
	strcat($$->code, ", ");
	strcat($$->code, $1->name); //get the variable name from the first math_expr
	strcat($$->code, ", ");
	strcat($$->code, $3->name); //get the variable name from the second math_expr
	strcat($$->code, "\n");
}
| TRUE{
	$$ = malloc(sizeof(struct CodeNode));
	strcpy($$->type, "bool");
	strcpy($$->name, "1");
}
| FALSE{
	$$ = malloc(sizeof(struct CodeNode));
	strcpy($$->type, "bool");
	strcpy($$->name, "0");
}
| ID{
	struct Bucket* var = findSymbol($1, symbolTable);
	if(var == NULL){
		yyerror("Undeclared variable");
	}
	if(strcmp(var->type, "bool") != 0){
		yyerror("Type mismatch");
	}
	$$ = malloc(sizeof(struct CodeNode));
	strcpy($$->type, var->type);
	strcpy($$->name, var->value);
}
| ID L_PAREN parameter R_PAREN {
	struct Bucket* funct = findSymbol($1, symbolTable);
	if(funct == NULL){
		yyerror("Undeclared function");
	}
	if(strcmp(funct->type, "bool") != 0){
		yyerror("Type mismatch");
	}
	$$ = malloc(sizeof(struct CodeNode));
	//here we are assuming that parameter will store a list of variable names containing the parameters in its code attribute
	//separated by spaces. Therefore, we need to separate the parameters
	strcpy($$->name, newTemp());
	char temp[1024];
	strcpy(temp, $3->code);
	char* token = strtok(temp, " ");
	while(token != NULL){
		strcpy($$->code, "param ");
		strcat($$->code, token);
		strcat($$->code, "\n");
		token = strtok(NULL, " ");
	}
	strcat($$->code, "call ");
	strcat($$->code, $1);
	strcat($$->code, ", ");
	strcat($$->code, $$->name);
	strcat($$->code, "\n");
}
;

boolop: EQUAL {
	$$ = malloc(sizeof(struct CodeNode));
	strcpy($$->name, "==");
}
| NE{
	$$ = malloc(sizeof(struct CodeNode));
	strcpy($$->name, "!=");
}
| SE{
	$$ = malloc(sizeof(struct CodeNode));
	strcpy($$->name, "<=");
}
| BE{
	$$ = malloc(sizeof(struct CodeNode));
	strcpy($$->name, ">=");
}
| SMALLER{
	$$ = malloc(sizeof(struct CodeNode));
	strcpy($$->name, "<");
}
| BIGGER{
	$$ = malloc(sizeof(struct CodeNode));
	strcpy($$->name, ">");
}
;


//note: we store the additon/subtraction operator in the name field of the CodeNode
addop : PLUS{
	$$ = malloc(sizeof(struct CodeNode));
	strcpy($$->name, "+");
}
| MINUS{
	$$ = malloc(sizeof(struct CodeNode));
	strcpy($$->name, "-");
}
;

term: term mulop factor{
	if(strcmp($1->type, $3->type) != 0){
		yyerror("Type mismatch");
	}
	$$ = malloc(sizeof(struct CodeNode));
	strcpy($$->type, $1->type);
	strcpy($$->name, newTemp());
	strcpy($$->code, $1->code);
	strcat($$->code, "\n");
	strcat($$->code, $3->code);
	strcat($$->code, "\n");
	strcat($$->code, $2->name); //get the multiplication/division operator from mulop, we store the operator in the name field of the CodeNode
	strcat($$->code, " ");
	strcat($$->code, $$->name); //get the variable name for the result
	strcat($$->code, ", ");
	strcat($$->code, $1->name); //get the variable name from the first term
	strcat($$->code, ", ");
	strcat($$->code, $3->name); //get the variable name from the second term
	strcat($$->code, "\n");
}
| factor{
	$$ = malloc(sizeof(struct CodeNode));
	strcpy($$->type, $1->type);
	strcpy($$->name, $1->name);
	strcpy($$->code, $1->code);
}
;

mulop: MULT{
	$$ = malloc(sizeof(struct CodeNode));
	strcpy($$->name, "*");
}
| DIV{
	$$ = malloc(sizeof(struct CodeNode));
	strcpy($$->name, "/");
}
;

factor: L_PAREN math_expr R_PAREN
| NUMBER
| ID
;

array: L_BRACE data data_ R_BRACE;

data : NUMBER {
	$$ = malloc(sizeof(struct CodeNode));
	strcpy($$->name, "digit");
}
| STRING_LITERAL {
	$$ = malloc(sizeof(struct CodeNode));
	strcpy($$->name, "str_lit");
}
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
