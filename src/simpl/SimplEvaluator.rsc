module simpl::SimplEvaluator
import ParseTree;
import IO;
import String;
import simpl::Simpl;


data Value
	= Fun(str funName, str arg, Expr body, Env defEnv)
	| Int(int i)
	| Str(str s)
	;

alias Env = map[str, Value];

tuple[Value,Type] evalSimpl(loc file) {
	return evalSimpl(parse(#start[SimplProgram], file).top, ());
}

tuple[Value,Type] evalSimpl(loc file, Env env) {
	return evalSimpl(parse(#start[SimplProgram], file).top, env);
}

tuple[Value,Type] evalSimpl(SimplProgram prog) {
	return evalSimpl(prog, ());
}

tuple[Value,Type] evalSimpl((SimplProgram)`<Def* defs> <Expr e>`, Env env) {	
	for(def <- defs) {
		env = evalDef(def, env);
	}		
	return eval(e, env);
}

Env evalDef((Def)`<Type rTyp> <Var v>(<Type aTyp> <Var a>) = <Expr e>;`, Env env) {
	throw "Not implemented yet!";
}

Env evalDef((Def)`<Type rTyp> <Var v> = <Expr e>;`, Env env) {
	throw "Not implemented yet!";
}



Value eval((Expr)`(<Expr e>)`, Env env) {
	return eval(e, env);
}

Value eval(e:(Expr)`<Expr e1> * <Expr e2>`, Env env) {
	s1 = eval(e1, env);
	s2 = eval(e2, env);
	if(Int(_) := s1 && Int(_) := s2)
		return Int(s1.i * s2.i);
	else
		throw "Both arguments should be integers: <e@\loc>";
}

Value eval((Expr)`<Expr e1>+<Expr e2>`, Env env) {
	return Int(eval(e1, env).i + eval(e2, env).i);
}

Value eval((Expr)`<Expr e1> \< <Expr e2>`, Env env)
	= Int(eval(e1, env).i < eval(e2, env).i ? 1 : 0);

Value eval((Expr)`if <Expr c> then <Expr t> else <Expr e> end`, Env env) 
	= eval(c, env).i != 0 ? eval(t, env) : eval(e, env);


Value eval((Expr)`let <Var v> = <Expr e1> in <Expr e2> end`, Env env) {
//	Env localEnv = env; // both refer to same value
//	localEnv["<v>"] = eval(e1, env); // localEnv refers to a new map, with the extra binding, env is unchanged
//	return eval(e2, localEnv);
	// this is just as good, the change to "env" has no effect outside this function
	env["<v>"] = eval(e1, env);
	return eval(e2, env);
}

// 
Value eval((Expr)`let <Type t> <Var f>(<Type at> <Var a>) = <Expr e1> in <Expr e2> end`, Env env) {
	env["<f>"] = Fun("<f>", "<a>", e1, env);
	return eval(e2, env);
}

Value eval((Expr)`(<Var v>) -\> <Expr body>`, Env env) {
	return Fun("lambda", "<v>", body, env);
}

Value eval((Expr)`<Expr f>(<Expr arg>)`, Env env) {
	//v = "<f>";
	Value fun = eval(f, env);
	Value input = eval(arg, env);
	//if(v in env) {
		if(Fun(funName, paramName, body, Env defEnv) := fun) {
			defEnv[paramName] = input;
			return eval(body, defEnv);
		}
		else {
			throw "not a function: <f>";
		}
//	}
//	else
//		throw "Undefined function <v>";	
}


//// Bad idea – the "other" may contain errors and should not be evaluated
//Value eval((Expr)`if <Expr c> then <Expr t> else <Expr e> end`, Env env) { 
//	cv = eval(c);
//	tv = eval(t);
//	ev = eval(e);
//	return cv != 0 ? tv : ev;
//}
//Value eval((Expr)`if <Expr c> then <Expr t> else <Expr e> end`, Env env) {
//	if(eval(c) != 0) {
//		return eval(t);
//	}
//	else {
//		return eval(e);
//	}
//}

Value eval((Expr)`<Num a>`, Env env) = Int(toInt("<a>"));

Value eval((Expr)`<Var a>`, Env env) {
	v = "<a>";
	if(v in env) {
		return env[v];
	}
	else
		throw "Undefined variable <v>";	
}

default Value eval(Expr e, Env env) {
	if(amb(alternatives) := e) {
		str s = "";
		for(Expr a <- alternatives) {
			s = s + "\n====\n<eval(a, env)>\n====\n";
		}
		return Str(s);
	}
	else
		throw "Unknown expression <e>";
}
