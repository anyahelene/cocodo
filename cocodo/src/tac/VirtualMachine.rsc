module tac::VirtualMachine
import IO;
import List;
import String;
import ParseTree;
import tac::ThreeAddressCode;
import util::Math;

alias Name = str;
alias Value = int;

data Function = Function(list[Name] args, list[TacStatement] body);
data Program = Program(map[Name, Function] functions);

data ProcessorState = State(
	list[Value] memory,
	int pc,
	int sp,
	bool flagZero,
	bool flagOverflow,
	bool flagReturn
	);

data ProcessorBindings = Bindings(	
	map[Name,int] labels,
	map[Name,int] bindings
	);
	

public Value executeProgram(TacProgram program, str funName, list[Value] args) {
	Program prog = Program(());
	for(TacFunction fun <- program.functions) {
		name = "<fun.name>";
		params = ["<a>" | a <- fun.args];
		stats = [s | s <- fun.body.statements];
		println("Loading function <name>(<intercalate(", ", params)>), <size(stats)> instructions");
		prog.functions[name] = Function(params, stats);
	}
	
	return executeProgram(prog, funName, args);
}	
public Value executeProgram(Program program, str funName, list[Value] args) {
	fun = program.functions[funName];
	memSize = 8192;
	state = State([0 | x <- [0 .. memSize]], 0, memSize-1, false, false, false);
	return executeFunction(fun, args, program, state).memory[memSize-1];
}

public ProcessorState executeFunction(Function fun, list[Value] args, Program program, ProcessorState state) {
	if(size(args) != size(fun.args)) {
		throw "Wrong number of arguments: expected <size(fun.args)>, got <size(args)>";
	}
	oldSp = state.sp;
	oldPc = state.pc;
	state.pc = 0;
	bindings = Bindings((), ());

	for(i <- [0 .. size(fun.body)]) {
		s = fun.body[i];
		l = unparse(s.label);
		if(l != "") {
			println("New label: <l> = <i>");
			bindings.labels[l[0..-1]] = i; 
		}
	}

	bindings.bindings["RESULT"] = state.sp;	
	state.sp = state.sp - 1;

	for(i <- [0 .. size(args)]) {
		println("Assigning argument <fun.args[i]> = <args[i]> to location <state.sp>");
		state.memory[state.sp] = args[i];
		bindings.bindings[fun.args[i]] = state.sp;	
		state.sp = state.sp - 1;
	}
	
	for(v <- {"<v>" | /(TacVariable)`<Id v>` <- fun.body}) {
		if(v notin bindings.bindings) {
			println("Allocating new variable <v> at <state.sp>");
			bindings.bindings[v] = state.sp;
			state.sp = state.sp - 1;
		}
	}	

	while(!state.flagReturn) {
		instr = fun.body[state.pc].instr;
		println("Executing: <state.pc>: <left(unparse(instr), 15)> // <intercalate("  ", [debugValue(v,bindings,state) | /TacRValue v <- [instr]])>");
		//println("  <debugVars(bindings, state)>");
		println("  <debugStack(state)>");
		println("");
		state = executeStep(instr, program, bindings, state);
	}
	state.flagReturn = false;
	state.sp = oldSp;
	state.pc = oldPc;
	
	return state;
}

public ProcessorState executeStep(list[TacInstruction] code, Program program, ProcessorBindings bindings, ProcessorState state) {
	return executeStep(code[state.pc], program, bindings, state);
}

public ProcessorState executeStep(
	(TacInstruction)`<TacLValue target> = <TacUnary op> <TacRValue opnd>`,
	Program prog, ProcessorBindings bs, ProcessorState state) {
	
	x = getValue(opnd, bindings, state);
	z = getAddress(target, bindings, state);

	switch(op) {
	case (TacUnary)`-`: state.memory[z] = -x;
	default: throw "Unknown operator: <unparse(op)>"; 
	}
	
	state.pc = state.pc + 1;
	return state;
}

public ProcessorState executeStep(
	(TacInstruction)`<TacLValue target> = <TacRValue opnd1> <TacBinary op> <TacRValue opnd2>`,
	Program prog, ProcessorBindings bs, ProcessorState state) {
	
	x = getValue(opnd1, bs, state);
	y = getValue(opnd2, bs, state);
	z = getAddress(target, bs, state);

	switch(op) {
	case (TacBinary)`-`:   state.memory[z] = x - y;
	case (TacBinary)`+`:   state.memory[z] = x + y;
	case (TacBinary)`*`:   state.memory[z] = x * y;
	case (TacBinary)`/`:   state.memory[z] = x / y;
	case (TacBinary)`%`:   state.memory[z] = x % y;
	case (TacBinary)`\<`:  state.memory[z] = x < y ? 1 : 0;
	case (TacBinary)`\>`:  state.memory[z] = x > y ? 1 : 0;
	case (TacBinary)`\<=`: state.memory[z] = x <= y ? 1 : 0;
	case (TacBinary)`\>=`: state.memory[z] = x >= y ? 1 : 0;
	case (TacBinary)`==`:  state.memory[z] = x == y ? 1 : 0;
	default: throw "Unknown operator: <unparse(op)>"; 
	}
	
	state.pc = state.pc + 1;
	return state;
}

public ProcessorState executeStep(
	(TacInstruction)`<TacLValue target> = <Id funName> (<{TacRValue ","}* opnds>)`,
	Program prog, ProcessorBindings bs, ProcessorState state) {
	
	args = [getValue(opnd, bs, state) | opnd <- opnds];
	z = getAddress(target, bs, state);

	state = executeFunction(prog.functions["<funName>"], args, prog, state);
	state.memory[z] = state.memory[state.sp];
	state.pc = state.pc + 1;
	return state;
}

public ProcessorState executeStep(
	(TacInstruction)`if <TacRValue opnd> goto <TacLabel lbl>`,
	Program prog, ProcessorBindings bs, ProcessorState state) {
	
	if(getValue(opnd, bs, state) != 0) {
		state.pc = bs.labels["<lbl>"];
	}
	else {
		state.pc = state.pc + 1;
	}
	
	return state;
}

public ProcessorState executeStep(
	(TacInstruction)`return <TacRValue opnd>`,
	Program prog, ProcessorBindings bs, ProcessorState state) {
	
	x = getValue(opnd, bs, state);
	z = getAddress((TacLValue)`RESULT`, bs, state);
	state.memory[z] = x;
	state.flagReturn = true;
	state.pc = state.pc + 1;
	
	return state;
}

public ProcessorState executeStep(
	(TacInstruction)``,
	Program prog, ProcessorBindings bs, ProcessorState state) {
	
	state.pc = state.pc + 1;
	
	return state;
}

public default ProcessorState executeStep(TacInstruction stat, Program prog, ProcessorBindings bs, ProcessorState state) {
	throw "Unknown statement: <unparse(stat)>";
}


public Value getValue((TacRValue)`<TacInteger i>`, ProcessorBindings bindings, ProcessorState state) {
	return toInt("<i>");
}

public Value getValue((TacRValue)`<TacHexInteger i>`, ProcessorBindings bindings, ProcessorState state) {
	return toInt("<i>"[2..],16);
}

public Value getValue((TacRValue)`<Id i>`, ProcessorBindings bindings, ProcessorState state) {
	return state.memory[bindings.bindings["<i>"]];
}

public Value getValue((TacRValue)`*<TacSimpleValue v>`, ProcessorBindings bindings, ProcessorState state) {
	return state.memory[getValue(v, bindings, state)];
}

public Value getAddress((TacLValue)`<Id i>`, ProcessorBindings bindings, ProcessorState state) {
	return bindings.bindings["<i>"];
}

public Value getAddress((TacLValue)`*<TacSimpleValue v>`, ProcessorBindings bindings, ProcessorState state) {
	return state.memory[getValue(v, bindings, state)];
}

public str debugValue((TacRValue)`<TacInteger i>`, ProcessorBindings bindings, ProcessorState state) {
	return "";
}

public str debugValue((TacRValue)`<TacHexInteger i>`, ProcessorBindings bindings, ProcessorState state) {
	return "";
}

public str debugValue((TacRValue)`<TacVariable i>`, ProcessorBindings bindings, ProcessorState state) {
	return "<i>=<state.memory[bindings.bindings["<i>"]]>";
}

public str debugValue((TacRValue)`*<TacSimpleValue v>`, ProcessorBindings bindings, ProcessorState state) {
	return "<v>=state.memory[getValue(v, bindings, state)]>";
}

public default str debugValue(TacRValue v, ProcessorBindings bindings, ProcessorState state) {
	throw "unknown: <v>";
}

public str debugVars(ProcessorBindings bs, ProcessorState state) {
	result = "";
	count = 0;
	for(b <- bs.bindings) {
		count = count + 1;
		result = "<result><b>=<right(toString(state.memory[bs.bindings[b]]), 8, "0")>  ";
		if(count % 8 == 0)
			result = result + "\n";
	}
	return result;
}
public str debugStack(ProcessorState state) {
	memSize = size(state.memory);
	result = "sp=<right(toString(state.sp), 4, "0")>:  ";
	for(i <- [state.sp .. min(state.sp+8,memSize)]) {
		val = state.memory[i];
		
		result = result + right(toString(val), 8, "0");
		if(i == state.sp)
			result = result + "\< ";
		else
			result = result + "  ";
	}
	
	return result;
}
