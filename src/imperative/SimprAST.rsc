module imperative::SimprAST

data ProgramAST
	= Program(list[DeclAST], list[StatAST])
	;

data DeclAST
	= FunDecl(str name, TypeAST retType, list[Param] params, list[StatAST] body)
	| VarDecl(str name, TypeAST typ, ExprAST init)
	;
	
data TypeAST
	= Fun(list[TypeAST] args, TypeAST retType)
	| Int()
	| ErrorType(str msg, loc location, TypeAST typ)
	;

public int sizeOf(Int()) = 1;
public int sizeOf(Fun(_,_)) = 1;
//public int sizeOf(Double()) = 2;
//public int sizeOf(Long()) = 2;

data StatAST
	= IfThenElseStat(ExprAST cond, list[StatAST] thenBranch, list[StatAST] elseBranch)
	| IfThenStat(ExprAST cond, list[StatAST] thenBranch)
	| WhileStat(ExprAST cond, list[StatAST] body)
	| DeclStat(str name, TypeAST typ, ExprAST init, Location storeLoc = Unknown())
	| AssignStat(str name, ExprAST expr, Location storeLoc = Unknown())
	| ReturnStat(ExprAST expr, Location storeLoc = Unknown())
	| ExprStat(ExprAST expr)
	| BlockStat(list[StatAST] body)
	| ErrorStat(str msg, loc location, StatAST stat)
	;
	
data ExprAST
	= Int(int i)
	| Var(str name, Location storeLoc = Unknown())
	| Apply(ExprAST f, list[ExprAST] args)
	| If(ExprAST cond, ExprAST thenBranch, ExprAST elseBranch)
	| Lambda(list[Param] params, ExprAST body)
	| Builtin(str name)
	| ErrorExpr(str msg, loc location, ExprAST expr)
	;

data Param
	= Param(TypeAST typ, str name)
	;
	
	
data Location
	= Local(int l)
	| Global(int l)
	| Unknown()
	;
