module simpl::Simplifier
import simpl::Simpl;
import ParseTree;
import IO;
import String;

public SimplProgram simplify(SimplProgram tree) {
	return visit(tree) {
	case (Expr)`<NUM a>+<NUM b>`: {
				insert parseInt(toInt(unparse(a)) + toInt(unparse(b)));
		}
	}
}


private Expr parseInt(int i) {
	return parse(#Expr, "<i>");
}