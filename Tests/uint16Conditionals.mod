{program uint16Conditionals(input,output);}

begin
  {gtr}
writeln ('conditional tests. All should pass');
  if 2>1 then writeln ('pass') else writeln ('fail');
  if 257>256 then writeln ('pass') else writeln ('fail');
  if 1>1 then writeln('fail') else writeln ('pass');
  if 256>256 then writeln('fail') else writeln ('pass');
  writeln;

  {geq}
  if 2>=1 then writeln ('pass') else writeln ('fail');
  if 257>=256 then writeln('pass') else writeln ('fail');
  if 1>=2 then writeln ('fail') else writeln('pass');
  if 256>=257 then writeln ('fail') else writeln('pass');
  writeln;
 
  {eq}
  if 1=1 then writeln ('pass') else writeln ('fail');
  if 256=256 then writeln ('pass') else writeln ('fail');
  if 1=2 then writeln ('fail') else writeln ('pass');
  if 256=257 then writeln ('fail') else writeln ('pass');
  writeln;

  {neq}
  if 1<>1 then writeln ('fail') else writeln ('pass');
  if 256<>256 then writeln ('fail') else writeln ('pass');
  if 1<>2 then writeln('pass') else writeln ('fail');
  if 256<>257 then writeln('pass') else writeln('fail');
  writeln;

  {lss}
  if 1<2 then writeln('pass') else writeln ('fail');
  if 256<257 then writeln('pass') else writeln ('fail');
  if 1<1 then writeln('fail') else writeln ('pass');
  if 256<256 then writeln('fail') else writeln ('pass');
  writeln;

  {leq} 
  if 1<2 then writeln ('pass') else writeln ('fail');
  if 256<257 then writeln ('pass') else writeln ('fail');
  if 1<1 then writeln('fail') else writeln ('pass');
  if 256<256 then writeln ('fail') else writeln ('pass');
  writeln;


end.
