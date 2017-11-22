module simpl::Simpl
import String;
import ParseTree;


start syntax SimplProgram = Expr;

syntax Expr
	= Var: ID                  // variables
	| Num: NUM                 // integers
	// left associative: a+b+c is interpreted as ((a+b)+c)
	| left (
		Times:  Expr "*" Expr       // multiplication
	  | Div:    Expr "/" Expr
	  )
	// priority: "Expr = Expr * Expr > Expr + Expr" 
	//           means a+b*c is interpreted as (a+(b*c))
	> Plus:  Expr "+" Expr       // addition
	> Minus: Expr "-" Expr       // addition
	| Let:       "let" ID "=" Expr "in" Expr "end"    // let x = 2+2 in x*2 end
	| LetFun:    "let" ID "(" Type ID ")" "=" Expr "in" Expr "end"
	| If:		 "if" Expr "then" Expr "else" Expr "end"
	| Appl:      ID "(" Expr ")"     // function call
	|            "(" Expr ")"        // parentheses
	;
	
syntax Type
	= ID
	| Type "(" Type ")"
	;
	
// identifiers
//    y !<< x means 'x' must not be preceeded by  'y'
//    x !>> y means 'x' must not by followed by 'y'
// so, this means that an identifier is a sequence of one
// or more letters or underscores, with no additional
// letters or underscores before or after
lexical ID = [a-zA-Z_] !<< [a-zA-Z_]+ !>> [a-zA-Z_];

// numbers
lexical NUM = [0-9] !<< [0-9]+ !>> [0-9];

// whitespace: this non-terminal is inserted *between* all terminals and
// non-terminals in all syntax productions (does not apply to lexical
// productions)
layout WS = [\ \n\r\f]*;

// Each grammar non-terminal corresponds to a type, in this case we have:
//   Program
//   Expr -- can be a Program
//   ID -- can be Expr
//   NUM -- can be Expr



public SimplProgram parseSimplProgram(str s) {
  return parse(#start[SimplProgram], s).top;
}

public SimplProgram parseSimplProgram(loc l) {
  return parse(#start[SimplProgram], l).top;
}

