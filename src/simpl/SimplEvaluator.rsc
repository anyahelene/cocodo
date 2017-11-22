module simpl::SimplEvaluator
import simpl::Simpl;
import String;
import ParseTree;
import IO;

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

public Value eval( (Expr)`<NUM a>`, Env env ) {
	int ae = toInt(unparse(a)); // "<a>"); // "<a>" is used to convert a to a string
	return Int(ae);
}

public Value eval((Expr)`<Expr a>+<Expr b>`, Env env) {
	return Int( eval(a,env).i + eval(b,env).i );
}

public Value eval((Expr)`<Expr a>*<Expr b>`, Env env) {
	return Int(eval(a,env).i*eval(b,env).i);
}


public Value eval((Expr)`(<Expr a>)`, Env env) {
	return eval(a,env);
}

public default Value eval(Expr e, Env env) {
	if(amb(_) := e)
		throw "Ambiguous expression <e>";
	else
		throw "Unknown expression <e>";
}

public Value eval((Expr)`<ID f>(<Expr a>)`, Env env) {
	Value fun = env["<f>"];
	if(Fun(param, expr, staticEnv) := fun) {
		// result is result of expr with param = arg


		println("Argument evaluted in:");
		printenv(env);
		Value arg = eval(a, env);
		
		println("<param> = <arg> in <unparse(expr)>");
	
		funEvalEnv = staticEnv;
		funEvalEnv[param] = arg;
	
		println("Body evaluated in:");
		printenv(funEvalEnv);

		return eval(expr, funEvalEnv);
	}
	else {
		throw "not a function: <fun>";
	}
}

public Value eval((Expr)`<ID v>`, Env env) {
	Name n = "<v>";
	
	if(n in env) {
		Value val = env[n];  // a ? x gives x if a throws an exception
		// will be either Int(...) or Fun(...,...)
		println("<n> = <val>");
		return val;
	}
	else {
		throw "Unknown variable: <n>";
	}
}


public Value eval((Expr)`let <ID v> = <Expr e1> in <Expr e2> end`, Env env) {
	// evaluate e1
	// assigne variable
	// evaluate e2, in a context where the variable v has the value of e1
	
//	a = [[]];
	Name n = "<v>";
	int i = eval(e1, env).i;
	println("Environment before:");
	printenv(env);
//	a[-1];
//	a += [];
	env[n] = Int(i);
	println("Environment inside let body:");
	printenv(env);
	return eval(e2, env);
}

public Value eval((Expr)`let <ID f>(<Type t> <ID v>) = <Expr e1> in <Expr e2> end`, Env env) {
	// store e1 and the parameter name v as a function data structure
	// assign to variable f
	// evaluate e2, in a context where f is bound to the function
	
	// for lexical scoping, we need to store the environment at the point of definition 
	
	env["<f>"] = Fun("<v>", e1, env);
	return eval(e2, env);
}


public Value eval((SimplProgram)`<Expr e>`, Env env) {
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
