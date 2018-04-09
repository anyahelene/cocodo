module simpl::SimplEvaluator
import ParseTree;
import IO;
import String;
import simpl::Simpl;

data Value
	= Fun(str funName, str arg, Expr body, Env defEnv)
	| Int(int i)
	;

alias Env = map[str, Value];

tuple[Value,Type] evalSimpl(loc file) {
	return eval(parse(#start[SimplProgram], file).top, ());
}

tuple[Value,Type] typecheckSimpl(loc file, Env env) {
	return eval(parse(#start[SimplProgram], file).top, env);
}

tuple[Value,Type] typecheckSimpl(SimplProgram prog) {
	return eval(prog, ());
}

tuple[Value,Type] evalSimpl((SimplProgram)`<Def* defs> <Expr e>`, Env env) {
	list[DefAST] ds = [];
	
	for(def <- defs) {
		env = evalDef(def, env);
		ds += def;
	}		
	return ProgramAST(ds, typecheck(e, env));
}

Env evalSimpl((Def)`<Type rTyp> <Var v>(<Type aTyp> <Var a>) = <Expr e>;`, Env env) {
}

Env evalSimpl((Def)`<Type rTyp> <Var v> = <Expr e>;`, Env env) {
}

Value eval(amb(alternatives), Env env) {
	Value s = "";
	for(alt <- alternatives) {
		s = s + "\n====\n<eval(alt, env)>\n====\n";
	}
	return s;
}


Value eval((Expr)`(<Expr e>)`, Env env) {
	return eval(e, env);
}

Value eval((Expr)`<Expr e1> * <Expr e2>`, Env env) {
	s1 = eval(e1, env);
	s2 = eval(e2, env);
	return Int(s1.i * s2.i);
}

Value eval((Expr)`<Expr e1>+<Expr e2>`, Env env) {
	return Int(eval(e1, env).i + eval(e2, env).i);
}

Value eval((Expr)`<Expr e1> - <Expr e2>`, Env env) = Int(eval(e1, env).i - eval(e2, env).i);

Value eval((Expr)`<Expr e1> \< <Expr e2>`, Env env) = Int(eval(e1, env).i < eval(e2, env).i ? 1 : 0);

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

Value eval((Expr)`let <Type t> <Var f>(<Type at> <Var a>) = <Expr e1> in <Expr e2> end`, Env env) {
	env["<f>"] = Fun("<f>", "<a>", e1, env);
	return eval(e2, env);
}

Value eval((Expr)`<Expr f>(<Expr arg>)`, Env env) {
	//v = "<f>";
	fun = eval(f, env);
	input = eval(arg, env);
	//if(v in env) {
		if(Fun(funName, paramName, body, defEnv) := fun) {
			env2 = defEnv;
			env2[paramName] = input;
			env2[funName] = fun;
			return eval(body, env2);
		}
		else {
			throw "not a function: <v>";
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
	throw "Unknown expression <e>";
}
