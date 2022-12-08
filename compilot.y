//2-3pm wch116

%{
#include <iostream>
#include <string>
#include <vector>
#include <cstdlib>
#include <fstream>
#include <stdio.h>
using namespace std; 

int yylex();
void yyerror(const char *s);
char* mycont(char* a, char* b);

struct Bucket {
	string name;
	string type;
	Bucket* next;
};

void changeLabel(string& text, string newLabel) {
	string::size_type i = 0;
	while((i = text.find("TEMPLABEL", i)) != string::npos) {
		text.replace(i, 9, newLabel);
		i += newLabel.length();
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
	string code;
	string name;
	string type;
};

int hash(string a){
	int i;
	int sum = 0;
	for(i = 0; i < a.size(); i++){
		sum += a.at(i);
	}
	return sum % 50;
}

void delSymbole(string a, vector<Bucket*>& table){
	int i = hash(a);
	Bucket* temp = table[i];
	Bucket* prev = nullptr;
	while(temp != nullptr){
		if(temp->name == a){
			if(prev == nullptr){
				table[i] = temp->next;
			}
			else{
				prev->next = temp->next;
			}
			delete temp;
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
We chould do a chained symbol table
NOTE: Maybe we shouldn't even let the users declare variables
w/o assignment at all! This only further complicates the code
*****/

void addSymbol(string name, string type, vector<Bucket*>& table){
	int i = hash(name);
	Bucket* temp = table.at(i);
	while(temp != nullptr){ //check if the symbol is already in the table
		if(temp->name == name){
			yyerror("Repeated variable declaration");
			return;
		}
		temp = temp->next;
	}
	//if not, add it to the table
	Bucket* newBucket = new Bucket;
	newBucket->name = name;
	newBucket->type = type;
	newBucket->next = table.at(i);
	table.at(i) = newBucket;
}

Bucket* findSymbol(string name, const vector<Bucket*>& table){
	int i = hash(name);
	Bucket* temp = table.at(i);
	while(temp != nullptr){
		if(temp->name == name){
			return temp;
		}
		temp = temp->next;
	}
	return nullptr;
}

string newTemp(){
	static int i = 0;
	string temp = "t";
	temp += to_string(i);
	i++;
	return temp;
}
string newLabel(){
	static int j = 0;
	string temp = "L";
	temp += to_string(j);
	i++;
	return temp;
}

vector<vector<Bucket*>> symbolTable(1, vector<Bucket*>(50, nullptr));

currTableIndex = 0;
vector<Bucket*> currentTable = symbolTable.at(0);

ofstream fout("output.txt");
if(!fout.is_open()){
	printf("Error opening file\n");
	exit(1);
}

%}

%union {
    string str;
	CodeNode* node;
}
/* declare tokens */
%token <str> NUMBER
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
%token <str> ID
%token EQUAL NE SE BE SMALLER BIGGER
%token FUNCTION
%token TRUE
%token FALSE
%token COMMENT
%token OUT
%token IN
%token AND
%token OR
%token NOT

%type <node> function_defs function_def program stmt arguments
%type <node> function_body
%type <node> declaration_stmt parameter if_stmt while_stmt assignment_stmt
%type <node> expression loop_body declaration data_ else_stmt else_if_stmt
%type <node> parameter_ if_body data arguments_ array 
%type <node> datatype bool_expr math_expr boolop term addop mulop factor result

%%

result: function_defs EOL program{
	fout << $1->code << endl << "func main" << endl << $3->code << endl << "endfunc" << endl;
	printf("%s\nfunc main\n%s\nendfunc\n", $1->code, $3->code);
}

function_defs : {
	$$ = nullptr;
}
| function_def EOL function_defs{
	$$ = new CodeNode;
	if($1 != nullptr){
		$$->code = $1->code + "\n";
	}
	$$->code += $3->code;
}

function_def : FUNCTION ID L_PAREN {
	printf("function\n");
	if(findSymbol($2, currentTable) != nullptr){
		yyerror("ID already declared");
	}
	if($2 == "main"){
		yyerror("main function cannot be declared");
	}
	addSymbol($2, "function", currentTable);
	//creating and entering a new scope. Therefore creating a new symbol table
	currentTableIndex++;
	symbolTable.push_back(vector<Bucket*>(50, nullptr));
	currentTable = symbolTable.at(currentTableIndex);
	$<node>$ = new CodeNode;
	$<node>$code = "func " + $2 + "\n";
}arguments R_PAREN L_BRACE EOL function_body EOL R_BRACE EOL {
	printf("function\n"); 
	$$->code += $<node>4->code + $<node>8->code + "endfunc";
	//exiting the scope. Therefore deleting the symbol table
	symbolTable.pop_back();
	currentTableIndex--;
	currentTable = symbolTable.at(currentTableIndex);
}

program: stmt{
	$$ = new CodeNode;
	$$->code = $1->code;
}
| program EOL stmt{
	$$ = new CodeNode;
	$$->code = $1->code;
	if($3 != nullptr){
		$$->code += "\n" + $3->code;
	}
}
;

stmt: {
	$$ = nullptr;
}
 | declaration_stmt {
	printf(" declaration_stmt\n");
	$$ = $1;
	}
 | ID L_PAREN parameter R_PAREN {
	if(findSymbol($1, currentTable) == nullptr){
		yyerror("Function not declared");
	}
	if(strcmp(findSymbol($1, currentTable)->type, "function") != 0){
		yyerror("Not a function");
	}
	printf(" function_call\n");
	$$ = new CodeNode;
	$$->code = $3->code + "\n" + "call " + $1;
 }
 | if_stmt {
	printf(" if_stmt\n");
	$$ = $1;
	}
 | while_stmt {
	printf(" while_stmt\n");
	$$ = $1;
	}
 | assignment_stmt {
	printf(" assignment_stmt\n");
	$$ = $1;
	}
 | OUT L_PAREN ID R_PAREN {
	printf(" out\n");
 }
 | COMMENT {printf(" comment\n");}
 ;

 if_body: {
	yyerror("if body cannot be empty");
 }
 | declaration_stmt {
	printf(" declaration_stmt\n");
	$$ = $1;
    }
 | ID L_PAREN parameter R_PAREN {
	if(findSymbol($1, currentTable) == nullptr){
		yyerror("Function not declared");
	}
	if(strcmp(findSymbol($1, currentTable)->type, "function") != 0){
		yyerror("Not a function");
	}
	printf(" function_call\n");
	$$ = new CodeNode;
	$$->code = $3->code + "\n" + "call " + $1;
	}
 | if_stmt {
	printf(" if_stmt\n");
	$$ = $1;
	}
 | while_stmt {
	printf(" while_stmt\n");
	$$ = $1;
	}
 | assignment_stmt {
	printf(" assignment_stmt\n");
	$$ = $1;
	}
 | COMMENT {printf(" comment\n");}
 ;

 function_body:declaration_stmt
 | assignment_stmt
 | if_stmt
 | while_stmt
 | RETURN expression {
	printf(" return\n");
	$$ = new CodeNode;
	$$->code = $2->code + "\n" + "ret " + $2->code;
	}
 | RETURN{
	$$ = new CodeNode;
	$$->code = "ret";
	}
 | ID L_PAREN parameter R_PAREN {printf(" function_call\n");}
 | COMMENT{
	$$ = nullptr;
 }
 ;

 loop_body: declaration_stmt
 | assignment_stmt
 | if_stmt
 | while_stmt
 | COMMENT{
	$$ = nullptr;
 }
 | ID L_PAREN parameter R_PAREN {printf(" function_call\n");}
 | BREAK {
	printf("break");
	$$ = new CodeNode;
	$$->code = ":=TEMPLABEL";
	}
 ;


assignment_stmt: ID ASSIGN expression{
	$$ = new CodeNode;
	Bucket* var = findSymbol($1, currentTable);
	if(var == nullptr){
		yyerror("Variable not declared");
	}
	if(strcmp(var->type, $3->type) != 0){
		yyerror("Type mismatch");
	}
	// strcpy($$->code, $3->code);
	// strcat($$->code, "\n= ");
	// strcat($$->code, var->temVar);
	// strcat($$->code, ", ");
	// strcat($$->code, $3->name);
}
| ID L_BRACK expression R_BRACK ASSIGN expression{
	$$ = new CodeNode;
	Bucket* var = findSymbol($1, currentTable);
	if(var == nullptr){
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

declaration_stmt: datatype ID declaration{
	$$ = new CodeNode;
	strcpy($$->code, $3->code);
	if($3 != nullptr){
		addSymbol($2, $1->type, currentTable);
	}else{
		yyerror("Declaration without assignment is not allowed");
	}
}
| datatype ID L_BRACK R_BRACK declaration{
	if(findSymbol($2, currentTable) != nullptr){
		yyerror("redeclaration of variable");
	}
	$$ = (CodeNode*)malloc(sizeof(CodeNode));
	if($5 == nullptr){ 
		yyerror("array size not specified"); //codes like: "itg a[]" is not allowed
	}else{
		//if the type field of declaration node is not empty, then it is a declaration with assignment
		//In that case, we need to generate a new temporary variable, therefore we use newTemp() as the third parameter
		//and we also need to generate code for the assignment
		strcpy($$->name, $2);
		addSymbol($2, "array", currentTable);
		char tempCode[1024];
		int count = 0;
		char* token = strtok($5->code, " ");
		//generate the code that assigns the value to the array
		while(token != nullptr){
			sprintf(tempCode + strlen(tempCode), "[]= %s, %d, %s\n", $2, count, token);
			count++;
		}
		tempCode[strlen(tempCode) - 1] = '\0';
		memset($5->code, 0, sizeof($5->code));
		sprintf($5->code, ".[] %s, %d", $2, count); //declare the array
		if(strlen($5->code) + strlen(tempCode) < 1023){ 
			//check if the code generated is too long
			strcat($5->code, tempCode);
		}else{
			yyerror("Code too long! Buffer overflow!");
		}
	}
}
| datatype ID L_BRACK expression R_BRACK declaration{
	if(findSymbol($2, currentTable) != nullptr){
		yyerror("redeclaration of variable");
	}
	if(strcmp($4->type, "int") != 0){
		yyerror("array size must be an integer");
	}
	$$ = (CodeNode*)malloc(sizeof(CodeNode));
	strcpy($$->code, $4->code);
	strcat($$->code, "\n");
	if($6 == nullptr){ 
		//In this case, things like "itg a[3]" is allowed, since we know the size of the array
		strcpy($$->name, $2);
		addSymbol($2, "array", currentTable);
		sprintf($$->code, ".[] %s, %s", $$->name, $4->name);
	}else{
		//if the type field of declaration node is not empty, then it is a declaration with assignment
		//In that case, we need to generate a new temporary variable, therefore we use newTemp() as the third parameter
		//and we also need to generate code for the assignment
		strcpy($$->name, $2);
		addSymbol($2, tempType, currentTable);
		char tempCode[1024];
		int count = 0;
		char* token = strtok($6->code, " ");
		while(token != nullptr){
			sprintf(tempCode + strlen(tempCode), "[]= %s, %d, %s\n", $2, count, token);
			count++;
		}
		sprintf($$->code, ".[] %s, %d", $4, count); //declare the array
	}
};

declaration: {
	$$ = nullptr
}
| ASSIGN expression{
	$$ = $2;
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
	$$ = new CodeNode;
	strcpy($$->code, $1->code);
	strcpy($$->name, $1->name);
	strcpy($$->type, $1->type);
}
| ID L_PAREN parameter R_PAREN {
	struct Bucket* funct = findSymbol($1, currentTable);
	if(funct == nullptr){
		yyerror("Undeclared function");
	}
	if(strcmp(funct->type, "function") != 0){
		yyerror("Not a function");
	}
	/*******
	NOTE: According to the professor, we do not need to check the validity of the function call
	So a function table is optional
	*******/
	$$ = new CodeNode;
	strcpy($$->name, newTemp());
	strcpy($$->code, $3->code);
	strcat($$->code, "\n");
	strcat($$->code, "call ");
	strcat($$->code, $1);
	strcat($$->code, ", ");
	strcat($$->code, $$->name);
} //function call
| TRUE{
	$$ = new CodeNode;
	strcpy($$->name, "1");
	strcpy($$->type, "bool");
}
| FALSE{
	$$ = new CodeNode;
	strcpy($$->name, "0");
	strcpy($$->type, "bool");
}
| ID L_BRACK expression R_BRACK{
	struct Bucket* array = findSymbol($1, currentTable);
	if(array == nullptr){
		yyerror("Undeclared array");
	}
	if(strcmp(array->type, "array") != 0){
		yyerror("Not an array");
	}
	if(strcmp($3->type, "int") != 0){
		yyerror("Array index must be an integer");
	}
	$$ = new CodeNode;
	strcpy($$->name, newTemp());
	sprintf($$->code, "=[] %s, %s, %s", $$->name, $1 , $3->name);
	strcpy($$->type, array->type);
} //array access
| array {
	$$ = new CodeNode;
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
	struct Bucket* var = findSymbol($1, currentTable);
	if(var == nullptr){
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
	struct Bucket* funct = findSymbol($1, currentTable);
	if(funct == nullptr){
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
	while(token != nullptr){
		strcpy($$->code, "param ");
		strcat($$->code, token);
		strcat($$->code, "\n");
		token = strtok(nullptr, " ");
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
	$$ = new CodeNode;
	$$->name = "*";
}
| DIV{
	$$ = new CodeNode;
	$$->name = "/";
}
;

factor: L_PAREN math_expr R_PAREN{
	$$ = $2;
}
| NUMBER{
	$$ = new CodeNode;
	$$->type = "int";
	$$->name = $1;
}
| ID{
	struct Bucket* var = findSymbol($1, currentTable);
	if(var == nullptr){
		yyerror("Undeclared variable");
	}
	$$ = new CodeNode;
	strcpy($$->type, var->type);
	strcpy($$->name, var->value);
}
;

array: L_BRACE data data_ R_BRACE{ //All the data is stored in the code field of the CodeNode, separated by a space
	if($2->type != "int"){ //only int arrays are allowed
		yyerror("Type mismatch. Arrays must be of type int");
	}
	$$ = new CodeNode;
	$$->type = "array";
	$$->code = $2->code;
	if($3 != nullptr){
		strcat($$->code, " ");
		strcat($$->code, $3->code);
	}
};

data : NUMBER{
	$$ = new CodeNode;
	$$->type = "int";
	$$->code = $1;
}
| ID{
	Bucket* var = findSymbol($1, currentTable);
	if(var == nullptr){
		yyerror("Undeclared variable");
	}
	if(var->type != "int"){ //only int arrays are allowed
		yyerror("Type mismatch. Arrays must be of type int");
	}
	$$ = new CodeNode;
	$$->type = "int";
	$$->code = var->name;
}
;


data_: {
	$$ = nullptr;
}
| COMMA data data_{
	if($2->type != "int"){ //only int arrays are allowed
		yyerror("Type mismatch. Arrays must be of type int");
	}
	$$ = new CodeNode;
	$$->type = $2->type;
	$$->code = $2->code;
	if($3 != nullptr){
		$$->code += " " + $3->code;
	}
}
;

if_stmt : IF L_PAREN bool_expr R_PAREN L_BRACE EOL if_body EOL R_BRACE else_if_stmt else_stmt{
	char* tempLabel1 = newLabel();
	char* tempLabel2 = newLabel();
	$$ = new CodeNode;
	//We want to jump to the else if statement if the bool_expr is false
	//so we need to invert the result of bool_expr
	$$->code = $3->code + "\n! " + $3->name + ", " + $3->name + "\n";
	//finish running program
	//go to the end of the if statement
    //generate a new label to go to if the bool_expr is false
	$$->code += "?:= " + tempLabel1 + ", " + $3->name + "\n" + $7->code + "\n:= " + tempLabel2 + "\n:" + tempLabel1;
	tempLabel = newLabel();
	if($10 != nullptr){
		changeLabel($10->code, tempLabel2); //change TEMPLABEL to go to the end of if statement
		$$->code += "\n" + $10->code;
	}
	if($11 != nullptr){
		//since this is else statement
		//it automatically goes to the end of the if statement
		//once it is done executing
		//therefore, no need to change the label
		$$->code += "\n" + $11->code;
	}
	$$->code += "\n:" + tempLabel2; //set the end of the if statement
};

else_stmt :{
	$$ = nullptr;
}
| ELSE L_BRACE EOL if_body EOL R_BRACE{
	$$ = $4;
}

else_if_stmt: {
	$$ = nullptr;
}
| ELSE_IF L_PAREN bool_expr R_PAREN L_BRACE EOL if_body EOL R_BRACE else_if_stmt{
	$$ = (*CodeNode)malloc(sizeof(struct CodeNode));
	string tempLabel1 = newLabel();
	$$->code = $3->code + "\n! " + $3->name + ", " + $3->name + "\n";
	//We want to jump to the else if statement if the bool_expr is false, so we need to invert the result of bool_expr
	$$->code += "?:=" + tempLabel1 + ", " + $3->name + "\n" + $7->code + "\n:=TEMPLABEL\n:" + tempLabel1;
	if($10 != nullptr){
		strcat($$->code, "\n");
		changeLabel($10->code, "TEMPLABEL");
		strcat($$->code, $10->code);
	}
}
;

while_stmt : WHILE L_PAREN bool_expr R_PAREN L_BRACE EOL loop_body EOL R_BRACE{
	$$ = new CodeNode;
	string tempLabel1 = newLabel();
	string tempLabel2 = newLabel();
	$$->code = : + tempLabel1 + "\n" + $3->code + "\n" + "! " + $3->name + ", " + $3->name + "\n";
	//We want to jump to the end of the while statement if the bool_expr is false, so we need to invert the result of bool_expr
	$$->code += "?:=" + tempLabel2 + ", " + $3->name + "\n";
	//in case there is a break statement, we want to change the labels first
	changeLabel($7->code, tempLabel2);
	$$->code += $7->code + "\n" + ":=" + tempLabel1 + "\n:" + tempLabel2;
}
;

//fuck type checking, not doing it
arguments: datatype ID arguments_{
	$$ = new CodeNode;
	$$->code = ". " + $2;
	if($3 != nullptr){
		$$->code += "\n" + $3->code;
	}
}
;

arguments_ :  {
	$$ = nullptr;
}
| COMMA datatype ID arguments_{
	$$ = new CodeNode;
	$$->code = ". " + $3;
	if($3 != nullptr){
		$$->code += "\n" + $3->code;
	}
}
;

/****
FIXME: We need to make chained symbol tables
***/

parameter : {
	$$ = nullptr;
}
| NUMBER parameter_ {
	$$ = new CodeNode;
	$$->code = "param " + $1;
	if($2 != nullptr){
		$$->code += "\n" + $2->code;
	}
}
| ID parameter_ {
	Bucket* var = findSymbol($1);
	if(var == nullptr){
		yyerror("Undeclared variable");
	}
	$$ = new CodeNode;
	$$->code = "param " + var->name;
	if($2 != nullptr){
		$$->code += "\n" + $2->code;
	}
}
;

parameter_ : {
	$$ = nullptr;
}
| COMMA NUMBER parameter_ {
	$$ = new CodeNode;
	$$->code = "param " + $2;
	if($3 != nullptr){
		$$->code += "\n" + $3->code;
	}
}
| COMMA ID parameter_ {
	Bucket* var = findSymbol($2);
	if(var == nullptr){
		yyerror("Undeclared variable");
	}
	$$ = new CodeNode();
	$$->code = "param " + var->name;
	if($3 != nullptr){
		$$->code += "\n" + $3->code;
	}
}
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
		currentTable[i] = nullptr;
	} //initialize symbol table
	fp = fopen("output.cplt", "w");
	yyparse();
	fclose(fp);
	return 0;

}
