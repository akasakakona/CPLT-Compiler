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

int yylex();
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

void addSymbol(std::string name, std::string type, std::vector<Bucket*>& table){
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

Bucket* findSymbol(std::string name, const std::vector<Bucket*>& table){
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

std::vector<std::vector<Bucket*> > symbolTable(1, std::vector<Bucket*>(50, nullptr));

size_t currTableIndex = 0;
std::vector<Bucket*> currentTable = symbolTable.at(0);

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
%type <node> function_body
%type <node> declaration_stmt parameter if_stmt while_stmt assignment_stmt
%type <node> expression loop_body declaration data_ else_stmt else_if_stmt
%type <node> parameter_ if_body data arguments_ array 
%type <node> datatype bool_expr math_expr boolop term addop mulop factor result

%%

result: function_defs EOL program{
	fout << $1->code << std::endl << "func main" << std::endl << $3->code << std::endl << "endfunc" << std::endl;
	printf("%s\nfunc main\n%s\nendfunc\n", ($1->code).c_str(), ($3->code).c_str());
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
	if(findSymbol(std::string($2), currentTable) != nullptr){
		yyerror("ID already declared");
	}
	if(std::string($2) == "main"){
		yyerror("main function cannot be declared");
	}
	addSymbol(std::string($2), "function", currentTable);
	//creating and entering a new scope. Therefore creating a new symbol table
	currTableIndex++;
	symbolTable.push_back(std::vector<Bucket*>(50, nullptr));
	currentTable = symbolTable.at(currTableIndex);
	$<node>$ = new CodeNode;
	$<node>$->code = "func " + std::string($2) + "\n";
}arguments R_PAREN L_BRACE EOL function_body EOL R_BRACE EOL {
	printf("function\n"); 
	$$->code += $<node>4->code + $<node>8->code + "endfunc";
	//exiting the scope. Therefore deleting the symbol table
	symbolTable.pop_back();
	currTableIndex--;
	currentTable = symbolTable.at(currTableIndex);
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
	if(findSymbol(std::string($1), currentTable) == nullptr){
		yyerror("Function not declared");
	}
	if(findSymbol(std::string($1), currentTable)->type != "function"){
		yyerror("Not a function");
	}
	printf(" function_call\n");
	$$ = new CodeNode;
	$$->code = $3->code + "\n" + "call " + std::string($1);
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
 | OUT L_PAREN expression R_PAREN {//FIXME: needs to complete IN and OUT, this should be available in all bodies
	printf(" out\n");
	$$ = new CodeNode;
 }
 | IN L_PAREN expression R_PAREN {
	printf(" in\n");
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
	if(findSymbol(std::string($1), currentTable) == nullptr){
		yyerror("Function not declared");
	}
	if(findSymbol(std::string($1), currentTable)->type != "function"){
		yyerror("Not a function");
	}
	printf(" function_call\n");
	$$ = new CodeNode;
	$$->code = $3->code + "\n" + "call " + std::string($1);
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

//FIXME: needs to be completed
 function_body:declaration_stmt {
 	$$ = new CodeNode;
	$$->code = $1->code + "\n";
 }
 | assignment_stmt {
	$$ = new CodeNode;
	$$->code = $1->code + "\n";
 }
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

//FIXME: needs to be completed
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
	Bucket* var = findSymbol(std::string($1), currentTable);
	if(var == nullptr){
		yyerror("Variable not declared");
	}
	if(var->type != $3->type){
		yyerror("Type mismatch");
	}
	$$->code = $3->code + "\n= " + var->name + ", " + $3->name;
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
	$$->code = $3->code + "\n" + $6->code + "\n[]= " + var->name + ", " + $3->name + ", " + $6->name;
}

declaration_stmt: datatype ID declaration{
	$$ = new CodeNode;
	addSymbol(std::string($2), $1->type, currentTable);
	$$->code = $3->code + "\n. " + std::string($2);
	if($3 != nullptr){
		$$->code += "\n= " + std::string($2) + ", " + $3->name;
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
		$$->code = ".[] " + std::string($2) + ", " + std::to_string(count+1) + "\n" + $$->code;

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
	$$->code = $4->code + "\n";
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
		$$->code = ".[] " + $$->name + ", " + std::to_string(count+1) + "\n" + $$->code;
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
	$$->code = $3->code + "\n" + "call " + std::string($1) + ", " + $$->name;
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
	$$->type = "int";
	$$->code = $3->code + "\n" + "=[] " + $$->name + ", " + std::string($1) + ", " + $3->name;
} //array access
| array {
	$$ = $1;
}
;

//FIXME: needs to be completed
math_expr: term addop math_expr {
	$$ = new CodeNode;
	$$->type = $1->type;
	if($1->type != "int" && $3->type != "int"){
		yyerror("type mismatch");
	}
	//$$->name = newTemp();
	$$->code = $1->code + " " + $2->name + " " + $3->code + "\n";
	if ($2->name == "+") {
		$$->name = $1->name + $3->name;
	}
	else if ($2->name == "-") {
		$$->name = $1->name + $3->name;
	}
}
| term {
	$$ = $1;
}
; 

bool_expr: math_expr boolop math_expr{
	$$ = new CodeNode;
	if($1->type != "int" || $3->type != "int"){
		yyerror("type mismatch");
	}
	$$->name = newTemp();
	$$->code = $1->code + "\n" + $3->code + "\n" + $2->name + " " + $$->name + ", " + $1->name + ", " + $3->name + "\n";
	
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
		yyerror("Undeclared variable");
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
	std::istringstream iss($3->code);
	std::string token;
	while(iss >> token){
		$$->code += "param " + token + "\n";
	}
	$$->code += "call " + std::string($1) + ", " + $$->name + "\n";
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
	$$->code = $1->code + "\n" + $3->code + "\n" + $2->name + " " + $$->name + ", " + $1->name + ", " + $3->name + "\n";
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
	$$->name = $1;
}
| ID{
	Bucket* var = findSymbol(std::string($1), currentTable);
	if(var == nullptr){
		yyerror("Undeclared variable");
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
	$$->code = $1;
}
| ID{
	Bucket* var = findSymbol(std::string($1), currentTable);
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
	std::string tempLabel1 = newLabel();
	std::string tempLabel2 = newLabel();
	$$ = new CodeNode;
	//We want to jump to the else if statement if the bool_expr is false
	//so we need to invert the result of bool_expr
	$$->code = $3->code + "\n! " + $3->name + ", " + $3->name + "\n";
	//finish running program
	//go to the end of the if statement
    //generate a new label to go to if the bool_expr is false
	$$->code += "?:= " + tempLabel1 + ", " + $3->name + "\n" + $7->code + "\n:= " + tempLabel2 + "\n:" + tempLabel1;
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
	$$ = new CodeNode;
	std::string tempLabel1 = newLabel();
	$$->code = $3->code + "\n! " + $3->name + ", " + $3->name + "\n";
	//We want to jump to the else if statement if the bool_expr is false, so we need to invert the result of bool_expr
	$$->code += "?:=" + tempLabel1 + ", " + $3->name + "\n" + $7->code + "\n:=TEMPLABEL\n:" + tempLabel1;
}
;

while_stmt : WHILE L_PAREN bool_expr R_PAREN L_BRACE EOL loop_body EOL R_BRACE{
	$$ = new CodeNode;
	std::string tempLabel1 = newLabel();
	std::string tempLabel2 = newLabel();
	$$->code = ":" + tempLabel1 + "\n" + $3->code + "\n" + "! " + $3->name + ", " + $3->name + "\n";
	//We want to jump to the end of the while statement if the bool_expr is false, so we need to invert the result of bool_expr
	$$->code += "?:=" + tempLabel2 + ", " + $3->name + "\n";
	//in case there is a break statement, we want to change the labels first
	changeLabel($7->code, tempLabel2);
	$$->code += $7->code + "\n" + ":=" + tempLabel1 + "\n:" + tempLabel2;
}
;

arguments: datatype ID arguments_{
	$$ = new CodeNode;
	$$->code = ". " + std::string($2);
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
	if($4 != nullptr){
		$$->code += "\n" + $4->code;
	}
}
;

parameter : {
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
	$$->code = "param " + std::string($2);
	if($3 != nullptr){
		$$->code += "\n" + $3->code;
	}
}
| COMMA ID parameter_ {
	Bucket* var = findSymbol(std::string($2), currentTable);
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

std::string mycont(char* a, char* b){

	strcat(a,b);
	return a;
}

int main(int argc, char **argv)
{
	fout.open("output.txt");
	if(!fout.is_open()){
		printf("Error opening file\n");
		exit(1);
	}
	yyparse();
	fout.close();
	return 0;

}
