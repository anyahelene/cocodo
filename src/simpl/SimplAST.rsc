module simpl::SimplAST

data TypeAST
	= Fun(list[TypeAST] args, TypeAST retType)
	| Int()
	;

data ProgramAST
	= SimplProgram(list[DefAST] defs, ExprAST body)
	;
	
data DefAST
	= FunDef(str name, list[Param] params, TypeAST retType, ExprAST body)
	| VarDef(str name, TypeAST typ, ExprAST init)
	;
	
data ExprAST
	= Int(int i)
	| Var(str name)
	| Var(str name, int storeLoc)
	| Apply(ExprAST f, list[ExprAST] args)
	| If(ExprAST cond, ExprAST thenBranch, ExprAST elseBranch)
	| Let(str name, ExprAST e1, ExprAST e2)
	| LetFun(str name, list[Param] params, ExprAST e1, ExprAST e2)
	| Builtin(str name)
	| Error(str msg, loc location, ExprAST expr)
	| Seq(ExprAST e1, ExprAST e2)
	;

data Param
	= Param(TypeAST typ, str name)
	;
	
	
data Location
	= Local(int l)
	| Global(int l)
	;
	
alias TCEnv = map[str, TypeAST];

alias TCSEnv = map[str, tuple[TypeAST,Location]];
