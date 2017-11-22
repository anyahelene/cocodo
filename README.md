# Language Implementation with Rascal – A Tutorial

* *Anya Helene Bagge*, Department of Informatics, University of Bergen

### History
* First edition: Tutorial at CoCoDo'17
* Second edition: Tutorial at UFCG in Campina Grande, Brazil, 2017

# Setup

* Install (if you don't have it already) a full Java 8 JDK. You may want to *uninstall* any previously installed JREs, to avoid confusion. Rascal needs a full JDK, and may fail if it's launched with just a JRE.

* Install Eclipse Neon.3 for RCP/RAP developers from https://www.eclipse.org/downloads/packages/eclipse-rcp-and-rap-developers/neon3 (other versions *may* work)

* Install Rascal from http://www.rascal-mpl.org/start/

* Clone the CoCoDo Rascal source from: https://github.com/anyahelene/cocodo.git

(In Eclipse, *File → Import → Git → Projects From Git*)

# Resources

* Lecture notes (Rascal language implementation tutorial): https://bytebucket.org/sle-uib/inf225/wiki/docs/full.pdf?rev=8426bd7d0f78856368eae5d9542c662989c9f4df

* A more advanced (full) implementation of different variants of the Simpl language: https://bitbucket.org/anyahelene/inf225public/src/b4731730e165a019aeb3ea084a5a904d1d28dc8d/Evaluator/?at=master

* Rascal help: http://www.rascal-mpl.org/help/

* Rascal library reference: http://tutor.rascal-mpl.org/Rascal/Rascal.html

# Things you should (hope) to learn

* Get a brief overview of what Rascal is and what it can be used for

* Basics of syntax definition – be aware of generalised parsing and ambiguities

* Basics of working with concrete syntax

* Strings and string interpolation

* Visiting data structures

* Basics of making an IDE

# Simple experiments
Open the CoCoDo project. You'll find various source code in the 'src' folder.

If you don't have a Rascal console open in Eclipse already, right click on the project and select *Rascal console*. Make sure the title of the console tab includes "project: cocodo".


## Set up language plugin
This will setup up syntax hightlighting for the languages we're creating.

```
rascal>import Plugin;
ok
rascal>main();
ok
```

## Simpl Language
```
import simpl::Simpl;
```

```
example = parseSimplProgram(|project://cocodo/src/simpl/example.simpl|)
```



### Things to do

* The minus operator is not implemented. Add it to the evaluator and typechecker.
* The language is missing a less-than (or other comparison) operator. Add it. Note that the less-than symbol is reserved in Rascal, so you need to escape it: `\<`.
* There is syntax for `if`, but the evaluator (and typechecker) doesn't support it. Add `if`. 
* Priorities and associativity is wrong: make them left associative and at the same priority


## More excitement
In the file src/simpl/Simplifier there's a simple constant folding transformation.

* Add support for other operators
* Try it on nested expressions (it won't work!). You need a bottom-up traversal (`bottom-up visit`).
* Add support for variables – you should make a recursive `simplify` function, make it take an environment (e.g., map[ID, int]) as argument and call itself recursively when it encounters a `let`.

 
## TAC Language
We also have a language for three-address code.


```
import tac::ThreeAddressCode;
```

```
example = parseTACProgram(|project://cocodo/src/tac/example.tac|)
```


The `parseProgram` function is shorthand for this:
```
import ParseTree;
programTop = parse(#start[TacProgram], |project://cocodo/src/tac/example.tac|);
program = programTop.top;
```


### Running the virtual machine
```
import tac::VirtualMachine;
executeProgram(example, "main", [])
```


# Solutions

* If evaluator: `public Value eval((Expr)`if <Expr cond> then <Expr e1> else <Expr e2> end`, Env env)
	= eval( (Int(0) := eval(cond, env)) ? e2 : e1, env );
`
