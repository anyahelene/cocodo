module simpl::SimplAST

alias Name = str;
data Type = Int()
		  | Str()
          | Fun(Type argType, Type ret)
          ;
data ExprTree
	= Var(Name name, Type typ) // or Var(Name name, Type type)
	| Int(int intValue)
	| Times(ExprTree e1, ExprTree e2)
	| Div(ExprTree e1, ExprTree e2)
	| Plus(ExprTree e1, ExprTree e2)
	| Minus(ExprTree e1, ExprTree e2)
	| Let(Name name, ExprTree body, ExprTree expr)
	| LetFun(Name name, Name param, ExprTree body, ExprTree expr)
	| Apply(Name name, ExprTree arg)
	;

data ProgramTree
	= Program(ExprTree expr)
	;
	

