module imperative::Simpr
import ParseTree;
import IO;
import String;

start syntax SimprProgram
	= Def* Expr
	;
	
syntax Def 
	= Type Var "(" {Param ","}* ")" "{" Stat* "}" // function declaration
	| Type Var "=" Expr ";" // variable declaration (global)
	;
	
syntax Stat
	= IfThenElseStat: "if" Expr "then" Stat* "else" Stat* "end"
	| IfThenStat: "if" Expr "then" Stat* "end"
	| WhileStat: "while" Expr "do" Stat* "end"
	| DeclStat: Type Var "=" Expr ";"
	| left AssignStat:  Var "=" Expr ";"
	| ExprStat: Expr ";" // expression evaluated for its side-effect
	| BlockStat: "{" Stat* "}"
	| Return: "return" Expr ";"
	| EmptyStat: ";"
	;
start syntax Expr 
	=  "(" Expr ")"
//	> "-" Expr
	> Apply: Expr "(" {Expr ","}* ")"
	> IfExpr: "if" Expr "then" Expr "else" Expr "end"
	> left Expr "*" Expr
	> left (Expr "+" Expr
	     |  Expr "-" Expr)
	> left Expr "\<" Expr
	| Lambda: "(" {Param ","}* ")" "-\>" Expr
	| Var: Var name
	| Int: Num i
	;

syntax Type
	= "int"
	| {Type ","}* "-\>" Type
	;
	
syntax Param
	= Type typ Var var
	;
lexical Var = [a-zA-Z] !<< [a-zA-Z] [a-zA-Z0-9]* !>> [a-zA-Z];

lexical Num = [0-9]+;


layout LAYOUT = [\ \n\r\f\t]* !>> [\ \n\r\f\t];

anno str node@category;

data MyException = UnknownExpression(value v);


public SimprProgram parseSimpr(loc l) = parse(#start[SimprProgram], l).top;
public SimprProgram parseSimpr(str s) = parse(#start[SimprProgram], s).top;

