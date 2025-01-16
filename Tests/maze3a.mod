{program maze (input,output);}

var maxcol, maxrow: uint16;
    freecell,wallcell,visitedcell,pathcell: char;
    {matrix: array[1..maxcellcount] of char;}
    entranceSquare: uint16;
    exitSquare:     uint16;
    solved:         uint16;
    entrow,entcol,
    xitrow,xitcol:  uint16;

    maxcellcount: uint16;
    locn:           uint16;  {location where peek/poke should go}

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

{ here is what the maze should look like,
  with column/row numbers, and pointers for
  start and finish places:

00000000011
12345678901
in   !    
##### ##### 01
#       # # 02
#######   # 03
#     ### # 04
# ### ### # 05
#   #   # # 06
##  ### # # 07
#   #   # # 08
# # ### # # 09
# #   #   # 10
##### ##### 11
out  ! 

00000000011
12345678901
}

{smaller matrix. search for "makematrix2" for a larger one}
{runs faster, and less recursion, so stack smashing is not
 a problem on 32k RAM 1802 machines.}

procedure makematrix3;
  var i,j: uint16;
  begin
    maxrow := 11;
    maxcol := 11;

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
      for j := 1 to maxcol do begin
        {writeln ('making cells free, i:',i,' j:',j);}
        poke(rcToMatrix(i,j), freecell);
      end;

    {draw box around puzzle}
    {row,col, row,col}
    horizontalLine(1,1,1,11);
    horizontalLine(11,1,11,11);
    verticalLine(1,1,11,1);
    verticalLine(1,11,11,11);
    
    {make an entrance and an exit}
    entrow := 1; entcol := 6;
    entranceSquare := rcToMatrix(entrow,entcol);
    poke(entranceSquare, freecell);
    xitrow := 11; xitcol := 6;
    exitSquare := rcToMatrix(xitrow,xitcol); 
    poke(exitSquare, freecell);
 
    {writeln('             row, col:');
    writeln('entrance:',entrow,entcol);
    writeln('exit:    ',xitrow,xitcol);}

    
    {Horizontal lines}
    {after the frame around the outside,
     I just "rasterized" the interior walls
     and these lines short/long horizontal
     lines are drawn here:}
    horizontalLine(3,1,3,7);
    horizontalLine(4,7,4,9);
    horizontalLine(5,3,5,5);
    horizontalLine(5,7,5,9);
    horizontalLine(6,5,6,5);
    horizontalLine(6,9,6,9);
    horizontalLine(7,1,7,2);
    horizontalLine(7,5,7,7);
    horizontalLine(7,9,7,9);
    horizontalLine(8,5,8,5);
    horizontalLine(8,9,8,9);
    horizontalLine(8,9,8,9);
    horizontalLine(9,3,9,3);
    horizontalLine(9,5,9,7);
    horizontalLine(9,9,9,9);
    horizontalLine(10,3,10,3);
    horizontalLine(10,7,10,7);
    {Vertical lines}
    {note that we just used 1 cell horizontal
     lines for filling in single dots on each line}
    
  end; {makematrix3}

{print the matrix. If solved, we print the
 final path found , and change the "visitedcell" 
 indicator to a "freecell" (a space char) to make
 it easier to read}

procedure printmatrix;
  var r,c: uint16;
  var i:   uint16;
  var ch: char;
  begin
    for r := 1 to maxrow do
      begin
        write ('row:',r,' ');
        for c := 1 to maxcol do begin
          i := rcToMatrix(r,c);

          {note the type change; type checking
           is not working 100% yet, but, for the
           write, we need it to be a char, so
           ...}
          i := peek(i);
          if i=visitedcell then i := freecell;
{doing some bounds checking}
{if i > 127 then i := 'X';
if i < 32 then i := 'x';
}

          ch := i;

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

  { where the matrix array is}
{1802 membership}
  locn := 0xA000;

{Pascal compiler}
  {locn := 0x000;}

  writeln('makeMatrix...');
  makematrix3;
  writeln('printMatrix...');
  printmatrix;
  writeln('solving...');


  solved := resolve(entrow,entcol);
  if solved = 1 then writeln ('solved')
  else writeln('not solvable');
  printmatrix;


end.
