{program setInspection(output);}


type skill = (cooking,  cleaning, driving, videogames, 
              eating,   baking,   flying,  swimming,
              crawling, barfing,  farting, snoring,
              yacking,   sleeping, biking,  programming);
skills = set of skill;
var slob, common, bluecollar: skills;

{===========================================}


const OctalDivisor = 8;
const DecimDivisor = 10;
const HexadDivisor = 16;

var t1:uint16;

{----------------------------------------}
{Recursively print an integer, in base 16}
procedure pr1hex(hd:uint16);
  begin {pr1hex}
    {print a hex digit}
    if hd<10 then write(hd)
    else write(chr(hd-10+ord('A')));
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

{procedure printAll3(t1:uint16);
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
  end;}

{----------------------------------------}

{begin
  printAll3(0x8FD);
  printAll3(1113);
  printAll3(999);
end.}

{===========================================}
procedure printSkill (cs:skills);
  begin
    {writeln ('set consists of:',cs);}
    if cooking in cs then writeln ('cooking');
    if cleaning in cs then writeln ('cleaning');
    if driving in cs then writeln ('driving');
    if videogames in cs then writeln ('videogames');
    if eating in cs then writeln ('eating');
    if baking in cs then writeln ('baking');
    if flying in cs then writeln ('flying');
    if swimming in cs then writeln ('swimming');
    if crawling in cs then writeln ('crawling');
    if barfing in cs then writeln ('barfing');
    if farting in cs then writeln ('farting');
    if snoring in cs then writeln ('snoring');
    if yacking in cs then writeln ('yacking');
    if sleeping in cs then writeln ('sleeping');
    if biking in cs then writeln ('biking');
    if programming in cs then writeln ('programming.');
  end;
    



begin
  writeln('--------------------------');
  writeln('Union and Difference Tests:');
  slob := [cooking,crawling]; 
  writeln('initial set slob is:');
  {prHex(ord(slob),HexadDivisor); writeln;}
  printSkill(slob); writeln;

  slob := slob + [driving]; 
  writeln('Union: slob + [driving] is:');
  {prHex(slob,HexadDivisor); writeln;}
  printSkill(slob); writeln;

  slob := slob + [crawling,barfing];
  writeln('Union: slob + [crawling,barfing] is:');
  {prHex(slob,HexadDivisor); writeln;} 
  printSkill(slob); writeln;

  slob := slob - [cooking,yacking]; 
  writeln('Difference: slob - [cooking,yacking] is:');
  {prHex(slob,HexadDivisor); writeln; }
  printSkill(slob); writeln;

  slob := slob - [driving]; 
  writeln('Difference: set slob - [driving] is:');
  {prHex(slob,HexadDivisor); writeln; }
  printSkill(slob); writeln;

  writeln('---------------------');
  writeln('an Intersection test:');
  blueCollar := [cooking, cleaning, driving, eating];
  writeln('set blueCollar is:');
  printSkill(blueCollar); writeln;

  slob := [driving, videogames, eating];
  writeln('set slob is:');
  printSkill(slob); writeln;

  common := blueCollar * slob;
  writeln('Intersection: blueCollar * slob is:');
  printSkill(common); writeln;
end.
