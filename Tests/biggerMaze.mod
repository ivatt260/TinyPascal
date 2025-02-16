{program maze (input,output);}

{const maxcellcount = 800;

      freecell = ' ';
      wallcell = '#';
      visitedcell = '.';
      pathcell = 'o';
}


var maxcol, maxrow: uint16;
    freecell,wallcell,visitedcell,pathcell: char;
    entranceSquare: uint16;
    exitSquare:     uint16;
    solved:         uint16;
    entrow,entcol,
    xitrow,xitcol:  uint16;

    maxcellcount: uint16;
    locn:         uint16; {location where peek/poke should go}

function rcToMatrix(var row,col:uint16):uint16;
  begin
    {writeln ('rcm ',row,',',col);}
    if (row < 1) or (row > maxrow) then begin
      writeln ('row out of bounds ',row);
      row := 1; end;
    if (col <1) or (col > maxcol) then begin
      writeln ('col out of bounds ',col);
      col := 1; end;
    rcToMatrix := locn+col+(row-1)*maxcol;
  end;

{horizontal line, row stays the same}
procedure horizontalLine(r1,c1,r2,c2:uint16);
  var r,c: uint16;
  begin
    r := r1;
    for c:= c1 to c2 do
      poke(rcToMatrix(r,c), wallcell);
  end; 

{vertical line, column stays the same}
procedure verticalLine(r1,c1,r2,c2:uint16);
  var r,c: uint16;
  begin
    c := c1;
    for r:= r1 to r2 do
      poke(rcToMatrix(r,c), wallcell);
  end; 

{larger matrix, from the internet}
procedure makematrix2;
  var i,j: uint16;
  begin
    maxrow := 23;
    maxcol := 29;

    writeln ('maxcellcount ',maxcellcount,' and we have ',maxrow*maxcol);
    if maxrow*maxcol > maxcellcount then begin
      writeln ('MAKE MATRIX LARGER')
    end
    else
    begin
      writeln ('within size, lets run!');
    end;

    {make all cells free}
    for i:=1 to maxrow do
      for j := 1 to maxcol do
        poke(rcToMatrix(i,j), freecell);

    
    {entrance: 	2,29
    exit:	22,1}
    {make an entrance and an exit}

    {put it bottom, near the right, for this test}
    entrow := 2; 
    entcol := 29;
    entranceSquare := rcToMatrix(entrow,entcol);
    poke(entranceSquare, freecell);

    {put exit top, near centre}
    xitrow := 22;
    xitcol := 1;
    exitSquare := rcToMatrix(xitrow,xitcol); 
    poke(exitSquare, freecell);
 
    writeln('             row, col:');
    writeln('entrance:',entrow,',',entcol);
    writeln('exit:    ',xitrow,',',xitcol);

    
    {Horizontal lines}
    horizontalLine(1,1,1,29);
    horizontalLine(3,15,3,19);
    horizontalLine(3,21,3,25);
    horizontalLine(5,1,5,3);
    horizontalLine(5,7,5,11);
    horizontalLine(5,17,5,19);
    horizontalLine(7,3,7,9);
    horizontalLine(7,15,7,17);
    horizontalLine(7,23,7,27);
    horizontalLine(9,1,9,3);
    horizontalLine(9,5,9,9);
    horizontalLine(9,13,9,15);
    horizontalLine(9,17,9,23);
    horizontalLine(11,3,11,5);
    horizontalLine(11,9,11,13);
    horizontalLine(11,15,11,19);
    horizontalLine(11,23,11,25);
    horizontalLine(13,1,13,15);
    horizontalLine(13,17,13,19);
    horizontalLine(13,25,13,29);
    horizontalLine(15,3,15,5);
    horizontalLine(15,7,15,11);
    horizontalLine(15,13,15,15);
    horizontalLine(15,19,15,23);
    horizontalLine(17,1,17,3);
    horizontalLine(17,5,17,13);
    horizontalLine(17,15,17,19);
    horizontalLine(19,3,19,5);
    horizontalLine(19,9,19,11);
    horizontalLine(19,13,19,19);
    horizontalLine(19,21,19,27);
    horizontalLine(21,5,21,7);
    horizontalLine(21,11,21,17);
    horizontalLine(21,19,21,21);
    horizontalLine(21,25,21,27);
    horizontalLine(23,1,23,29);
    
    {Vertical lines}
    
    verticalLine(1,1,21,1);
    verticalLine(3,3,5,3);
    verticalLine(17,3,21,3);
    verticalLine(1,5,7,5);
    verticalLine(9,5,11,5);
    verticalLine(15,5,17,5);
    verticalLine(21,5,23,5);
    verticalLine(3,7,5,7);
    verticalLine(11,7,13,7);
    verticalLine(17,7,21,7);
    verticalLine(1,9,3,9);
    verticalLine(21,9,23,9);
    verticalLine(1,11,9,11);
    verticalLine(13,11,15,11);
    verticalLine(19,11,21,11);
    verticalLine(3,13,11,13);
    verticalLine(3,15,9,15);
    verticalLine(11,15,17,15);
    verticalLine(13,17,15,17);
    verticalLine(19,17,21,17);
    verticalLine(1,19,3,19);
    verticalLine(5,19,9,19);
    verticalLine(11,19,13,19);
    verticalLine(15,19,19,19);
    verticalLine(3,21,5,21);
    verticalLine(7,21,15,21);
    verticalLine(17,21,21,21);
    verticalLine(5,23,7,23);
    verticalLine(11,23,19,23);
    verticalLine(21,23,23,23);
    verticalLine(1,25,3,25);
    verticalLine(5,25,11,25);
    verticalLine(13,25,17,25);
    verticalLine(3,27,7,27);
    verticalLine(9,27,13,27);
    verticalLine(15,27,21,27);
    verticalLine(3,29,23,29);
  end; {makematrix2}

procedure printmatrix;
  var r,c: uint16;
  var i:   uint16;
  var ch:  char;
  begin
    for r := 1 to maxrow do
      begin
        write ('row:',r,' ');
        for c := 1 to maxcol do begin
          i := rcToMatrix(r,c);
          ch := peek(i);

          {remove the "been there done that" marker}
          if ch=visitedcell then ch := freecell;

          {doing some bounds checking}
          if ord(ch) > 127 then ch := 'X';
          if ord(ch) < 32 then ch := 'x';
          write(ch);
        end;
        writeln;
      end
  end;

{recursively resolve, return 0 if not on solution path,
 return 1 if it is part of the solution}  
function resolve (row,col:uint16):uint16;
  var QWERTY,mySquare: uint16;
  begin
    {assume not resolved}
    {writeln ('resolve, row:',row,', col:',col);}

    {right now, TinyPascal can not read the function
     return value in the function itself, so use a 
     temp and return that at the end}
    QWERTY := 0;

    if (row >=1) and (row <= maxrow) 
      and (col >=1) and (col <=maxcol) then begin

      {find out where we are on the board}
      mySquare := rcToMatrix(row,col);

      {are we on a free cell or on a wall??}
      if peek(mySquare) = freecell then begin
        {mark visited}
        poke(mySquare, visitedcell);

        {are we at exit?}
        if (row = xitrow) and (col = xitcol) then begin
          QWERTY := 1;
          end
        else
          {go west, east, north, south...}
          begin
          if (QWERTY = 0) then QWERTY := resolve(row-1,col);
          if (QWERTY = 0) then QWERTY := resolve(row,col-1);
          if (QWERTY = 0) then QWERTY := resolve(row+1,col);
          if (QWERTY = 0) then QWERTY := resolve(row,col+1);
        end;
        if QWERTY = 1 then poke(mySquare, pathcell);
      end;
    end;
    {place the result in the function result}
    resolve := QWERTY;
  end;


begin
  {constants}
  maxcellcount := 800;

  freecell := ' ';
  wallcell := '#';
  visitedcell := '.';
  pathcell := 'o';


  writeln('looking to see where RAM is');
  poke(0xA000,'q');
  if peek(0xA000) = 'q'then locn := 0xA000
  else
    begin
      poke(0x2000,'q');
      if peek(0x2000) = 'q'then locn := 0x2000
      else writeln('WARNING, could not find free RAM');
    end;
  writeln('using RAM at:',locn);

  writeln('makeMatrix...');
  makematrix2;
{
  writeln('printMatrix...');
  printmatrix;
  writeln('solving...');
}


  solved := resolve(entrow,entcol);
  if solved = 1 then writeln ('solved')
  else writeln('not solvable');
  printmatrix;
end.
