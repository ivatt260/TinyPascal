{program readln(input,output);}

{read characters in from "stdin".
 if running from the pascal compiled on the desktop, 
 it will source keystrokes from the BOTTOM OF THIS FILE.

 if running on a Membership/Memberchip card, it will get
 input from the keyboard.

 No matter what, the program will end if it gets either a
 closing squiggly brace, or, it reads "ninetynine" characters
 (from the constant; no, nothing to do with 99 bottles of beer
 on the wall...)
}

const ninetynine = 9;
var lone:char;
var t1:uint16;


begin
  lone := 'z';
  t1 := 1;
  repeat
    writeln('press a key!');
    readln(lone);
    writeln('just read in as a number:',ord(lone));
    if ord(lone) > 20 then writeln ('as a character: ',lone);
    t1 := t1+1;
  until (t1 > ninetynine) or (lone = '}');
  writeln ('done');
end.
{this is junk}
