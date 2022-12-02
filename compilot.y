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
	//char value[125];
	char temVar[8];
	struct Bucket* next;
};

void changeLabel(char *text, char *newLabel) {
    char buffer[1025];
    char *p = text;

    while ((p = strstr(p, "TEMPLABEL"))) {
        strncpy(buffer, text, p-text);
        buffer[p-text] = '\0'; //reterminate string
        strcat(buffer, "NEWLABEL");
        strcat(buffer, p+sizeof("TEMPLABEL")-1);
        strcpy(text, buffer);
        p++;
    }
}

/****
itg a = 10
itg b = 20
itg c = b + a
itg d
d = 50
****/

/****
= t1, 10
= t2, 20
+ t3, t1, t2
****/


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

/*****
FIXME: 
We want to create a newTemp for each variable, because if we don't
we could have a variable called "t1" that is created by newTemp(), and we can have another
variable called "t1" that is created by user.
We also need to store is the scope of the symbol.
I'll think about how to implement this later.
NOTE: Maybe we shouldn't even let the users declare variables
w/o assignment at all! This only further complicates the code
*****/

void addSymbol(char* name, char* type, char* tempVar, struct Bucket* table[]){
	int i = hash(name);
	struct Bucket* temp = table[i];
	while(temp != NULL){ //check if the symbol is already in the table
		if(strcmp(temp->name, name) == 0){
			yyerror("Repeated variable declaration");
			return;
		}
		temp = temp->next;
	}
	//if not, add it to the table
	struct Bucket* new = (struct Bucket*)malloc(sizeof(struct Bucket));
	strcpy(new->name, name);
	strcpy(new->type, type);
	if(tempVar != NULL){
		strcpy(new->temVar, tempVar);
	}else{
		yyerror("Declaration without assignment is not allowed");
	}
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

char* newLabel(){
	static int j = 0;
	char* temp = (char*)malloc(8);
	sprintf(temp, "L%d", j);
	i++;
	return temp;
}

void changeLabel(char* label, char* newLabel){
	
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
%token EOL
%token END
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

%type <node> datatype bool_expr math_expr boolop term addop mulop factor
%type <str> TRUE FALSE ID

%%
program: stmt{
	$$ = (struct CodeNode*)malloc(sizeof(struct CodeNode));
	strcpy($$->code, $1->code);
}
| program EOL stmt{
	$$ = (struct CodeNode*)malloc(sizeof(struct CodeNode));
	strcpy($$->code, $1->code);
	if($3 != NULL){
		strcat($$->code, "\n");
		strcat($$->code, $3->code);
	}
}
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

assignment_stmt: ID ASSIGN assignment{
	$$ = (struct CodeNode*)malloc(sizeof(struct CodeNode));
	Bucket* var = findSymbol($1, symbolTable);
	if(var == NULL){
		yyerror("Variable not declared");
	}
	if(strcmp(var->type, $3->type) != 0){
		yyerror("Type mismatch");
	}
	strcpy($$->code, $3->code);
	strcat($$->code, "\n= ");
	strcat($$->code, var->temVar);
	strcat($$->code, ", ");
	strcat($$->code, $3->name);
}
| ID L_BRACK expression R_BRACK ASSIGN assignment{
	$$ = (struct CodeNode*)malloc(sizeof(struct CodeNode));
	Bucket* var = findSymbol($1, symbolTable);
	if(var == NULL){
		yyerror("Variable not declared");
	}
	if(strcmp("int", $6->type) != 0){
		yyerror("Type mismatch, array can only store int");
	}
	if(strcmp("int", $3->type) != 0){
		yyerror("Type mismatch, array index must be int");
	}
	strcpy($$->code, $3->code);
	strcat($$->code, "\n");
	strcat($$->code, $6->code);
	//[]= dst, index, src
	strcat($$->code, "\n[]= ");
	strcat($$->code, var->temVar);
	strcat($$->code, ", ");
	strcat($$->code, $3->name);
	strcat($$->code, ", ");
	strcat($$->code, $6->name);
}

assignment: expression{
	$$ = (struct CodeNode*)malloc(sizeof(struct CodeNode));
	strcpy($$->code, $1->code);
	strcpy($$->name, $1->name);
	strcpy($$->type, $1->type);
}
| array{
	$$ = (struct CodeNode*)malloc(sizeof(struct CodeNode));
	strcpy($$->code, $1->code);
	strcpy($$->name, $1->name);
	strcpy($$->type, $1->type);
}
;

declaration_stmt: datatype ID declaration{
	$$ = (struct CodeNode*)malloc(sizeof(struct CodeNode));
	strcpy($$->code, $3->code);
	if($3 != NULL){
		addSymbol($2, $1->type, newTemp(), symbolTable);
	}else{
		yyerror("Declaration without assignment is not allowed");
	}
}
| INTEGER ID L_BRACK R_BRACK declaration{
	if(findSymbol($2, symbolTable) != NULL){
		yyerror("redeclaration of variable");
	}
	$$ = (CodeNode*)malloc(sizeof(CodeNode));
	if($5 == NULL){ 
		yyerror("array size not specified"); //codes like: "itg a[]" is not allowed
	}else{
		//if the type field of declaration node is not empty, then it is a declaration with assignment
		//In that case, we need to generate a new temporary variable, therefore we use newTemp() as the third parameter
		//and we also need to generate code for the assignment
		strcpy($$->name, newTemp());
		addSymbol($2, "array", $$->name, symbolTable);
		char tempCode[1024];
		int count = 0;
		char* token = strtok($5->code, " ");
		//generate the code that assigns the value to the array
		while(token != NULL){
			sprintf(tempCode + strlen(tempCode), "[]= %s, %d, %s\n", $4, count, token);
			count++;
		}
		tempCode[strlen(tempCode) - 1] = '\0';
		memset($5->code, 0, sizeof($5->code));
		sprintf($5->code, ".[] %s, %d", $4, count); //declare the array
		if(strlen($5->code) + strlen(tempCode) < 1023){ 
			//check if the code generated is too long
			strcat($5->code, tempCode);
		}else{
			yyerror("Code too long! Buffer overflow!");
		}
	}
}
| INTEGER ID L_BRACK expression R_BRACK declaration{
	if(findSymbol($2, symbolTable) != NULL){
		yyerror("redeclaration of variable");
	}
	if(strcmp($4->type, "int") != 0){
		yyerror("array size must be an integer");
	}
	$$ = (CodeNode*)malloc(sizeof(CodeNode));
	strcpy($$->code, $4->code);
	strcat($$->code, "\n");
	if($6 == NULL){ 
		//In this case, things like "itg a[3]" is allowed, since we know the size of the array
		strcpy($$->name, newTemp());
		addSymbol($2, "array", $$->name, symbolTable);
		sprintf($$->code, ".[] %s, %s", $$->name, $4->name);
	}else{
		//if the type field of declaration node is not empty, then it is a declaration with assignment
		//In that case, we need to generate a new temporary variable, therefore we use newTemp() as the third parameter
		//and we also need to generate code for the assignment
		strcpy($$->name, newTemp());
		addSymbol($2, tempType, $$->name, symbolTable);
		char tempCode[1024];
		int count = 0;
		char* token = strtok($5->code, " ");
		while(token != NULL){
			sprintf(tempCode + strlen(tempCode), "[]= %s, %d, %s\n", $4, count, token);
			count++;
		}
		tempCode[strlen(tempCode) - 1] = '\0';
		memset($5->code, 0, sizeof($5->code));
		sprintf($5->code, ".[] %s, %d", $4, count); //declare the array
		if(strlen($5->code) + strlen(tempCode) < 1023){ 
			//check if the code generated is too long
			strcat($5->code, tempCode);
		}else{
			yyerror("Code too long! Buffer overflow!");
		}
	}
};

declaration: {
	$$ = NULL
}
| ASSIGN expression{
	$$ = (*CodeNode)malloc(sizeof(struct CodeNode));
	strcpy($$->code, $2->code);
	strcpy($$->name, $2->name);
	strcpy($$->type, $2->type);
}
;

datatype: INTEGER{
	$$ = (*CodeNode)malloc(sizeof(struct CodeNode));
	strcpy($$->type, "int");
}
| BOOLEAN{
	$$ = (*CodeNode)malloc(sizeof(struct CodeNode));
	strcpy($$->type, "bool");
}
;

expression: math_expr{
	$$ = (struct CodeNode*)malloc(sizeof(struct CodeNode));
	strcpy($$->code, $1->code);
	strcpy($$->name, $1->name);
	strcpy($$->type, $1->type);
}
| ID L_PAREN parameter R_PAREN {
	struct Bucket* funct = findSymbol($1, symbolTable);
	if(funct == NULL){
		yyerror("Undeclared function");
	}
	if(strcmp(funct->type, "function") != 0){
		yyerror("Not a function");
	}
	/*******
	FIXME: This is where I'm currently working on
	I need to generate code for the function call
	we need to check if the number of parameters is correct
	and we need to check if the type of the parameters is correct
	also the return type of the function
	and we need to generate code for the function call
	This bit is a little tricky
	I have been thinking, maybe function table will solve our problem
	But in that case, it means that we will be able to have functions and variables with the same name.
	NOTE: According to the professor, we do not need to check the validity of the function call
	So a function table is optional
	*******/
	$$ = (struct CodeNode*)malloc(sizeof(struct CodeNode));
	strcpy($$->name, newTemp());
	char* token = strtok($3->code, " ");
} //function call
| TRUE{
	$$ = (struct CodeNode*)malloc(sizeof(struct CodeNode));
	strcpy($$->name, "1");
	strcpy($$->type, "bool");
}
| FALSE{
	$$ = (struct CodeNode*)malloc(sizeof(struct CodeNode));
	strcpy($$->name, "0");
	strcpy($$->type, "bool");
}
| ID L_BRACK expression R_BRACK{
	struct Bucket* array = findSymbol($1, symbolTable);
	if(array == NULL){
		yyerror("Undeclared array");
	}
	if(strcmp(array->type, "array") != 0){
		yyerror("Not an array");
	}
	if(strcmp($3->type, "int") != 0){
		yyerror("Array index must be an integer");
	}
	$$ = (struct CodeNode*)malloc(sizeof(struct CodeNode));
	strcpy($$->name, newTemp());
	sprintf($$->code, "=[] %s, %s, %s", $$->name, $1 , $3->name);
	strcpy($$->type, array->type);
} //array access
| array {
	$$ = (struct CodeNode*)malloc(sizeof(struct CodeNode));
	strcpy($$->name, $1->name);
	strcpy($$->code, $1->code);
	strcpy($$->type, $1->type);
}
;

math_expr: term addop math_expr
| term 
; 

bool_expr: math_expr boolop math_expr{
	$$ = (*CodeNode)malloc(sizeof(struct CodeNode));
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
	$$ = (*CodeNode)malloc(sizeof(struct CodeNode));
	strcpy($$->type, "bool");
	strcpy($$->name, "1");
}
| FALSE{
	$$ = (*CodeNode)malloc(sizeof(struct CodeNode));
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
	$$ = (*CodeNode)malloc(sizeof(struct CodeNode));
	strcpy($$->type, var->type);
	strcpy($$->name, var->value);
}
| ID L_PAREN parameter R_PAREN {
	struct Bucket* funct = findSymbol($1, symbolTable);
	if(funct == NULL){
		yyerror("Undeclared function");
	}
	if(strcmp(funct->type, "function") != 0){
		yyerror("Type mismatch");
	}
	$$ = (*CodeNode)malloc(sizeof(struct CodeNode));
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
	$$ = (*CodeNode)malloc(sizeof(struct CodeNode));
	strcpy($$->name, "==");
}
| NE{
	$$ = (*CodeNode)malloc(sizeof(struct CodeNode));
	strcpy($$->name, "!=");
}
| SE{
	$$ = (*CodeNode)malloc(sizeof(struct CodeNode));
	strcpy($$->name, "<=");
}
| BE{
	$$ = (*CodeNode)malloc(sizeof(struct CodeNode));
	strcpy($$->name, ">=");
}
| SMALLER{
	$$ = (*CodeNode)malloc(sizeof(struct CodeNode));
	strcpy($$->name, "<");
}
| BIGGER{
	$$ = (*CodeNode)malloc(sizeof(struct CodeNode));
	strcpy($$->name, ">");
}
;


//We store the additon/subtraction operator in the name field of the CodeNode
addop : PLUS{
	$$ = (*CodeNode)malloc(sizeof(struct CodeNode));
	strcpy($$->name, "+");
}
| MINUS{
	$$ = (*CodeNode)malloc(sizeof(struct CodeNode));
	strcpy($$->name, "-");
}
;

term: term mulop factor{
	if(strcmp($1->type, $3->type) != 0){
		yyerror("Type mismatch");
	}
	$$ = (*CodeNode)malloc(sizeof(struct CodeNode));
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
	$$ = (*CodeNode)malloc(sizeof(struct CodeNode));
	strcpy($$->type, $1->type);
	strcpy($$->name, $1->name);
	strcpy($$->code, $1->code);
}
;

mulop: MULT{
	$$ = (*CodeNode)malloc(sizeof(struct CodeNode));
	strcpy($$->name, "*");
}
| DIV{
	$$ = (*CodeNode)malloc(sizeof(struct CodeNode));
	strcpy($$->name, "/");
}
;

factor: L_PAREN math_expr R_PAREN{
	$$ = (*CodeNode)malloc(sizeof(struct CodeNode));
	strcpy($$->type, $2->type);
	strcpy($$->name, $2->name);
	strcpy($$->code, $2->code);
}
| NUMBER{
	$$ = (*CodeNode)malloc(sizeof(struct CodeNode));
	strcpy($$->type, "int");
	strcpy($$->name, $1);
}
| ID{
	struct Bucket* var = findSymbol($1, symbolTable);
	if(var == NULL){
		yyerror("Undeclared variable");
	}
	$$ = (*CodeNode)malloc(sizeof(struct CodeNode));
	strcpy($$->type, var->type);
	strcpy($$->name, var->value);
}
;

array: L_BRACE data data_ R_BRACE{ //All the data is stored in the code field of the CodeNode, separated by a space
	if(strcmp($2->type, "int") == 0){ //only int arrays are allowed
		yyerror("Type mismatch. Arrays must be of type int");
	}
	$$ = (*CodeNode)malloc(sizeof(struct CodeNode));
	strcpy($$->type, "array");
	strcpy($$->code, $2->code);
	if($3 != NULL){
		strcat($$->code, " ");
		strcat($$->code, $3->code);
	}
};

data : NUMBER{
	$$ = (*CodeNode)malloc(sizeof(struct CodeNode));
	strcpy($$->type, "int");
	strcpy($$->code, $1);
}
| ID{
	struct Bucket* var = findSymbol($1, symbolTable);
	if(var == NULL){
		yyerror("Undeclared variable");
	}
	if(strcmp(var->type, "int") != 0){
		yyerror("Type mismatch. Arrays must be of type int");
	}
	$$ = (*CodeNode)malloc(sizeof(struct CodeNode));
	strcpy($$->type, var->type);
	if(strcmp(var->value, "") == 0){
		yyerror("Array element not initialized");
	}
	strcpy($$->code, var->tempVar);
}
;


data_: {
	$$ = NULL;
}
| COMMA data data_{
	if(strcmp($2->type, "int") == 0){ //only int arrays are allowed
		yyerror("Type mismatch. Arrays must be of type int");
	}
	$$ = (*CodeNode)malloc(sizeof(struct CodeNode));
	strcpy($$->type, $2->type);
	strcpy($$->code, $2->code);
	if($3 != NULL){
		strcat($$->code, " ");
		strcat($$->code, $3->code);
	}
}
;

if_stmt : IF L_PAREN bool_expr R_PAREN L_BRACE EOL program EOL R_BRACE else_if_stmt else_stmt{
	/****
	FIXME: This part is not done yet. We need to add the code for the else if and else statements
	Which is essentially adding labels for stuff
	****/
	char* tempLabel1 = newLabel();
	char* tempLabel2 = newLabel();
	$$ = (*CodeNode)malloc(sizeof(struct CodeNode))
	strcpy($$->code, $3->code);
	strcat($$->code, "\n");
	strcat($$->code, "! ");
	strcat($$->code, $3->name);
	strcat($$->code, ", ");
	strcat($$->code, $3->name);
	strcat($$->code, "\n");
	//We want to jump to the else if statement if the bool_expr is false
	//so we need to invert the result of bool_expr
	strcat($$->code, "?:=");
	strcat($$->code, tempLabel1);
	strcat($$->code, ", ");
	strcat($$->code, $3->name);
	strcat($$->code, "\n");
	strcat($$->code, $7->code);//finish running program
	strcat($$->code, "\n");
	strcat($$->code, ":=");
	strcat($$->code, tempLabel2);
	strcat($$->code, "\n");//go to the end of the if statement
	strcat($$->code, ":");
	strcat($$->code, tempLabel1);//generate a new label to go to if the bool_expr is false
	tempLabel = newLabel();
	if($10 != NULL){
		strcat($$->code, "\n");
		changeLabel($10->code, tempLabel2); //change TEMPLABEL to go to the end of if statement
		strcat($$->code, $9->code);
	}
	if($11 != NULL){
		strcat($$->code, "\n");
		//since this is else statement
		//it automatically goes to the end of the if statement
		//once it is done executing
		//therefore, no need to change the label
		strcat($$->code, $10->code);
	}
	strcat($$->code, "\n:");
	strcat($$->code, tempLabel2);//set the end of the if statement
};

else_stmt :{
	$$ = NULL;
}
| ELSE L_BRACE EOL program EOL R_BRACE{
	$$ = (*CodeNode)malloc(sizeof(struct CodeNode));
	strcat($$->code, $4->code);
}

else_if_stmt: {
	$$ = NULL;
}
| ELSE_IF L_PAREN bool_expr R_PAREN L_BRACE EOL program EOL R_BRACE else_if_stmt{
	$$ = (*CodeNode)malloc(sizeof(struct CodeNode));
	char* tempLabel1 = newLabel();
	strcat($$->code, $3->code);
	strcat($$->code, "\n");
	strcat($$->code, "! ");
	strcat($$->code, $3->name);
	strcat($$->code, ", ");
	strcat($$->code, $3->name);
	strcat($$->code, "\n");
	//We want to jump to the else if statement if the bool_expr is false, so we need to invert the result of bool_expr
	strcat($$->code, "?:=");
	strcat($$->code, tempLabel1);
	strcat($$->code, ", ");
	strcat($$->code, $3->name);
	strcat($$->code, "\n");
	strcat($$->code, $7->code);
	strcat($$->code, "\n");
	strcat($$->code, ":=TEMPLABEL\n:");
	strcat($$->code, tempLabel1);
	if($10 != NULL){
		strcat($$->code, "\n");
		strcat($$->code, $9->code);
	}
}
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
| ID parameter_ | array parameter_
;

parameter_ : 
| COMMA NUMBER parameter_ 
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
