{program setInspection(output);}


type skill = (cooking,  cleaning, driving, videogames, 
              eating,   baking,   flying,  swimming,
              crawling, barfing,  farting, snoring,
              yacking,   sleeping, biking,  programming);
skills = set of skill;
var slob: skills;

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


  writeln ('union tests');
  writeln ('slob is being set to [cooking..swimming]...');
  slob := [cooking..swimming]; 
  printSkill(slob);
  writeln;

  writeln ('... adding in [crawling..programming]...');
  slob := slob + [crawling..programming]; 
  printSkill(slob);
  writeln;


  writeln('... setting to NULL + [cooking]...');
  slob := [] + [cooking];
  printSkill(slob);
  writeln;



  writeln ('difference tests');
  slob := [cooking,cleaning,driving,videogames];
  writeln ('at the moment, slob is:');
  printSkill(slob);

  writeln;
  writeln ('subtracting [cooking,cleaning]...');
  slob := slob - [cooking,cleaning];
  printSkill(slob);


end.
