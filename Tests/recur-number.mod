
const OctalDivisor = 8;
const DecimDivisor = 10;
const HexadDivisor = 16;

var t1:uint16;

{----------------------------------------}
{Recursively print an integer, in base 16}
procedure pr1hex(hd:uint16);
  begin {pr1hex}
    {print a hex digit}
    {not working in April 2025 release of interp
    if hd<10 then write(hd)
    else write(chr(hd-10+ord('A')));
    }

    if hd = 0x00 then write('0') else
    if hd = 0x01 then write('1') else
    if hd = 0x02 then write('2') else
    if hd = 0x03 then write('3') else
    if hd = 0x04 then write('4') else
    if hd = 0x05 then write('5') else
    if hd = 0x06 then write('6') else
    if hd = 0x07 then write('7') else
    if hd = 0x08 then write('8') else
    if hd = 0x09 then write('9') else
    if hd = 0x0A then write('A') else
    if hd = 0x0B then write('B') else
    if hd = 0x0C then write('C') else
    if hd = 0x0D then write('D') else
    if hd = 0x0E then write('E') else
    iF hd = 0x0F then write('F') else
    writeln (' out of range ');
    

  end; {pr1hex}


procedure prHex(curnum,divisor:uint16);
  var lh,rh:uint16;
  begin {prHex}
    lh := curnum DIV divisor;
    rh := curnum MOD divisor;
    if lh >=divisor then 
      prHex(lh,divisor) 
    else pr1Hex(lh);

    pr1Hex(rh);
  end; {prHex}

{----------------------------------------}

procedure printAll3(t1:uint16);
  begin
    writeln('number to convert is:',t1); 
  
    write  ('  number in base  8 is:');
    prHex(t1,OctalDivisor);
    writeln;
  
    write  ('  number in base 10 is:');
    prHex(t1,DecimDivisor);
    writeln;
  
    write  ('  number in base 16 is:');
    prHex(t1,HexadDivisor);
    writeln;
    writeln;
  end; {printAll3}

{----------------------------------------}

begin
  printAll3(0x8FD);
  printAll3(1113);
  printAll3(999);
end.
