module ImperativeAST


alias Store = int;
alias Name = str;
data Type = Int()
		  | Str()
          | Fun(Type argType, Type ret)
          ;
          
          
data Var = Var(Name name, Store sto, Type typ); 
data ImpExprTree
	= Ref(Var var) // or Var(Name name, Type type)
	| Int(int intValue)
	| Times(ImpExprTree e1, ImpExprTree e2)
	| Div(ImpExprTree e1, ImpExprTree e2)
	| Plus(ImpExprTree e1, ImpExprTree e2)
	| Minus(ImpExprTree e1, ImpExprTree e2)
	| Let(Var var, ImpExprTree body, ImpExprTree expr)
	| LetFun(Var var, Var param, ImpExprTree body, ImpExprTree expr)
	| Apply(Var var, ImpExprTree arg)
	| Assign(Var var, ImpExprTree)
	| Seq(ImpExprTree e1, ImpExprTree e2)
	;

data ImperativeTree
	= Program(ImpExprTree expr)
	;
	

