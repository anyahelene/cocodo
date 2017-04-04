module simpl::Simpl
import String;
import ParseTree;
import IO;
start syntax Program = Expr;

syntax Expr
	= Var: ID                  // variables
	| Num: NUM                 // integers
	// left associative: a+b+c is interpreted as ((a+b)+c)
	| left (
		Times: Expr "*" Expr       // multiplication
	  | Div: Expr "/" Expr
	  )
	// priority: "Expr = Expr * Expr > Expr + Expr" 
	//           means a+b*c is interpreted as (a+(b*c))
	> left Plus: Expr "+" Expr       // addition
	| Assign: ID "=" Expr
	| left Seq: Expr ";" Expr
	| Let: "let" ID "=" Expr "in" Expr "end"    // let x = 2+2 in x*2 end
	| LetFun: "let" ID "(" Type ID ")" "=" Expr "in" Expr "end"
	| Appl: ID "(" Expr ")"     // function call
	| "(" Expr ")"        // parentheses
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

// Types:
//   Program
//   Expr -- can be a Program
//   ID -- can be Expr
//   NUM -- can be Expr


// Concrete Syntax Patterns:
//   Form: (NonTerminal)`...`
//   Patterns:
//      * something which is valid in the language, for that non-terminal 2+2, a, f(2)
//      * <NonTerminal VariableName> -- will match anything of that non-terminal type
//         -- <NUM a> - any number (according to the rule for NUM) (this is an expression)
//              (Expr)`<NUM a>` will match (Expr)`2`, (Expr)`123456`
//         -- <NUM a> with an existing variable:
//                if we do: a = (NUM)`2`
//                then (Expr)`<NUM a>` will match (Expr)`2` but not (Expr)`123456`
//         -- can occur anywhere NonTerminal is legal in the language
//  Patterns are used in:
//      * Argument lists
//      * switch and visit statements
//      * with the match operator:   pattern := value
//  There are also other forms of patterns, such as regular expressions, and
//  structural patterns
// in the case of argument lists, we are doing *matching*, and the variables
// get the value of whatever they matched in the tree

//alias Value = int;
alias Name = str;
data Value = Int(int i)
           | Fun(Name arg, Expr e, Env env);
alias Env = map[Name,Value];

public int eval( (Expr)`<NUM a>`, Env env ) {
	ae = toInt("<a>"); // "<a>" is used to convert a to a string
	return ae;
}

public int eval((Expr)`<Expr a>+<Expr b>`, Env env) {
	return eval(a,env)+eval(b,env);
}

public int eval((Expr)`<Expr a>*<Expr b>`, Env env) {
	return eval(a,env)*eval(b,env);
}


public int eval((Expr)`(<Expr a>)`, Env env) {
	return eval(a,env);
}

public default int eval(Expr e, Env env) {
	if(amb(_) := e)
		throw "Ambiguous expression <e>";
	else
		throw "Unknown expression <e>";
}

public int eval((Expr)`<ID f>(<Expr a>)`, Env env) {
	Value fun = env["<f>"];
	if(Fun(param, expr, staticEnv) := fun) {
		// result is result of expr with param = arg


		println("Argument evaluted in:");
		printenv(env);
		int arg = eval(a, env);
		
		println("<param> = <arg> in <unparse(expr)>");
	
		funEvalEnv = staticEnv;
		funEvalEnv[param] = Int(arg);
	
		println("Body evaluated in:");
		printenv(funEvalEnv);

		return eval(expr, funEvalEnv);
	}
	return 0;
}

public int eval((Expr)`<ID v>`, Env env) {
	Name n = "<v>";
	
	if(n in env) {
		Value val = env[n];  // a ? x gives x if a throws an exception
		// vil være enten Int(...) eller Fun(...,...)
		println("<n> = <val>");
		if(Int(i) := val) {
			return i;
		}
		else if(Fun(f,e,_) := val) {
			throw "Cannot use function as a value: x =\> <unparse(e)>";
		}
	}
	else {
		throw "Unknown variable: <n>";
	}
}

public int eval((Expr)`let <ID v> = <Expr e1> in <Expr e2> end`, Env env) {
	// evaluer e1
	// tilordne variabel
	// evaluer e2, i en kontekst hvor variabelen v har verdien til e1
	
	Name n = "<v>";
	int i = eval(e1, env);
	println("Environment before:");
	printenv(env);
	
	env[n] = Int(i);
	println("Environment inside let body:");
	printenv(env);
	return eval(e2, env);
}

public int eval((Expr)`let <ID f>(<Type t> <ID v>) = <Expr e1> in <Expr e2> end`, Env env) {
	// lagre e1, og argumentet v
	// tilordne variabel f
	// evaluer e2, i en kontekst hvor variabelen v har verdien til e1
	
	// 1) evaluer det vi kan av e1 (uten å bruke parameteret), og bruk
	// det som kroppen til funksjonen
	// 2) lagre hele miljøet slik det var når f ble definert
	
	env["<f>"] = Fun("<v>", e1, env);
	return eval(e2, env);
}


public int eval((Program)`<Expr e>`, Env env) {
	return eval(e, env);
}

// visit(..) { ... } visits every node in the tree and
// * matches cases against each node
// * you can replace the node with a node of the same type

public Expr eval2(Expr e) {
	return bottom-up visit(e) {
		case Expr x: {
			println(x);
			fail;
		}
/*
	case (Expr)`<NUM a>+<NUM b>`: { // match and do something
		result = "<toInt("<a>")+toInt("<b>")>";
		insert parse(#Expr, result); // replace
	}
	// match and replace
	case (Expr)`<NUM a>*<NUM b>` => parse(#Expr, "<toInt("<a>")*toInt("<b>")>")
*/
	}
}

public void printenv(Env env) {
	println("{");
	for(k <- env) {
		switch(env[k]) {
		case Int(i): println("  <k> = <i>");
		case Fun(a,b,_): println("  <k>(<a>) = <unparse(b)>");
		}
	}
	println("}");
}
