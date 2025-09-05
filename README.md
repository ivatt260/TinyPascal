Tiny Pascal for Small Computers.

This is a "Tiny" version of Pascal, which has a goal of "write once, run anywhere". 

Targeted machines: 

- Lee Hart's RCA1802 "Membership" and "Memberchip" cards,
- 8080 machines like Lee's "Altaid8800" and the RC2014 Z-80 machines,
- and the 8088... (more about that in the future!)

The source code of the compiler is written in FreePascal, which should run on any modern desktop. Right now, I use Linux almost exclusively,
so some of the documentation may be linux-specific. 

Mode of operation:
- write TinyPascal code;
- run it through the compiler (with built-in runtime interpreter);
- if ok, assemble the output into a ".hex" file;
- download the interpreter to your single board computer; (only needs doing once)
- download the ".hex" file to your single board computer;
- run the interpreter, if (e.g. on CP/M) a file name is required, enter your hex file name;
- sit back and enjoy!

Updates, futures:
  - remove the need for the "assemble output to hex file" step;
  - ease use of the TinyPascal compiler (the goal was to get it working, now, the goal is to get it user-friendly);
  - enhance the PCode for records, arrays, 32 bit numbers, I/O ports (right now, memory-mapped I/O should work);
  - enable "Modula" style of modules, first module will be for machine-specifics
    
 
