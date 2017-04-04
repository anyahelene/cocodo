module Plugin

import util::IDE;
import ParseTree;
import IO;
import tac::ThreeAddressCode;
import simpl::Simpl;

void main() {
   registerLanguage("TAC", "tac", Tree(str src, loc l) {
     pt = parse(#start[TacProgram], src, l);
     return pt;
   });

   registerLanguage("Simpl", "simpl", Tree(str src, loc l) {
     pt = parse(#start[SimplProgram], src, l);
     return pt;
   });
}