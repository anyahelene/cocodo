module Plugin

import util::IDE;
import ParseTree;
import IO;
import tac::ThreeAddressCode;

void main() {
   registerLanguage("TAC", "tac", Tree(str src, loc l) {
     pt = parse(#start[TacProgram], src, l);
     return pt;
   });
}