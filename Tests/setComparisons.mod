{program setInspection(output);}


type skill = (cooking,  cleaning, driving, videogames, 
              eating,   baking,   flying,  swimming,
              crawling, barfing,  farting, snoring,
              yacking,   sleeping, biking,  programming);
skills = set of skill;
var slob, slobCopy, neighbour: skills;
 tmp: uint16;

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
    

{===========================================}
begin
  tmp := 22;
  writeln ('Set Comparison Tests');
  slob := [cooking..swimming];
  slobCopy := [cooking..swimming];

  neighbour := [baking..snoring];
  writeln('set slob and slobCopy consists of:');
  printSkill(slob);
  printSkill(slobCopy);
  writeln;
  writeln('set neighbour consists of:');
  printSkill(neighbour);
  writeln;

  {equality, "="}
  if slob = slobCopy then writeln ('slob = slobCopy') else writeln ('Hmmm.. slob does NOT equal slobCopy, it should');

  {inequality, "<>"}
  if slob <> slobCopy then writeln ('Hmmm... slob = slobCopy - shouldnt') else writeln ('testing <>, as slob=slobCopy, being here in the else is correct.');

  {inclusion 1, "<="}
  neighbour := [cleaning];
  writeln ('neighbour set to [cleaning], slob as above:');
  write ('neighbour <= slob: ');
  if neighbour <= slob then 
    writeln ('<= true (this is correct)') 
  else 
    writeln ('<= false (this is an ERROR');

  {inclusion 2, ">="}
  write ('neighbour >= slob: ');
  if neighbour >= slob then 
    writeln ('>= true (this is an ERROR)') 
  else 
    writeln ('>= false (this is correct)');


  {element, "IN"}
  if cooking in slob then writeln ('cooking IS in slob') else writeln ('Hmmm... cooking should be in slob');

end.
