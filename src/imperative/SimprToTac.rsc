module imperative::SimprToTac
import ParseTree;
import IO;
import String;
import imperative::SimprAST;

alias LocEnv = map[str,Location];
alias TacCode = str;


public bool isSimple(Int(_)) = true;
public bool isSimple(Var(_,_)) = true;
public bool isSimple(Builtin(_)) = true;
public default bool isSimple(ExprAST e) = false;

public tuple[TacCode,LocEnv] compile(Program(list[DeclAST] decls, list[StatAST] stats), LocEnv env) {
	;
}

public tuple[TacCode,LocEnv] compile(FunDecl(str name, TypeAST retType, list[Param] params, list[StatAST] body), LocEnv env) {
	;
}


public tuple[TacCode,LocEnv] compile(VarDecl(str name, TypeAST typ, ExprAST init), LocEnv env) {
	;
}

public tuple[TacCode,LocEnv] compileStat(IfThenElseStat(ExprAST cond, list[StatAST] thenBranch, list[StatAST] elseBranch), LocEnv env) {
	<condOperand, condCode, env> = compileExpr(cond, "tmp", env);
	<thenCode, env1> = compileStat(thenBranch, env);
	<elseCode, env2> = compileStat(elseBranch, env);
	elseLabel = newLabel("else");
	return <"<condCode>\tunless <condOperand> goto <elseLabel>\n<thenCode><elseLabel>:\n<elseCode>", env>;
}


public tuple[TacCode,LocEnv] compileStat(IfThenStat(ExprAST cond, list[StatAST] thenBranch), LocEnv env) {
	<condOperand, condCode, env> = compileExpr(cond, "tmp", env);
	<thenCode, env1> = compileStat(thenBranch, env);
	elseLabel = newLabel("else");
	return <"<condCode>\tunless <condOperand> goto <elseLabel>\n<thenCode><elseLabel>:\n", env>;
}


public tuple[TacCode,LocEnv] compileStat(WhileStat(ExprAST cond, list[StatAST] body), LocEnv env) {
	<condOperand, condCode, env> = compileExpr(cond, "tmp", env);
	<bodyCode, env1> = compileStat(body, env);
	startLabel = newLabel("loop");
	endLabel = newLabel("end");
	return <"<startLabel>:<condCode>\tunless <condOperand> goto <endLabel>\n<bodyCode><endLabel>:\n", env>;
}


public tuple[TacCode,LocEnv] compileStat(DeclStat(str name, Location storeLoc, TypeAST typ, ExprAST init), LocEnv env) {
	str s = "var <name> : ";
	
	switch(typ) {
	case Int(): s += "int";
	case Fun(_,_): s += "ptr";
	default: "unknown type <typ>";
	}
	
	if(Local(l) := storeLoc) {
		s += "@<l>";
	}
	return "<s>\n<compileStat(AssignStat(name, storeLoc, init), env)>";
}


public tuple[TacCode,LocEnv] compileStat(AssignStat(str name, Location storeLoc, ExprAST expr), LocEnv env) {
	// compile expression, ask that result is placed in <name>
	<exprResult, exprCode, env> = compileExpr(expr, name, env);
	
	// if result was actually placed in <name>, we don't need to do anything
	if(exprResult == name) {
		return <exprResult, env>;
	}
	else { // otherwise, do computation and assignment
		return <"<exprCode>\t<name> = <exprResult>\n", env>;
	}	
}


public tuple[TacCode,LocEnv] compileStat(ReturnStat(ExprAST expr, Location storeLoc), LocEnv env) {
	// returning a value is the same as:
	// - assigning the return value to __return
	<resultCode,env> = compileStat(AssignStat("__return", storeLoc, expr));
	// - then returning
	return <"<resultCode>return\n", env>;
}


public tuple[TacCode,LocEnv] compileStat(ExprStat(ExprAST expr), LocEnv env) {
	// we're not actually using the value of the expression, just computing it
	<exprResult, exprCode, env> = compileExpr(expr, "tmp", env);
	return <exprCode, env>;
}


public tuple[TacCode,LocEnv] compileStat(BlockStat(list[StatAST] body), LocEnv env) {
	str blockCode = "";
	blockEnv = env;
	for(s <- body) {
		<code, blockEnv> = compileStat(body, blockEnv);
		blockCode += code;
	}
	return <blockCode, env>;
}


public tuple[TacCode,LocEnv] compileStat(ErrorStat(str msg, loc location, StatAST stat), LocEnv env) {
	throw "Unresolved compilation error: <msg>";
}



	
public tuple[str,TacCode,LocEnv] compileExpr(Int(int i), str dest, LocEnv env) {
	return <"<i>", "", env>;
}


public tuple[TacCode,LocEnv] compileExpr(Var(str name, Location storeLoc), LocEnv env) {
	return <"<name>", "", env>;
}

public tuple[TacCode,LocEnv] compileExpr(Apply(Builtin(op), list[ExprAST] args), str dest, LocEnv env) {
	str code = "";
	<funOperand, funCode, env> = compileExpr(f, "fun", env);
	code += funCode;
	list[str] arguments = [];
	for(a <- args) {
		str argName = newName("a");
		<argName, argCode, env> = compileExpr(a, argName, env);
		arguments += argName;
		code += argCode;
	}
	if(size(args) == 1) {
		return "<code>\t<dest> = <op> <arguments[0]>";
	}
	else if(size(args) == 2) {
		return "<code>\t<dest> = <arguments[0]> <op> <arguments[1]>";
	} 
	else {
		throw "wrong number of arguments for a built-in operator: <size(args)>";
	}
}

public tuple[TacCode,LocEnv] compileExpr(Apply(ExprAST f, list[ExprAST] args), LocEnv env) {
	str code = "";
	<funOperand, funCode, env> = compileExpr(f, "fun", env);
	code += funCode;
	list[str] arguments = [];
	for(a <- args) {
		str argName = newName("a");
		<argName, argCode, env> = compileExpr(a, argName, env);
		arguments += argName;
		code += argCode;
	}
	return "<code>\tcall <funOperand>(<intercalate(", ", arguments)>)\n";
}


public tuple[TacCode,LocEnv] compileExpr(If(ExprAST cond, ExprAST thenBranch, ExprAST elseBranch), LocEnv env) {
	;
}


public tuple[TacCode,LocEnv] compile(Lambda(list[Param] params, ExprAST body), LocEnv env) {
	;
}


public tuple[TacCode,LocEnv] compile(Builtin(str name), LocEnv env) {
	;
}


public tuple[TacCode,LocEnv] compile(ErrorExpr(str msg, loc location, ExprAST expr), LocEnv env) {
	;
}

int i = 0;
public str newTmp() = newTmp("t");

public str newTmp(str s) {
	n = "<s><i>";
	i = i + 1;
	return n;
}
