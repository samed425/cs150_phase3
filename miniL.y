    /* cs152-miniL phase2 */
%{
#include <stdio.h>
#include <stdlib.h>
#include <string>
#include <string.h>
#include <sstream>
#include <vector>
#include "lib.h"

//%define api.value.type variant

void yyerror(const char *msg);
void serror(const char *msg);
extern int yylex();
extern int currLine;
extern int currPos;

char *identToken;
int numberToken;
int  count_names = 0;


enum Type { Integer, Array };
struct Symbol {
  std::string name;
  Type type;
  int size;
};
struct Function {
  std::string name;
  std::vector<Symbol> declarations;
};

std::vector <Function> symbol_table;
std::string reserved[51] = {"function", "beginparams", "endparams", "beginlocals", "endlocals", "integer", "array", "enum", "of", "if", "then", "endif", "else", "for", "while", "do", "beginloop", "endloop", "continue", "read", "write", "and", "or", "not", "true", "false", "return", "-", "+", "*", "/", "%", "==", "<>", "<", ">", "<=", ">=", "identiier", "number", ";", ":", ".", ",", "(", ")", "[", "]", ":=", "MINI-L" };

Function *get_function() {
  int last = symbol_table.size()-1;
  return &symbol_table[last];
}

bool find(std::string &value) {
  Function *f = get_function();
  for(int i=0; i < f->declarations.size(); i++) {
    Symbol *s = &f->declarations[i];
    if (s->name == value) {
      return true;
    }
  }
  return false;
}

Symbol* search_symbol(std::string value) {
  Symbol* symbol = nullptr;
  Function *f = get_function();
    for(int i=0; i < f->declarations.size(); i++) {
      Symbol *s = &f->declarations[i];
      if (s->name == value) {
        symbol = s;
      }
    }
  return symbol;
}

bool int_var_check(std::string name, int index) {
        if (find(name)) {
                serror("Variable already defined");
                return false;
        }
	for (int i = 0; i < 51; i++) {
		if (name == reserved[i]) {
			serror("Invalid variable name");
			return false;
		}
	}
	return true;
}

bool arr_var_check(std::string name, int index) {
        if (find(name)) {
                serror("Variable already defined");
                return false;
        }
        for (int i = 0; i < 51; i++) {
                if (name == reserved[i]) {
                        serror("Invalid variable name");
                        return false;
                }
        }
	if (index < 1) {
		serror("Invalid array size");
		return false;
	}
	return true;
}

bool find_function(std::string &value) {
	for (int i = 0; i < symbol_table.size(); i++) {
		if (symbol_table[i].name == value) {
			return true;
		}
	}
return false;
}


void add_function_to_symbol_table(char* &value) {
  Function f;
  f.name = value;
  symbol_table.push_back(f);
}

void add_variable_to_symbol_table(std::string &value, Type t, int size) {
  if (t == Integer) {
    if (int_var_check(value, size)) {
      Symbol s;
      s.name = value;
      s.type = t;
      s.size = size;
      Function *f = get_function();
      f->declarations.push_back(s);
    }
    else {
      return;
    }
  }

  else {
    if (arr_var_check(value, size)) {
      Symbol s;
      s.name = value;
      s.type = t;
      s.size = size;
      Function *f = get_function();
      f->declarations.push_back(s);
    }
    else {
      return;
    }
  }
  return;
}

void print_symbol_table(void) {
  printf("symbol table:\n");
  printf("--------------------\n");
  for(int i=0; i<symbol_table.size(); i++) {
    printf("function: %s\n", symbol_table[i].name.c_str());
    for(int j=0; j<symbol_table[i].declarations.size(); j++) {
      if (symbol_table[i].declarations[j].type == Array) {
	printf("  locals: %s[%i]\n", symbol_table[i].declarations[j].name.c_str(), symbol_table[i].declarations[j].size);
      }
      else {
	printf("  locals: %s\n", symbol_table[i].declarations[j].name.c_str());
      }
    }
  }
  printf("--------------------\n");
}

%}

%union{
  /* put your types here */
	char* str;
	int num;
}

%error-verbose
%locations
%start prog_start
%token FUNCTION BEGIN_PARAMS END_PARAMS BEGIN_LOCALS END_LOCALS BEGIN_BODY END_BODY INTEGER ARRAY ENUM OF IF THEN ENDIF ELSE FOR WHILE DO BEGINLOOP ENDLOOP CONTINUE READ WRITE AND OR NOT TRUE FALSE RETURN SUB ADD MULT DIV MOD EQ NEQ LT GT LTE GTE SEMICOLON COLON COMMA L_PAREN R_PAREN L_SQUARE_BRACKET R_SQUARE_BRACKET ASSIGN EQ_SIGN
%token <str> IDENT
%type <str> identifier
%token <str> NUMBER
%type <str> number
%type <num> arr_var
%right ASSIGN
%left OR
%left AND
%right NOT
%left LT LTE GT GTE EQ NEQ
%left ADD SUB
%left MULT DIV MOD
%left L_SQUARE_BRACKET R_SQUARE_BRACKET
%left L_PAREN R_PAREN
/* %start program */

%% 
prog_start:
	program	
	;

program:

|	function program 
	;

function_name:
	FUNCTION identifier {add_function_to_symbol_table($2);};

function:
	function_name SEMICOLON BEGIN_PARAMS declarations END_PARAMS BEGIN_LOCALS declarations END_LOCALS BEGIN_BODY statements END_BODY
	;

int_var:
	COLON INTEGER
|       identifier int_var {std::string str($1); for (int i = 0; i < str.size(); i++) { if (str[i] == ',' || str[i] == ' ') {str = str.substr(0, i);}} add_variable_to_symbol_table(str, Integer, -1);}
|       COMMA identifier int_var {std::string str($2); for (int i = 0; i < str.size(); i++) { if (str[i] == ' ') {str = str.substr(0, i);}} add_variable_to_symbol_table(str, Integer, -1);}
	;

arr_var:
	COLON ARRAY L_SQUARE_BRACKET number R_SQUARE_BRACKET OF INTEGER {$$ = atoi($4);}
|	identifier arr_var {$$ = $2; std::string str($1); for (int i = 0; i < str.size(); i++) { if (str[i] == ',' || str[i] == ' ') {str = str.substr(0, i);}} add_variable_to_symbol_table(str, Array, $$);}
|	COMMA identifier arr_var {$$ = $3; std::string str($2); for (int i = 0; i < str.size(); i++) { if (str[i] == ' ') {str = str.substr(0, i);}} add_variable_to_symbol_table(str, Array, $$);}
	;

declaration:
	int_var
|	identifiers COLON ENUM L_PAREN identifiers R_PAREN
|	arr_var
|	identifiers INTEGER {yyerror("Invalid declaration");}
|       identifiers ENUM L_PAREN identifiers R_PAREN {yyerror("Invalid declaration");}
|	identifiers ARRAY L_SQUARE_BRACKET number R_SQUARE_BRACKET OF INTEGER {yyerror("Invalid declaration");}
	;

statement:
	var ASSIGN expression
|	IF bool-expr THEN statements elses ENDIF
|	WHILE bool-expr BEGINLOOP statements ENDLOOP
|	DO BEGINLOOP statements ENDLOOP WHILE bool-expr
|	READ vars
|	WRITE vars
|	CONTINUE
|	RETURN expression
|	var EQ_SIGN expression {yyerror(":= expected");}
	;

bool-expr:
	rltn-and-expr
|	rltn-and-expr OR bool-expr
	;

rltn-and-expr:
	rltn-expr
|	rltn-expr AND rltn-and-expr
	;

rltn-expr:
	NOT rltn-expr
|	expression comp expression
|	TRUE
|	FALSE
|	L_PAREN bool-expr R_PAREN
	;

comp:
	EQ
|	NEQ
|	LT
|	GT
|	LTE
|	GTE
|	EQ_SIGN{yyerror("Invalid comparator");}
	;

expression:
	mult-expr
|	mult-expr ADD expression
|	mult-expr SUB expression
	;

mult-expr:
	term
|	term MULT mult-expr
|	term DIV mult-expr
|	term MOD mult-expr
	;
 
term:
	identifier L_PAREN expressions R_PAREN {std::string str($1); if (!(find_function(str))) { serror("Function not defined");};}
|	terms
	;

terms:
	SUB terms
|	var
|	number
|	L_PAREN expression R_PAREN
	;

var:
	identifier {std::string str($1); for (int i = 0; i < str.size(); i++) { if (!(isalpha(str[i])) && (!(isdigit(str[i]))) && !(str[i] == '_')){str = str.substr(0, i);}} if (!find(str)) { serror("Variable not defined.");} else if (search_symbol(str)->type == Array) { serror("Array variable missing index");}}
|	identifier L_SQUARE_BRACKET expression R_SQUARE_BRACKET {std::string str($1); for (int i = 0; i < str.size(); i++) { if (!(isalpha(str[i])) && (!(isdigit(str[i]))) && !(str[i] == '_')){str = str.substr(0, i);}} if (!find(str)) { serror("Variable not defined.");} else if (search_symbol(str)->type == Integer) { serror("Integer variable used as array");}  }
	;

expressions:
	
|	expression expressions2
	;

expressions2:
	
|	COMMA expression expressions2
	;
	
elses:
	
|	ELSE statements
	;


vars:
	var
|	var COMMA vars
	;

identifiers:
	identifier
|	identifier COMMA identifiers
|       identifier identifiers {yyerror("Expected comma");}
	;

declarations:
	
|	declaration SEMICOLON declarations
|	declaration declarations {yyerror("Expected semicolon");}
	;

statements:
	statement SEMICOLON
|	statement SEMICOLON statements
	;
number:
	NUMBER {$$ = $1;}
 	;

identifier:
	IDENT {$$ = $1;}
	;

  /* write your rules here */

%% 

int main(int argc, char **argv) {
   yyparse();
   /* print_symbol_table(); */
   std::string temp = "main";	
   if (!find_function(temp)) {
	serror("No main function defined.");
   }
   return 0;
}

void yyerror(const char *msg) {
     printf("**Syntax error at  line %d, position %d: %s\n", currLine, currPos, msg); 
}

void serror(const char *msg) {
     printf("**Semantic error at line %d, position %d: %s\n", currLine, currPos, msg);
}
