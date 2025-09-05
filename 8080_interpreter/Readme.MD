# Interpreter for CP/M 2.2 computers.
This interpreter runs on CP/M 2.2 computers. It is written in 8080 assembler, and uses CP/M 2.2 standard calls, so should run on any CP/M
2.2 8-bit computers such as the R2014 computers. 

I have tested this on Lee Harts "Altaid8800" computer - a beautiful, little 8080 computer. 

## Current Status (Sept 5 2025)
At the moment, it generally works.
- peek, poke; memory is "sandboxed"; there's something like 1K RAM in the "peek-poke" sandbox. In the future, this will be removed, giving
one the ability to write over the whole 64k computer memory.... 
- Sets; the code for Pascal Sets is not complete.
- Speed - wrote the PCode interpreter in "C", spent time getting a "TinyC" compiler working, compiled the interpreter. Now, the goal is
to rewrite the interpreter in assembler; first steps have halved execution speed; I hope to get it running 5x faster than the TinyC-compiled
version.

## Specific notes on the "Altaid8800" computer.

### Battery Backup
I have added a coin-cell battery, wired up as per the instructions. DO IT! Downloading support programs via serial gets old fast. 

### Go to CP/M
I have memorized the three letter commands "T", "L", "C", (Tender Loving Care) these take you into CP/M and stop the flashing lights.
