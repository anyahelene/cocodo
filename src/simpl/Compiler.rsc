module simpl::Compiler

import simpl::Simpl;



public str compile(str dest, (Expr)`<NUM a>`) {
	return "<dest> = <unparse(a)>;\n";
}


public default str compile(str dest, (Expr)`<Expr a>+<Expr b>`) {
	return "<compile("t1", a)><compile("t2", b)><dest> = t1 + t2;";
}
