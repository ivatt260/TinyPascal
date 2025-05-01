Tests.
------

  All tests are compiled to be loaded at memory 8800. They assume you are
  running on a Membership/chip card, because the I/O routines are coded to
  work with the "MC20ANSA" ROM.

  If your RAM is in lower memory, or you have different SCRT address for
  read and write characters, you'll need to compile and assemble the
  tests.

maze3a:
  Go through a maze; find path from start to end.
  A recursive program; highlighting peek, poke, and writeln. 

biggerMaze: 
  A bigger maze than maze3a; takes a few seconds longer to run.

files in this directory:
------------------------

biggerMaze.mod:
              A bigger maze. Follow the directions for "maze3a.mod"
              below to see how to the compile for this works.

maze3a.mod  : TinyPascal maze program source. 
              I use the ".mod" file type to 
              indicate that this is not full Pascal. (I created
              a compiler for Wirths' Modula, as described in 
              Software Practice and Experience, thus the usage
              of ".mod". 

              Note that this uses "Peek" and "Poke" to direct
              memory access. It tries to find RAM at low memory
              or higher memory; hopefully this works for you.

              If not, Change the addresses in the maze3a.mod, then
              recompile, and reassemble the resulting ".asm" file, 
              to create the .hex file at the correct memory partition.

              Compile this by (eg) "TinyPascal < maze3a.mod" this
              results in the file "assemblerOut.asm" - copy this
              manually to "maze3a.asm" and assemble with a18 - see
              the script example below.

maze3a.txt  : a simple script file to compile maze3a.asm into
              maze3a.hex. You'll have to change this to suit
              your directory structure.

maze3a.hex  : Binary hex file, compiled and assembled, and set to
              load at 0x8800 for Membership cards with rom at 0x000.

              It is included here should you want to give this 
              a try without needing to set up all the tools required.

maze3a.lst  : assembler listing - I use this for debugging in Emma-02,
              by setting break points, inspecting registers.

              It is included here should you want to give this 
              a try without needing to set up all the tools required.

---- other tests, for those interested:

loopTests	- for, while, repeat loop tests.
		- note, UINT16s are printed in HEX on the 1802;
		-       currently the compiler prints in decimal.

readln		- read text from keyboard. End with "}" key.
	
recur-number	- prints a number in hex, decimal and octal.
		- ***NOTE - v0.6 of the 1802 interpreter does not
		  print quite right, so this version has an "if"
		  chain. (see the code) 

setCombinations - 16 bit "set" combination tests.

setComparisons	- comparing two or more sets, for inclusion.

setUnionTest	- adding/removing set elements.

uint16Conditionals - test all ">=", etc condition tests.
		- should print a bunch of "pass" lines

----

               README.txt  : this file 
