Tests.

maze3a:
  Go through a maze; find path from start to end.
  A recursive program; highlighting peek, poke, and writeln. 

files in this directory:

maze3a.mod  : TinyPascal maze program source. 
              I use the ".mod" file type to 
              indicate that this is not full Pascal. (I created
              a compiler for Wirths' Modula, as described in 
              Software Practice and Experience, thus the usage
              of ".mod". 

              execute this by (say) "TinyPascal < maze3a.mod" this
              results in the file "assemblerOut.asm" - copy this
              manually to "maze3a.asm".

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

README.txt  : this file 
