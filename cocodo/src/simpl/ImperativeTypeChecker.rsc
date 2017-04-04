module ImperativeTypeChecker
import Simple;
import ImperativeAST;
import IO;
import String;
import ParseTree;

alias Name = str;

alias TcEnv = map[Name,tuple[Type, Store]];

int nameCounter = 0;

public int newName() {
	int r = nameCounter;
	nameCounter = nameCounter + 1;
	return r;
}

int storeCounter = 0;

public int newStore() {
	int r = storeCounter;
	storeCounter = storeCounter + 1;
	return r;
}


public tuple[ImpExprTree, Type] typecheck( (Expr)`<NUM a>`, TcEnv env ) {
	return <Int(toInt("<a>")), Int()>;
}

public tuple[ImpExprTree, Type] typecheck((Expr)`<Expr a>+<Expr b>`, TcEnv env) {
	<aTree, aType> = typecheck(a,env);
	<bTree, bType> = typecheck(b,env);
	
	if(<Int(), Int()> := <aType, bType>) {
		return <Plus(aTree, bTree), Int()>;
	}
	/*
	else if(<Str(), Str()> := <aType, bType>) { // string concatenation
		return Str();
	}
	else if(<Str(), _> := <aType, bType>) { // string concat as in Java
		return Str();
	}
	*/
	
	throw "Type error, expected int, int was <aType>, <bType>";
}

public tuple[ImpExprTree, Type] typecheck((Expr)`<Expr a>*<Expr b>`, TcEnv env) {
	<aTree, aType> = typecheck(a,env);
	<bTree, bType> = typecheck(b,env);
	
	if(<Int(), Int()> := <aType, bType>) {
		return <Times(aTree, bTree), Int()>;
	}
	
	throw "Type error, expected int, int was <aType>, <bType>";
}

public default int typecheck(Expr e, TcEnv env) {
	if(amb(_) := e)
		throw "Ambiguous expression <e>";
	else
		throw "Unknown expression <e>";
}

public tuple[ImpExprTree, Type] typecheck((Expr)`<Expr a>;<Expr b>`, TcEnv env) {
	<aTree, aType> = typecheck(a,env);
	<bTree, bType> = typecheck(b,env);

	return <Seq(aTree, bTree), bType>;
}

public tuple[ImpExprTree, Type] typecheck((Expr)`<ID f>(<Expr a>)`, TcEnv env) {
	if("<f>" in env) {
		<funType, funStore> = env["<f>"];
		if(Fun(paramType, retType) := funType) {
			println("Argument typechecked in:");
			printenv(env);
			<argTree, argType> = typecheck(a, env);
			
			if(paramType == argType) {
				return <Apply(Var("<f>", funStore, funType), argTree), retType>;
			}
			else {
				throw "Wrong argument type: expected <paramType>, got <argType>";
			}	
		}
		else {
			throw "Not a function: <f> (is <fun>)";
		}
	}
	else {
		throw "Unknown variable: <n>";
	}
}

public tuple[ImpExprTree, Type] typecheck((Expr)`<ID v>`, TcEnv env) {
	Name n = "<v>";
	
	if(n in env) {
		<varType, varStore> = env[n];
		return <Ref(Var("<v>", varStore, varType)), varType>;  // type of the variable
	}
	else {
		throw "Unknown variable: <n>";
	}
}

public tuple[ImpExprTree, Type] typecheck((Expr)`let <ID v> = <Expr e1> in <Expr e2> end`, TcEnv env) {
	// typechecker e1
	// tilordne variabel
	// typecheckuer e2, i en kontekst hvor variabelen v har verdien til e1
	
	Name n = "<v>";	
	Store sto = newStore();
	
	
	<e1Tree, varType> = typecheck(e1, env);
	println("TcEnvironment before:");
	printenv(env);
	
	env[n] = <varType, sto>;
	println("TcEnvironment inside let body:");
	printenv(env);
	<e2Tree, e2Type> = typecheck(e2, env);
	return <Let(Var(n, sto, varType), e1Tree, e2Tree), e2Type>;
}

public tuple[ImpExprTree, Type] typecheck((Expr)`let <ID f>(<Type t> <ID v>) = <Expr e1> in <Expr e2> end`, TcEnv env) {
	paramType = typecheck(t, env);
	paramStore = newStore();
	
	bodyTcEnv = env;
	bodyTcEnv["<v>"] = <paramType, paramStore>;
	<bodyTree, retType> = typecheck(e1, bodyTcEnv);
	
	funStore = newStore();
	funType = Fun(paramType, retType);
	env["<f>"] = <funType, funStore>;
	<e2Tree, e2Type> = typecheck(e2, env);
	
	return <LetFun(Var("<f>", funStore, funType), Var("<v>", paramStore, paramType),
	               bodyTree, e2Tree), e2Type>;
}

public Type typecheck((Type)`<ID t>`, TcEnv env) {
	switch("<t>") {
	case "int": return Int();
	case "str": return Str();
	}
	
	throw "Unknown type name <unparse(t)>";
}

public Type typecheck((Type)`<Type rt>(<Type at>)`, TcEnv env) {
	return Fun(typecheck(at, env), typecheck(rt, env));
}

public tuple[ImpExprTree, Type] typecheck((Program)`<Expr e>`, TcEnv env) {
	return typecheck(e, env);
}


public void printenv(TcEnv env) {
	println("{");
	for(k <- env) {
		switch(env[k]) {
		case Int(): println("  <k> : int");
		case Fun(a,b): println("  <k> : <a> -\> <b>");
		}
	}
	println("}");
}
