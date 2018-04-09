module simpl::Simplifier
import simpl::Simpl;
import ParseTree;
import IO;
import String;

str bla = "";

public Expr rename(Expr tree, str from, str to) =
	top-down-break visit(tree) {
	case (Expr)`<ID a>`: {
		if("<a>" == from) insert(parse(#Expr, to));
		}
	case (Expr)`let <ID v> = <Expr e1> in <Expr e2> end`: {
		if("<v>" == from) {
			e1 = rename(e1, from, to);
			insert (Expr)`let <ID v> = <Expr e1> in <Expr e2> end`;
		}
		else
			fail;
	}
	};
	
	
public SimplProgram simplify(SimplProgram tree) =
	bottom-up visit(tree) {
	case (Expr)`<NUM a>   +   <NUM b>`: {
				insert parseInt(toInt(unparse(a)) + toInt(unparse(b)));
		}

	case (Expr)`<NUM a>*<NUM b>` =>
				parseInt(toInt(unparse(a)) * toInt(unparse(b)))
	};



private Expr parseInt(int i) {
	return parse(#Expr, "<i>");
}