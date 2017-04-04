module tac::ThreeAddressCode
import ParseTree;
extend lang::std::Id;
extend lang::std::Layout;


start syntax TacProgram = TacFunction* functions;

start syntax TacBlock = {TacStatement ";"}* statements;

syntax TacLabel
	= @category="Identifier" Label: Id name
	;

syntax TacFunction
	= Function: Id name "(" {Id ","}* args ")" "{" TacBlock body "}"
	;
		
syntax TacStatement
	= Stat: (TacLabel ":")? label TacInstruction instr
	;
	
syntax TacInstruction
    = Assign: TacLValue target "=" TacExpr expr
    | @doc="branch" Branch:  "if" TacRValue "goto" TacLabel dest
    | Return: "return" TacRValue
    | Nop:
	;

syntax TacExpr
	= Atom: TacRValue opnd
	> Binary: TacRValue leftOpnd TacBinary op TacRValue rightOpnd
	| Unary: TacUnary op TacRValue opnd
	| Call: Id name "(" {TacRValue ","}* args ")"
	;
	
syntax TacLValue =
	  TacVariable
	| Deref: "*" TacSimpleValue
	;

syntax TacVariable = Var: Id name;

syntax TacGlobal = "#" Id name;

syntax TacRValue
	= TacSimpleValue
	| Deref: "*" TacSimpleValue
	;
	
syntax TacSimpleValue
	= TacVariable
	| @category="Constant" TacGlobal
	| Int:	TacInteger intValue
	| HexInt: TacHexInteger hexValue
	;

lexical TacBinary =
	  Op: [+*\-/\<\>=&|^%.!]+
	;

lexical TacUnary =
	  Unary: [\-!]
	;
	
lexical TacInteger = [0-9]+;

lexical TacHexInteger = [0] [x] [0-9]+;


public TacProgram parseTACProgram(str s) {
  return parse(#start[TacProgram], s).top;
}

public TacProgram parseTACProgram(loc l) {
  return parse(#start[TacProgram], l).top;
}


public start[TacBlock] parseBlock(str s) {
  return parse(#start[TacBlock], s);
}

public start[TacBlock] parseBlock(str s, loc l) {
  return parse(#start[TacBlock], s, l);
} 
