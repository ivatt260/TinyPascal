{program loopTests (input,output);}

  var i: uint16;

begin
    writeln ('----------------------------------------');
    writeln('for loop, counting up:');
    for i:=1 to 11 do write(i,' '); writeln; writeln;

    writeln('for loop, counting down:');
    for i:=11 downto 1 do write(i,' '); writeln; writeln;

    writeln('for loop, counting up with high numbers:');
    for i:=34001 to 34011 do write(i,' '); writeln; writeln;

    writeln('for loop, counting down with high numbers:');
    for i:=34011 downto 34001 do write(i,' '); writeln; writeln;

    writeln ('----------------------------------------');
    writeln('while do counting up:');
    i := 1; while i<=11 do begin  write(i,' '); i:= i+1; end;
    writeln; writeln;

    writeln('while do counting down:');
    i := 11; while i>=1 do begin write(i,' '); i:= i-1; end;
    writeln; writeln;

    writeln ('----------------------------------------');
    writeln('repeat until counting up:');
    i := 1; repeat write(i,' '); i:= i+1; until i>11;
    writeln; writeln;

    writeln('repeat until counting down:');
    i := 11; repeat write(i,' '); i:= i-1; until i<1;
    writeln; writeln;


end.
