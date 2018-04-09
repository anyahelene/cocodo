module Plugin

import util::IDE;
import ParseTree;
import IO;
//import tac::ThreeAddressCode;
import simpl::Simpl;
//import imperative::Simpr;

void main() {
	/*
   registerLanguage("TAC", "tac", Tree(str src, loc l) {
     pt = parse(#start[TacProgram], src, l);
     return pt;
   });
   */

   registerLanguage("Simpl", "simpl", Tree(str src, loc l) {
     pt = parse(#start[SimplProgram], src, l);
     return pt;
   });
   
   /*
   registerLanguage("Simpr", "simpr", Tree(str src, loc l) {
     pt = parse(#start[SimplProgram], src, l);
     return pt;
   });
   */
   
   registerContributions("Simpl", {
   		builder(set[Message] (Tree t) {
   			println("build!");
 			ast = typecheck(t, ());
 			return {error(s, l) | /Error(s, l) <- ast};
   		})
   });
}