module simpl::Simpl
import ParseTree;
import IO;
import String;

start syntax SimplProgram
	= Def* Expr
	;
	
syntax Def 
	= Type Var "(" Type Var ")" "=" Expr ";"
	| Type Var "=" Expr ";"
	;
	
start syntax Expr 
	=  "(" Expr ")"
	// X > Y means the X has a high priority that Y 
	> Apply: Expr "(" Expr ")"
	// left means that the operator is left associative
	> left Expr "*" Expr
	> left (Expr "+" Expr  // + and - are mutually left associative
	       |Expr "-" Expr)
	> left Expr "\<" Expr
	> "if" Expr "then" Expr "else" Expr "end"
	| Let: "let" Var name "=" Expr init "in" Expr body "end"
	| LetFun: "let" Type retType Var name "(" Type argType Var arg ")" "=" Expr init "in" Expr body "end"
	| Lambda: "(" Var ")" "-\>" Expr
	| Var name
	| Int: Num i
	;

syntax Type
	= "int"
	| Type "-\>" Type
	;
	
lexical Var = [a-zA-Z] !<< [a-zA-Z]+ !>> [a-zA-Z];

lexical Num = [0-9]+;


layout LAYOUT = [\ \n\r\f\t]* !>> [\ \n\r\f\t];

anno str node@category;

data MyException = UnknownExpression(value v);

Expr addParens(Expr t) = bottom-up visit(t) {
	case (Expr)`<Num e>`: ;
	case (Expr)`<Var e>`: ;
	case (Expr)`<Expr e>` => (Expr)`(<Expr e>)`
//	case appl(prod(sort(/.*[Ee]xpr.*/), _, _), _): ;
};

Expr partEval(Expr t) = bottom-up visit(t) {
	case (Expr)`<Expr a> + 0` => a
	case (Expr)`<Num a> + <Num b>`: {
		int c = toInt("<a>") + toInt("<b>");
		insert parse(#Expr, "<c>");
	}
	case (Expr)`<Num a> * <Num b>`: {
		int c = toInt("<a>") * toInt("<b>");
		insert parse(#Expr, "<c>");
	}
	case (Expr)`if <Num c> then <Expr th> else <Expr el> end`: {
		if(toInt("<c>") != 0) {
			insert th;
		}
		else {
			insert el;
		}
	}
};

/*
Expr desugar(Expr e) {
	return visit(e) {
	case (Expr)`(<Var v>) -\> <Expr body>`
		=> (Expr)`let int FOO(int <Var v>) = <Expr body> in FOO end`
	}
}
*/

public bool parses(str s) = parse(#start[SimplProgram], s)?;
public SimplProgram parseSimpl(loc l) = parse(#start[SimplProgram], l).top;
public SimplProgram parseSimpl(str s) = parse(#start[SimplProgram], s).top;

