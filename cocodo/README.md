
## Set up language plugin
```
rascal>import Plugin;
ok
rascal>main();
ok
```

## TAC Language
```
import tac::ThreeAddressCode;
```

```
example = parseProgram(|project://cocodo/src/tac/example.tac|)
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
