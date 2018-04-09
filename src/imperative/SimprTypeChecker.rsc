module imperative::SimprTypeChecker
import ParseTree;
import IO;
import String;
import imperative::Simpr;
import imperative::SimprAST;


alias TCSEnv = map[str, tuple[TypeAST, Location]];

TypeAST typecheck((Type)`int`, TCSEnv env) = imperative::SimprAST::Int();

TypeAST typecheck((Type)`<{Type ","}* t1> -\> <Type t2>`, TCSEnv env)
	= Fun([typecheck(t) | t <- t1], typecheck(t2));

// here we could to type checking of user-defined types, e.g.:
/*TypeAST typecheck(t:(Type)`<Var n>`, TCSEnv env) {
	if("<n>" in env) {
		return env["<n>"];
	}
	else {
		return Error("Unknown type <n>", t@\loc, Int()); 
	}
}*/
default TypeAST typecheck(Type t, TCSEnv env) { 
	throw "Unknown type <t>, <t@\loc>";
}


public tuple[ProgramAST,set[Message]] typecheck((SimprProgram)`<Def* defs> <Expr e>`) {
	TCSEnv env = ("__next_global_loc": <Int(),Global(0)>);
	for(d <- defs) {
		env = loadDecl(d, env);
	}
	//list[StatAST] ss;
	ss =
	for(d <- defs) {
		append typecheckDef(d, env);
	}
	
	ast = Program(ss, [ExprStat(typecheck(e, env)[0])]);
	set[Message] errs = {};
	visit(ast) {
		case ErrorExpr(s, l, _): errs += error(s,l);
		case ErrorStat(s, l, _): errs += error(s,l);
		case ErrorType(s, l, _): errs += error(s,l);
	}
	
	return <ast,errs>;
}
tuple[ExprAST,TypeAST] typecheck((Expr)`(<Expr e>)`, TCSEnv env) {
	return typecheck(e, env);
}

tuple[ExprAST,TypeAST] typecheckOperator(str opName, Expr e1, Expr e2, TCSEnv env) {
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
		return ErrorExpr("* expected int arguments", e@\loc,Apply(Builtin("int::<opName>"), [a1, a2])) ;
	}
}

tuple[ExprAST,TypeAST] typecheck(e : (Expr)`<Expr e1> + <Expr e2>`, TCSEnv env) {
	return typecheckOperator("+", e1, e2, env);
}

tuple[ExprAST,TypeAST] typecheck(e : (Expr)`<Expr e1> * <Expr e2>`, TCSEnv env)
	= typecheckOperator("*", e1, e2, env);

tuple[ExprAST,TypeAST] typecheck(e : (Expr)`<Expr e1> - <Expr e2>`, TCSEnv env)
	= typecheckOperator("-", e1, e2, env);

tuple[ExprAST,TypeAST] typecheck(e : (Expr)`<Expr e1> \< <Expr e2>`, TCSEnv env)
	= typecheckOperator("\<", e1, e2, env);

tuple[ExprAST,TypeAST] typecheck(fullE : (Expr)`if <Expr c> then <Expr t> else <Expr e> end`, TCSEnv env) {
	<aC, tC> = typecheck(c, env);
	<a1,t1> = typecheck(t, env);
	<a2,t2> = typecheck(e, env);
	newNode = If(aC, a1, a2);
	
	if(tC == Int()) {
		if(t1 == t2) {
			return <newNode, t1>;
		}
		else {
			return <ErrorExpr("Branches should have same type: <t1> != <t2>", fullE@\loc, newNode), t1>;
		}
	}
	else {
		return <ErrorExpr("Condition should return int", c@\loc, newNode), t1>;
	}
}


tuple[ExprAST,TypeAST] typecheck((Expr)`<Expr f>(<{Expr ","}* args>)`, TCSEnv env) {
	<funAST, funType> = typecheck(f, env);
	checkedArgs = [typecheck(arg, env) | arg <- args];
	argTypes = [t | <a,t> <- checkedArgs];
	argASTs = [a | <a,t> <- checkedArgs];
	
	if(Fun(paramTypes, retType) := funType) {
		newNode = Apply(funAST, argASTs);
	
		if(size(checkedArgs) != size(paramTypes)) {
			return <ErrorExpr("Wrong number of arguments, expected <size(paramTypes)>, got <size(checkedArgs)>", f@\loc, newNode), retType>;
		}

		for(i <- [0..size(argTypes)]) {
			if(argTypes[i] != paramTypes[i]) {
				return <ErrorExpr("Wrong argument type, expected <paramTypes[i]>, got <argTypes[i]>", arg@\loc, newNode), retType>;		
			}				
		}
		
		return <newNode, retType>;
	}
	else {
		return <ErrorExpr("Not a function: <f>", f@\loc, funAST), funType>;
	}
}



tuple[ExprAST,TypeAST] typecheck((Expr)`<Num a>`, TCSEnv env) = <Int(toInt("<a>")), Int()>;



tuple[ExprAST,TypeAST] typecheck((Expr)`<Var a>`, TCSEnv env) {
	v = "<a>";
	if(v in env) {
		<t,l> = env[v];
		return <Var("<a>", storeLoc = l), t>;
	}
	else {
		return <ErrorExpr("Undefined variable <v>", a@\loc, Var("<a>")), Int()>;
	}	
}

default tuple[ExprAST,TypeAST] typecheck(Expr e, TCSEnv env) {
	throw "Unknown expression <e>";
}

tuple[StatAST,TCSEnv] typecheck(fullS : (Stat)`if <Expr c> then <Stat* thens> else <Stat* elses> end`, TCSEnv env) {
	<condAST, condType> = typecheck(c, env);
	
	<thenASTs, tEnv> = typecheck([s | s <- thens], env);
	<elseASTs, eEnv> = typecheck([s | s <- elses], env);
	
	// we can now do a "meet" of the two environments tEnv and eEnv, and combine the results
	// (e.g., if we're counting the number of storage locations needed)
	
	newNode = IfThenElseStat(condAST, thenASTs, elseASTs);
	
	if(condType == Int()) {
		return <newNode, env>;
	}
	else {
		return <ErrorStat("Condition should return int", c@\loc, newNode), env>;
	}
}

tuple[StatAST,TCSEnv] typecheck((Stat)`<Type t> <Var v> = <Expr e1>;`, TCSEnv env) {
	declType = typecheck(t);
	<initAST, initType> = typecheck(e1, env);
	

	<_,Local(l)> = env["__next_loc"];
	env["<v>"] = <declType, Local(l)>;
	env["__next_loc"] = <Int(), Local(l+1)>;
	
	newNode = DeclStat("<v>", declType, initAST, storeLoc = l);
	if(declType == initType) {
		return <newNode, env>;
	}
	else {
		return <ErrorStat("Type of initialiser <initType> not compatible with type of variable <declType>", e1@\loc, newNode), env>;
	}
}

tuple[StatAST,TCSEnv] typecheck((Stat)`{<Stat* stats>}`, TCSEnv env) {
	return typecheck([s | s <- stats], env);
}

tuple[list[StatAST],TCSEnv] typecheck(list[Stat] stats, TCSEnv env) {
	statASTs = for(s <- stats) {
		<statAST, env> = typecheck(s, env);
		append statAST;
	}
	return <statASTs, env>;
}
tuple[StatAST,TCSEnv] typecheck((Stat)`<Expr e1>;`, TCSEnv env) {
	<exprAST, exprType> = typecheck(e1, env);
	return <ExprStat(exprAST), env>;
}

tuple[StatAST,TCSEnv] typecheck((Stat)`return <Expr e1>;`, TCSEnv env) {
	<exprAST, exprType> = typecheck(e1, env);
	<retType, retLoc> = env["__return"];
	newNode = ReturnStat(exprAST, storeLoc = retLoc);
	if(retType == exprType) {
		return <newNode, env>;
	}
	else {
		return <Error("Expected return value of type <retType>, got <exprType>", e1@\loc, newNode), env>;
	}
}

tuple[StatAST,TCSEnv] typecheck((Stat)`<Var v> = <Expr e1>;`, TCSEnv env) {
	<exprAST, exprType> = typecheck(e1, env);
	if("<v>" in env) {
		<varType, varLoc> = env["<v>"];
		newNode = AssignStat("<v>", exprAST, storeLoc = l);
		if(exprType == varType) {
			return <newNode, env>;
		}
		else {
			return <ErrorStat("Type <exprType> not compatible with type of variable <varType>", e1@\loc, newNode), env>;
		}
	}
	else {
		return <ErrorStat("Unknown variable <v>", v@\loc, ExprStat(exprAST)), env>;
	}
}

public TCSEnv loadDecl((Def)`<Type rt> <Var f>(<{Param ","}* ps>) { <Stat* body> }`, TCSEnv env) {
	retType = typecheck(rt, env);
	list[Param] params = [Param(typecheck(t, env), "<v>") | (Param)`<Type t> <Var v>` <- ps];

	<_, Global(l)> = env["__next_global_loc"];
	env["__next_global_loc"] = <Int(), Global(l+1)>;
	env["<f>"] = <Fun([t | Param(t,_) <- params], retType), Global(l)>;
	return env;
}

public TCSEnv loadDecl((Def)`<Type typ> <Var v> = <Expr e>;`, TCSEnv env) {
	varType = typecheck(typ);
	<_, Global(l)> = env["__next_global_loc"];
	env["__next_global_loc"] = <Int(), Global(l+1)>;
	env["<v>"] = <varType, Global(l)>;
	return env;
}

public DeclAST typecheckDef((Def)`<Type rt> <Var f>(<{Param ","}* ps>)  { <Stat* body> }`, TCSEnv env) {
	retType = typecheck(rt, env);
	list[Param] params = [Param(typecheck(t, env), "<v>") | (Param)`<Type t> <Var v>` <- ps];

	int l = -size(params);
	for(Param(t,n) <- params) {
		env[n] = <t, Local(l)>;
		l = l + sizeOf(t);
	}

	// We can also set aside space for the return value in the local storage area (on
	// the stack). At the very least, we should have the expected return type in the
	// environment, so we can check that return values are type correct.
	 
	env["__return"] = <retType, Local(l)>;
	l = l + sizeOf(Fun([],Int())); 
	
	// function itself is already in the environment, because all global definitions
	// have already been processed with loadDef()
	
	// finally, we make a note of where new local variables should be placed.
	env["__next_loc"] = <Int(), Local(l)>;


	<bodyASTs, _> = typecheck([s | s <- body], env);
	
	//maxLoc = max([l | /Var(_, Local(l)) <- bodyAST]);
	
	return FunDecl("<f>", retType, params, bodyASTs);
}
	
public DeclAST typecheckDef((Def)`<Type typ> <Var v> = <Expr e>;`, TCSEnv env) {
	<initAST, _> = typecheck((Stat)`<Var v> = <Expr e>;`, env);
	<varType,varLoc> = env["<v>"];
	<exprAST, exprType> = typecheck(e, env);
	return VarDecl("<v>", varType, exprAST);
}

tuple[ExprAST,TypeAST] typecheck(amb(alternatives), TCSEnv env) {
	TypeAST s = Int();
	for(alt <- alternatives) {
		s = s + "\n====\n<typecheck(alt, env)>\n====\n";
	}
	return Error("Ambiguity", |unknown://|);
}
