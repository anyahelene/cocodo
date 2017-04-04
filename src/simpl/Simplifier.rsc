module simpl::Simplifier
import simpl::Simpl;
import ParseTree;
import IO;
import String;

str bla = "";

public SimplProgram simplify(SimplProgram tree) =
	visit(tree) {
	case (Expr)`<NUM a>   +   <NUM b>`: {
				println("<"<bla>">:
						'	<a>
						'+
						'	<b>");
				insert parseInt(toInt(unparse(a)) + toInt(unparse(b)));
		}

	case (Expr)`<NUM a>*<NUM b>` =>
				parseInt(toInt(unparse(a)) * toInt(unparse(b)))
	};



private Expr parseInt(int i) {
	return parse(#Expr, "<i>");
}