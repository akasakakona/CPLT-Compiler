//2-3pm wch116

%{
#include <iostream>
#include <string>
#include <vector>
#include <cstdlib>
#include <fstream>
#include <sstream>
#include <stdio.h>
#include <cstring>
#include <stdlib.h>

extern "C" int yylex();
extern int yyleng;
extern int yylineno;

extern FILE *yyin;
extern char* yytext;

void yyerror(const char *s);
std::string mycont(std::string a, std::string b);

struct Bucket {
	std::string name;
	std::string type;
	Bucket* next;
};

void changeLabel(std::string& text, std::string newLabel) {
	std::string::size_type i = 0;
	while((i = text.find("TEMPLABEL", i)) != std::string::npos) {
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
	std::string code;
	std::string name;
	std::string type;
};

int hash(std::string a){
	int i;
	int sum = 0;
	for(i = 0; i < a.size(); i++){
		sum += a.at(i);
	}
	return sum % 50;
}

void delSymbole(std::string a, std::vector<Bucket*>& table){
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

void addSymbol(std::string name, std::string type, std::vector<Bucket*>* table){
	int i = hash(name);
	Bucket* temp = table->at(i);
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
	if(table->at(i) != nullptr){
		newBucket->next = table->at(i);
	}else{
		newBucket->next = nullptr;
	}
	table->at(i) = newBucket;
}

Bucket* findSymbol(std::string name, const std::vector<Bucket*>* table){
	int i = hash(name);
	Bucket* temp = table->at(i);
	while(temp != nullptr){
		if(temp->name == name){
			return temp;
		}
		temp = temp->next;
	}
	return nullptr;
}

std::string newTemp(){
	static int i = 0;
	std::string temp = "t";
	temp += std::to_string(i);
	i++;
	return temp;
}
std::string newLabel(){
	static int j = 0;
	std::string temp = "L";
	temp += std::to_string(j);
	j++;
	return temp;
}

int paramCount = 0;

int newParam(){
	return paramCount++;
}

void resetParam(){
	paramCount = 0;
}

std::vector<std::vector<Bucket*> > symbolTable(1, std::vector<Bucket*>(50, nullptr));

size_t currTableIndex = 0;
std::vector<Bucket*>* currentTable = &symbolTable.at(0);



std::ofstream fout;

%}

%union {
    char* string;
	struct CodeNode* node;
}
/* declare tokens */
%token <string> NUMBER
%token PLUS MINUS MULT DIV
%token ASSIGN
%token EOL
//%token END
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
%token <string> ID
%token EQUAL NE SE BE SMALLER BIGGER
%token FUNCTION
%token TRUE
%token FALSE
%token COMMENT
%token OUT
%token IN
//%token AND
//%token OR
//%token NOT

%type <node> function_defs function_def program stmt arguments
%type <node> function_body loop_bodies function_bodies if_bodies
%type <node> declaration_stmt parameter if_stmt while_stmt assignment_stmt
%type <node> expression loop_body declaration data_ else_stmt else_if_stmt
%type <node> parameter_ if_body data arguments_ array funct
%type <node> datatype bool_expr math_expr boolop term addop mulop factor result

%%

result: function_defs program{
	if($1 != nullptr){
		fout << $1->code << std::endl << std::endl;
	}
	fout << "func main" << std::endl << $2->code << std::endl << "endfunc" << std::endl;
	printf("Code generated successfully!\n");
}

function_defs: {
	$$ = nullptr;
}
| function_def EOL function_defs{
	$$ = new CodeNode;
	$$->code = $1->code;
	if($3 != nullptr){
		$$->code += "\n\n" + $3->code;
	}
}

funct: FUNCTION ID L_PAREN{
	//creating and entering a new scope. Therefore creating a new symbol table
	if(std::string($2) == "main"){
		yyerror("main function cannot be defined");
	}
	if(findSymbol(std::string($2), currentTable) != nullptr){
		yyerror("Repeated function declaration");
	}
	addSymbol(std::string($2), "function", currentTable);
	symbolTable.push_back(std::vector<Bucket*>(50, nullptr));
	currTableIndex++;
	currentTable = &symbolTable.at(currTableIndex);
	$$ = new CodeNode;
	$$->code = "func " + std::string($2);
}

function_def: funct arguments R_PAREN L_BRACE EOL function_bodies R_BRACE {
	$$ = new CodeNode;
	$$->code = $1->code;
	if($2 != nullptr){
		$$->code += "\n" + $2->code;
	}
	$$->code += "\n" + $6->code;
	if($6->code.find("ret") == std::string::npos){
		$$->code += "\nret";
	}
	$$->code += "\nendfunc";
	//exiting the scope. Therefore deleting the symbol table
	symbolTable.pop_back();
	currTableIndex--;
	currentTable = &symbolTable.at(currTableIndex);
	resetParam();
};

program: stmt{
	$$ = $1;
}
| program EOL stmt{
	$$ = new CodeNode;
	if($1->code != ""){
		$$->code = $1->code;
	}
	if($3 != nullptr){
		$$->code += "\n" + $3->code;
	}
}
;

stmt: {
	$$ = nullptr;
}
 | declaration_stmt {
	$$ = $1;
	}
 | ID L_PAREN parameter R_PAREN {
	if(findSymbol(std::string($1), currentTable) == nullptr){
		yyerror("Function not declared");
	}
	if(findSymbol(std::string($1), currentTable)->type != "function"){
		yyerror("Not a function");
	}
	$$ = new CodeNode;
	if($3 != nullptr){
		$$->code = $3->code + "\n";
	}
	std::string temp = newTemp();
	$$->code += ". " + temp + "\n" + "call " + std::string($1) + ", " + temp;
	}
 | if_stmt {
	$$ = $1;
	}
 | while_stmt {
	$$ = $1;
	}
 | assignment_stmt {
	$$ = $1;
	}
 | OUT L_PAREN ID R_PAREN {
	if(findSymbol(std::string($3), currentTable) == nullptr){
		yyerror("Variable not declared");
	}
	$$ = new CodeNode;
	$$->code = ".> " + std::string($3);
	}
 | IN L_PAREN ID R_PAREN {
	if(findSymbol(std::string($3), currentTable) == nullptr){
		yyerror("Variable not declared");
	}
	$$ = new CodeNode;
	$$->code = ".< " + std::string($3);
	}
 | COMMENT {
	$$ = nullptr;
	}
 ;

if_bodies: {
	$$ = nullptr;
}
| if_body EOL if_bodies {
	$$ = new CodeNode;
	$$->code = $1->code;
	if($3 != nullptr){
		$$->code += "\n" + $3->code;
	}
}

 if_body: declaration_stmt {
	$$ = $1;
    }
 | ID L_PAREN parameter R_PAREN {
	if(findSymbol(std::string($1), currentTable) == nullptr){
		yyerror("Function not declared");
	}
	if(findSymbol(std::string($1), currentTable)->type != "function"){
		yyerror("Not a function");
	}
	$$ = new CodeNode;
	$$->code = $3->code + "\n" + "call " + std::string($1) + ", " +  newTemp();
	}
 | if_stmt {
	$$ = $1;
	}
 | while_stmt {
	$$ = $1;
	}
 | assignment_stmt {
	$$ = $1;
	}
 | COMMENT {
	$$ = nullptr;
	}
 | OUT L_PAREN ID R_PAREN {
	if(findSymbol(std::string($3), currentTable) == nullptr){
		yyerror("Variable not declared");
	}
	$$ = new CodeNode;
	$$->code = ".> " + std::string($3);
	}
 | IN L_PAREN ID R_PAREN {
	if(findSymbol(std::string($3), currentTable) == nullptr){
		yyerror("Variable not declared");
	}
	$$ = new CodeNode;
	$$->code = ".< " + std::string($3);
	}
 ;

function_bodies:{
	$$ = nullptr;
}
| function_body EOL function_bodies{
	$$ = new CodeNode;
	$$->code = $1->code;
	if($3 != nullptr){
		$$->code += "\n" + $3->code;
	}
}

 function_body:declaration_stmt{
	$$ = $1;
 }
 | assignment_stmt{
	$$ = $1;
 }
 | if_stmt{
	$$ = $1;
 }
 | while_stmt{
	$$ = $1;
 }
 | RETURN expression {
	$$ = new CodeNode;
	if($2->code != ""){
		$$->code = $2->code + "\n";
	}
	$$->code += "ret " + $2->name;
	}
 | RETURN{
	$$ = new CodeNode;
	$$->code = "ret";
	}
 | ID L_PAREN parameter R_PAREN {
	if(findSymbol(std::string($1), currentTable) == nullptr){
		yyerror("Function not declared");
	}
	$$ = new CodeNode;
	$$->code = $3->code + "\n" + "call " + std::string($1) + ", " + newTemp();
	}
 | COMMENT{
	$$ = nullptr;
 }
 | OUT L_PAREN ID R_PAREN {
	if(findSymbol(std::string($3), currentTable) == nullptr){
		yyerror("Variable not declared");
	}
	$$ = new CodeNode;
	$$->code = ".> " + std::string($3);
	}
 | IN L_PAREN ID R_PAREN {
	if(findSymbol(std::string($3), currentTable) == nullptr){
		yyerror("Variable not declared");
	}
	$$ = new CodeNode;
	$$->code = ".< " + std::string($3);
	}
 ;

loop_bodies: {
	$$ = nullptr;
}
| loop_body EOL loop_bodies{
	$$ = new CodeNode;
	$$->code = $1->code;
	if($3 != nullptr){
		$$->code += "\n" + $3->code;
	}
}

 loop_body: declaration_stmt{
	$$ = $1;
 }
 | assignment_stmt{
	$$ = $1;
 }
 | if_stmt{
	$$ = $1;
 }
 | while_stmt{
	$$ = $1;
 }
 | COMMENT{
	$$ = nullptr;
 }
 | ID L_PAREN parameter R_PAREN {
	if(findSymbol(std::string($1), currentTable) == nullptr){
		yyerror("Function not declared");
	}
	$$ = new CodeNode;
	$$->code = $3->code + "\n" + "call " + std::string($1) + ", " + newTemp();
	}
 | BREAK {
	$$ = new CodeNode;
	$$->code = ":= TEMPLABEL";
	}
 | OUT L_PAREN ID R_PAREN {
	if(findSymbol(std::string($3), currentTable) == nullptr){
		yyerror("Variable not declared");
	}
	$$ = new CodeNode;
	$$->code = ".> " + std::string($3);
	}
 | IN L_PAREN ID R_PAREN {
	if(findSymbol(std::string($3), currentTable) == nullptr){
		yyerror("Variable not declared");
	}
	$$ = new CodeNode;
	$$->code = ".< " + std::string($3);
	}
 ;


assignment_stmt: ID ASSIGN expression{
	$$ = new CodeNode;
	Bucket* var = findSymbol(std::string($1), currentTable);
	if(var == nullptr){
		yyerror("Variable not declared");
	}
	if(var->type != $3->type){
		yyerror("Type mismatch");
	}
	if($3->code != ""){
		$$->code = $3->code + "\n";
	}
	$$->code += "= " + var->name + ", " + $3->name;
}
| ID L_BRACK expression R_BRACK ASSIGN expression{
	$$ = new CodeNode;
	Bucket* var = findSymbol(std::string($1), currentTable);
	if(var == nullptr){
		yyerror("Variable not declared");
	}
	if($6->type != "int"){
		yyerror("Type mismatch, array can only store int");
	}
	if($3->type != "int"){
		yyerror("Type mismatch, array index must be int");
	}
	if($3->code != ""){
		$$->code = $3->code + "\n";
	}
	if($6->code != ""){
		$$->code += $6->code + "\n";
	}
	$$->code += "[]= " + var->name + ", " + $3->name + ", " + $6->name;
}

declaration_stmt: datatype ID declaration{
	if(findSymbol(std::string($2), currentTable) != nullptr){
		yyerror("redeclaration of variable");
	}
	$$ = new CodeNode;
	addSymbol(std::string($2), $1->type, currentTable);
	if($3 != nullptr){
		if($3->code != ""){
			$$->code = $3->code + "\n";
		}
		$$->code += ". " + std::string($2) + "\n= " + std::string($2) + ", " + $3->name;
	}else{
		$$->code = ". " + std::string($2);
	}
}
| datatype ID L_BRACK R_BRACK declaration{
	if(findSymbol(std::string($2), currentTable) != nullptr){
		yyerror("redeclaration of variable");
	}
	$$ = new CodeNode;
	if($5 == nullptr){ 
		yyerror("array size not specified"); //codes like: "itg a[]" is not allowed
	}else{
		//if the type field of declaration node is not empty, then it is a declaration with assignment
		//In that case, we need to generate a new temporary variable, therefore we use newTemp() as the third parameter
		//and we also need to generate code for the assignment
		$$->name = std::string($2);
		addSymbol(std::string($2), "array", currentTable);
		int count = 0;
		std::istringstream iss($5->code);
		std::string token = "";
		//generate the code that assigns the value to the array
		while(iss >> token){
			$$->code += "[]= " + std::string($2) + ", " + std::to_string(count) + ", " + token + "\n";
			count++;
		}
		$$->code.pop_back();
		$$->code = ".[] " + std::string($2) + ", " + std::to_string(count) + "\n" + $$->code;
	}
}
| datatype ID L_BRACK expression R_BRACK declaration{
	if(findSymbol(std::string($2), currentTable) != nullptr){
		yyerror("redeclaration of variable");
	}
	if($4->type != "int"){
		yyerror("array size must be an integer");
	}
	$$ = new CodeNode;
	if($4->code != ""){
		$$->code = $4->code + "\n";
	}
	addSymbol(std::string($2), "array", currentTable);
	if($6 == nullptr){ 
		//In this case, things like "itg a[3]" is allowed, since we know the size of the array
		$$->name = std::string($2);
		$$->code += ".[] " + $$->name + ", " + $4->name;
	}else{
		$$->name = std::string($2);
		std::istringstream iss($6->code);
		std::string token;
		int count = 0;
		while(iss >> token){
			$$->code += "[]= " + $$->name + ", " + std::to_string(count) + ", " + token + "\n";
			count++;
		}
		$$->code.pop_back();
		$$->code = ".[] " + $$->name + ", " + std::to_string(count) + "\n" + $$->code;
	}
};

declaration: {
	$$ = nullptr;
}
| ASSIGN expression{
	$$ = $2;
}
;

datatype: INTEGER{
	$$ = new CodeNode;
	$$->type = "int";
}
| BOOLEAN{
	$$ = new CodeNode;
	$$->type = "bool";
}
;

expression: math_expr{
	$$ = $1;
}
| ID L_PAREN parameter R_PAREN {
	Bucket* funct = findSymbol(std::string($1), currentTable);
	if(funct == nullptr){
		yyerror("Undeclared function");
	}
	if(funct->type != "function"){
		yyerror("Not a function");
	}
	/*******
	NOTE: According to the professor, we do not need to check the validity of the function call
	So a function table is optional
	*******/
	$$ = new CodeNode;
	$$->name = newTemp();
	$$->code = ". " + $$->name + "\n";
	$$->code += $3->code + "\n" + "call " + std::string($1) + ", " + $$->name;
} //function call
| TRUE{
	$$ = new CodeNode;
	$$->name = "1";
	$$->type = "bool";
}
| FALSE{
	$$ = new CodeNode;
	$$->name = "0";
	$$->type = "bool";
}
| ID L_BRACK expression R_BRACK{
	Bucket* array = findSymbol(std::string($1), currentTable);
	if(array == nullptr){
		yyerror("Undeclared array");
	}
	if(array->type != "array"){
		yyerror("Not an array");
	}
	if($3->type != "int"){
		yyerror("Array index must be an integer");
	}
	$$ = new CodeNode;
	$$->name = newTemp();
	$$->code = ". " + $$->name + "\n";
	$$->type = "int";
	if($3->code != ""){
		$$->code += $3->code + "\n";
	}
	$$->code += "=[] " + $$->name + ", " + std::string($1) + ", " + $3->name;
} //array access
| array {
	$$ = $1;
}
;

//FIXME: needs to be completed
math_expr: math_expr addop term {
	$$ = new CodeNode;
	if($1->type != "int" || $3->type != "int"){
		yyerror("type mismatch");
	}
	$$->name = newTemp();
	$$->code = ". " + $$->name + "\n";
	if($1->code != ""){
		$$->code += $1->code + "\n";
	}
	if($3->code != ""){
		$$->code += $3->code + "\n";
	}
	$$->code += $2->name + " " + $$->name + ", " + $1->name + ", " + $3->name;
	$$->type = "int";
}
| term {
	$$ = $1;
}
; 

bool_expr: expression boolop expression{
	$$ = new CodeNode;
	if($1->type != "int" || $3->type != "int"){
		yyerror("type mismatch");
	}
	$$->name = newTemp();
	$$->code = ". " + $$->name + "\n";
	if($1->code != ""){
		$$->code += $1->code + "\n";
	}
	if($3->code != ""){
		$$->code += $3->code + "\n";
	}
	$$->code += $2->name + " " + $$->name + ", " + $1->name + ", " + $3->name;
	
}
| TRUE{
	$$ = new CodeNode;
	$$->type = "bool";
	$$->name = "1";
}
| FALSE{
	$$ = new CodeNode;
	$$->type = "bool";
	$$->name = "0";
}
| ID{
	Bucket* var = findSymbol(std::string($1), currentTable);
	if(var == nullptr){
		char error[100] = "Undeclared variable: ";
		strcat(error, $1);
		yyerror(error);
	}
	if(var->type != "bool"){
		yyerror("Type mismatch! Boolean expected");
	}
	$$ = new CodeNode;
	$$->type = var->type;
	$$->name = var->name;
}
| ID L_PAREN parameter R_PAREN {
	Bucket* funct = findSymbol(std::string($1), currentTable);
	if(funct == nullptr){
		yyerror("Undeclared function");
	}
	if(funct->type != "function"){
		yyerror("Type mismatch");
	}
	$$ = new CodeNode;
	//here we are assuming that parameter will store a list of variable names containing the parameters in its code attribute
	//separated by spaces. Therefore, we need to separate the parameters
	$$->name = newTemp();
	$$->code = ". " + $$->name + "\n";
	std::istringstream iss($3->code);
	std::string token;
	while(iss >> token){
		$$->code += "param " + token + "\n";
	}
	$$->code += "call " + std::string($1) + ", " + $$->name;
}
;

boolop: EQUAL {
	$$ = new CodeNode;
	$$->name = "==";
}
| NE{
	$$ = new CodeNode;
	$$->name = "!=";
}
| SE{
	$$ = new CodeNode;
	$$->name = "<=";
}
| BE{
	$$ = new CodeNode;
	$$->name = ">=";
}
| SMALLER{
	$$ = new CodeNode;
	$$->name = "<";
}
| BIGGER{
	$$ = new CodeNode;
	$$->name = ">";
}
;


//We store the additon/subtraction operator in the name field of the CodeNode
addop : PLUS{
	$$ = new CodeNode;
	$$->name = "+";
}
| MINUS{
	$$ = new CodeNode;
	$$->name = "-";
}
;

term: term mulop factor{
	if($1->type != $3->type){
		yyerror("Type mismatch");
	}
	$$ = new CodeNode;
	$$->type = $1->type;
	$$->name = newTemp();
	$$->code = ". " + $$->name + "\n";
	if($1->code != ""){
		$$->code += $1->code + "\n";
	}
	if($3->code != ""){
		$$->code += $3->code + "\n";
	}
	$$->code += $2->name + " " + $$->name + ", " + $1->name + ", " + $3->name;
}
| factor{
	$$ = $1;
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
	$$->name = std::string($1);
}
| ID{
	Bucket* var = findSymbol(std::string($1), currentTable);
	if(var == nullptr){
		char error[100] = "Undeclared variable: ";
		strcat(error, $1);
		yyerror(error);
	}
	$$ = new CodeNode;
	$$->type = var->type;
	$$->name = var->name;
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
		$$->code += " " + $3->code;
	}
};

data : NUMBER{
	$$ = new CodeNode;
	$$->type = "int";
	$$->code = std::string($1);
}
| ID{
	Bucket* var = findSymbol(std::string($1), currentTable);
	if(var == nullptr){
		char error[100] = "Undeclared variable: ";
		strcat(error, $1);
		yyerror(error);
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

if_stmt: IF L_PAREN bool_expr R_PAREN L_BRACE EOL if_bodies R_BRACE else_if_stmt else_stmt{
	std::string tempLabel1 = newLabel();
	std::string tempLabel2 = newLabel();
	$$ = new CodeNode;
	//We want to jump to the else if statement if the bool_expr is false
	//so we need to invert the result of bool_expr
	if($3->code != ""){
		$$->code += $3->code + "\n";
	}
	$$->code += "! " + $3->name + ", " + $3->name + "\n";
	//finish running program
	//go to the end of the if statement
    //generate a new label to go to if the bool_expr is false
	$$->code += "?:= " + tempLabel1 + ", " + $3->name + "\n" + $7->code + "\n:= " + tempLabel2 + "\n: " + tempLabel1;
	if($9 != nullptr){
		changeLabel($9->code, tempLabel2); //change TEMPLABEL to go to the end of if statement
		$$->code += "\n" + $9->code;
	}
	if($10 != nullptr){
		//since this is else statement
		//it automatically goes to the end of the if statement
		//once it is done executing
		//therefore, no need to change the label
		$$->code += "\n" + $10->code;
	}
	$$->code += "\n: " + tempLabel2; //set the end of the if statement
};

else_stmt :{
	$$ = nullptr;
}
| ELSE L_BRACE EOL if_bodies R_BRACE{
	$$ = $4;
}

else_if_stmt: {
	$$ = nullptr;
}
| ELSE_IF L_PAREN bool_expr R_PAREN L_BRACE EOL if_bodies R_BRACE else_if_stmt{
	$$ = new CodeNode;
	std::string tempLabel1 = newLabel();
	$$->code = $3->code + "\n! " + $3->name + ", " + $3->name + "\n";
	//We want to jump to the else if statement if the bool_expr is false, so we need to invert the result of bool_expr
	$$->code += "?:= " + tempLabel1 + ", " + $3->name + "\n" + $7->code + "\n:= TEMPLABEL\n: " + tempLabel1;
}
;

while_stmt: WHILE L_PAREN bool_expr R_PAREN L_BRACE EOL loop_bodies R_BRACE{
	$$ = new CodeNode;
	std::string tempLabel1 = newLabel();
	std::string tempLabel2 = newLabel();
	$$->code = ": " + tempLabel1 + "\n";
	if($3->code != ""){
		$$->code += $3->code + "\n";
	}
	$$->code += "! " + $3->name + ", " + $3->name + "\n";
	//We want to jump to the end of the while statement if the bool_expr is false, so we need to invert the result of bool_expr
	$$->code += "?:= " + tempLabel2 + ", " + $3->name + "\n";
	//in case there is a break statement, we want to change the labels first
	changeLabel($7->code, tempLabel2);
	$$->code += $7->code + "\n" + ":= " + tempLabel1 + "\n: " + tempLabel2;
}
;

arguments:{
	$$ = nullptr;
}
 | datatype ID arguments_{
	$$ = new CodeNode;
	if(findSymbol(std::string($2), currentTable) != nullptr){
		char error[100] = "Variable already declared: ";
		strcat(error, $2);
		yyerror(error);
	}
	addSymbol(std::string($2), $1->type, currentTable);
	$$->code = ". " + std::string($2) + "\n= " + std::string($2) + ", $" + std::to_string(newParam());
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
	$$->code = ". " + std::string($3);
	if(findSymbol(std::string($3), currentTable) != nullptr){
		char error[100] = "Variable already declared: ";
		strcat(error, $3);
		yyerror(error);
	}
	addSymbol(std::string($3), $2->type, currentTable);
	$$->code = ". " + std::string($3) + "\n= " + std::string($3) + ", $" + std::to_string(newParam());
	if($4 != nullptr){
		$$->code += "\n" + $4->code;
	}
}
;

parameter: {
	$$ = nullptr;
}
| NUMBER parameter_ {
	$$ = new CodeNode;
	$$->code = "param " + std::string($1);
	if($2 != nullptr){
		$$->code += "\n" + $2->code;
	}
}
| ID parameter_ {
	Bucket* var = findSymbol(std::string($1), currentTable);
	if(var == nullptr){
		char error[100] = "Undeclared variable: ";
		strcat(error, $1);
		yyerror(error);
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
	$$->code = "param " + std::string($2);
	if($3 != nullptr){
		$$->code += "\n" + $3->code;
	}
}
| COMMA ID parameter_ {
	Bucket* var = findSymbol(std::string($2), currentTable);
	if(var == nullptr){
		char error[100] = "Undeclared variable: ";
		strcat(error, $2);
		yyerror(error);
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
	fprintf(stderr, "ERROR LINE %d: %s\n", yylineno, s);
	exit(1);
};

std::string mycont(char* a, char* b){
	strcat(a,b);
	return a;
}

int main(int argc, char **argv)
{
	fout.open("output.mil");
	if(!fout.is_open()){
		printf("Error opening file\n");
		exit(1);
	}
	++argv, --argc; /* skip over program name */
	if(argc > 0){
		yyin = fopen(argv[0], "r");
	}
	else{
		yyin = stdin;
	}
	yyparse();
	fout.close();
	return 0;
}