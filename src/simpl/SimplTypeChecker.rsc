module simpl::SimplTypeChecker
import ParseTree;
import IO;
import String;
import simpl::Simpl;
import simpl::SimplAST;

Type typecheck((Type)`int`) = Int();

Type typecheck((Type)`<Type t1> -\> <Type t2>`)
	= Fun(typecheck(t1), typecheck(t2));

default Type typecheck(Type t) { 
	throw Error("Unknown type <t>", t@\loc, Int());
}

tuple[ExprAST,Type] typecheckSimpl(loc file) {
	return typecheck(parse(#start[SimplProgram], file).top, ());
}

tuple[ExprAST,Type] typecheckSimpl(loc file, TCEnv env) {
	return typecheck(parse(#start[SimplProgram], file).top, env);
}

tuple[ExprAST,Type] typecheckSimpl(SimplProgram prog) {
	return typecheck(prog, ());
}

tuple[ExprAST,Type] typecheckSimpl((SimplProgram)`<Def* defs> <Expr e>`, TCEnv env) {
	list[DefAST] ds = [];
	
	for(def <- defs) {
		<def, env> = typecheckDef(def, env);
		ds += def;
	}		
	return ProgramAST(ds, typecheck(e, env));
}

tuple[DefAST,TCEnv] typecheckSimpl((Def)`<Type rTyp> <Var v>(<Type aTyp> <Var a>) = <Expr e>;`, TCEnv env) {
}

tuple[DefAST,TCEnv] typecheckSimpl((Def)`<Type rTyp> <Var v> = <Expr e>;`, TCEnv env) {
}

tuple[ExprAST,Type] typecheckSimpl((Expr)`(<Expr e>)`, TCEnv env) {
	return typecheck(e, env);
}

tuple[ExprAST,Type] typecheckOperator(str opName, Expr e1, Expr e2, TCEnv env) {
	<a1, t1> = typecheck(e1, env);
	<a2, t2> = typecheck(e2, env);
	if(t1 == Int() && t2 == Int())
		return <Apply(Builtin("int::<opName>"), [a1, a2]), Int()>;
	else if(t1 == String() && t2 == String())
		return <Apply(Builtin("string::append"),[a1, a2]), String()>;
	else {
	// Eventuelt:
	//    * throw feil
	//    * skriv ut feilmelding
	//    * returner feilmeldinger i en egen liste
		return Error("* expected int arguments", e@\loc) ;
	}
}

tuple[ExprAST,Type] typecheck(e : (Expr)`<Expr e1> + <Expr e2>`, TCEnv env) {
	return typecheckOperator("+", e1, e2, env);
}

tuple[ExprAST,Type] typecheck(e : (Expr)`<Expr e1> * <Expr e2>`, TCEnv env)
	= typecheckOperator("*", e1, e2, env);

tuple[ExprAST,Type] typecheck(e : (Expr)`<Expr e1> - <Expr e2>`, TCEnv env)
	= typecheckOperator("-", e1, e2, env);

tuple[ExprAST,Type] typecheck(e : (Expr)`<Expr e1> \< <Expr e2>`, TCEnv env)
	= typecheckOperator("\<", e1, e2, env);

tuple[ExprAST,Type] typecheck(fullE : (Expr)`if <Expr c> then <Expr t> else <Expr e> end`, TCEnv env) {
	<aC, tC> = typecheck(c, env);
	<a1,t1> = typecheck(t, env);
	<a2,t2> = typecheck(e, env);
	newNode = If(aC, a1, a2);
	
	if(tC == Int()) {
		if(t1 == t2) {
			return <newNode, t1>;
		}
		else {
			return <Error("Branches should have same type: <t1> != <t2>", fullE@\loc, newNode), t1>;
		}
	}
	else {
		return <Error("Condition should return int", c@\loc, newNode), t1>;
	}
}


tuple[ExprAST,Type] typecheck((Expr)`let <Var v> = <Expr e1> in <Expr e2> end`, TCEnv env) {
//	TCEnv localTCEnv = env; // begge to refererer til samme verdi
//	localTCEnv["<v>"] = typecheck(e1, env); // localTCEnv refererer til en ny map, med den ekstra bindingen – env er uendret
//	return typecheck(e2, localTCEnv);
	// dette funker like grei; endringen av "env" har ingen effekt utenfor
	// denne funksjonen
	
	<a1, t1> = typecheck(e1, env);
	env["<v>"] = t1;
	<a2, t2> = typecheck(e2, env);
	
	//if("<v>" in env) {
	//	return <Error("Redefined variable <v>", v@\loc, Let("<v>", a1, a2)), t2>;
	//}
	//else {
		return <Let("<v>", a1, a2), t2>;
	//}
}


tuple[ExprAST,Type] typecheck((Expr)`let <Type rt> <Var f>(<Type t> <Var a>) = <Expr e1> in <Expr e2> end`, TCEnv env) {
	// let twice(x) = x * x in twice(2) end
	argType = typecheck(t);
	retType = typecheck(rt);
	bodyEnv = env + ("<a>" : argType, "<f>" : Fun([argType], retType));
	<bodyAST, bodyType> = typecheck(e1, bodyEnv);

	env["<f>"] = Fun([argType], retType);
	<a2, t2> = typecheck(e2, env);
	
	if(retType == bodyType) {
		return <LetFun("<f>", [Param(argType, "<a>")], bodyAST, a2), t2>;
	}
	else {
		return <Error("Expected return type <retType>, got <bodyType>", rt@\loc, LetFun("<f>", [Param(argType, "<a>")], bodyAST, a2)), retType>;
	}
}

tuple[ExprAST,Type] typecheck((Expr)`<Expr f>(<Expr arg>)`, TCEnv env) {
	<funAST, funType> = typecheck(f, env);
	<inputAST, inputType> = typecheck(arg, env);
	
	if(Fun([argType], retType) := funType) {
		if(argType == inputType) {
			return <Apply(funAST, [inputAST]), retType>;
		}
		else {
			return <Error("Wrong argument type, expected <argType>", arg@\loc, Apply(funAST, [inputAST])), retType>;
		}
	}
	else {
		return <Error("Not a function: <f>", f@\loc, Apply(funAST, [inputAST])), funType>;
	}
}



tuple[ExprAST,Type] typecheck((Expr)`<Num a>`, TCEnv env) = <Int(toInt("<a>")), Int()>;

tuple[ExprAST,Type] typecheck((Expr)`<Var a>`, TCEnv env) {
	v = "<a>";
	if(v in env) {
		return <Var("<a>"), env[v]>;
	}
	else {
		return <Error("Undefined variable <v>", a@\loc, Var("<a>")), Int()>;
	}	
}

default tuple[ExprAST,Type] typecheck(Expr e, TCEnv env) {
	throw "Unknown expression <e>";
}

tuple[ExprAST,Type] typecheck(amb(alternatives), TCEnv env) {
	Type s = Int();
	for(alt <- alternatives) {
		s = s + "\n====\n<typecheck(alt, env)>\n====\n";
	}
	return Error("Ambiguity", |unknown://|);
}
