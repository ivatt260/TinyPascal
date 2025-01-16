program TinyPascal(input,output);

{$mode ISO}

(*******************************************************
 * TinyPascal p-code compiler, targeted to the RCA CDP 1802
 *
 * The basis of this compiler, and the interpreter, came from
 * Niclaus Worths' Algorithms + Data Structures = Programs
 *
 * book circa 1979.
 *
 * It has been modified to provide a "Tiny" version of the
 * Pascal language, targeted to 8 and 16 bit processors.
 *
 * John A. Stewart, January 13, 2025
 ******************************************************)

(*
 
Dec 11  - Functions and 1802 code, SHL 1 for the ax param.

Nov 30  - Functions - in the function itself, you can only
          assign a value to the function, you can not read
          it. (ie write only, but should be read/write)

Nov 21  - disabled error(typeMismatch) as, the following was
          too confusing for it. (i.e. needs more work...)
              if (1>some_variable) then writeln('true');
          because of the ()s and passing types into expression.

Nov 12  - working on peek poke array and read in hex numbers.

Nov 04  - procedures and functions appear to be working.

Sept 30 - filling in parameters for procedures, not really coded well yet.

Sep 27 - Versioning added. Loads a LIT on stack, then
	 gives it an OPR 0,version, and the interpreter checks
	 for matching version number.

Sep 15 - change getch to convert uppercase to lowercase for
         keywords. A bad way of doing it, but at least it
         works.

Sep 5 - write/writeln for char strings and uint16s working.
  On assembler output, 
	TXOUT, IO_charString, address of static string,
               string is in assembler listing, null terminated.
	TXOUT, IO_uint16, 0 - uint16 is on the stack.
  writelns write an IO_charString, with 0x0a 0x0d 0x00.

Aug 9 statement - variable/procedure - no need to prepend with "call"
prepping for function/procedure calls with parameters.

 
Aug 4 have Write and Writeln with uint16 and charString working.

July 31 - added function for to downto 
	  added keywords: case write writeln

JAS - moving closer to real pascal 
	- change PL0 "condition" to Pascal "Expression" 
	- change PL0 "expression" to Pascal "simple expression"
	- remove "ODD" keyword

   - if-then-else (the else condition) added.
   - repeat-until added.

*)


{JAS - starting assembler printout;
        - added operators "ret" and "xit"
        - goes to fixed-name assembler output file.
{JAS - July12 2024, writing output to assembler code for RCA1802}
{JAS - June23 2024, working on error prints, and on following the "base" flow}

{TinyPascal compiler with code generation}

label 99;

	const norw = 30;      {no. of reserved words}
	   txmax = 200;       {length of identifier table}
	   nmax = 5;         {max. no. of digits in numbers}
	   al = 10;           {length of identifiers}
	   amax = 32768;       {maximum address}
	   uint16amax = 65536;      {maximum uint16}
	   levmax = 20;       {maximum depth of block nesting}
	   cxmax = 20000;     {size of code array}
	   constCharMax=1024; {size of static string store}
	   maxparams=10;      {max number of params for func/proc}

	   DlSlRa_proc = 3;   {stack space for dynamic link, static
			       link and return address for procedures}

	   DlSlRa_func = 3;   {stack space for dynamic link, static
			       link and return address for functions}




	(* I/O for read/write *)
	(* keep these the same for the interpreter *)
	const IO_newLine = 0;
	const IO_charString = 1;
	const IO_uint16 = 2;
	const IO_char = 3;

	(* used for generating a CR-LF on output *)
	const IO_Write = 32;
	const IO_Writeln = 33;

	const opr_neg = 1;   {negative number}
	const opr_plus = 2;  {plus}
	const opr_minus= 3;  {minus}
	const opr_mul = 4;   {multiply}
	const opr_div = 5;   {divide}
        (*
	const opr_odd = 6;   {odd}
	*)
	const opr_mod = 7;   {MOD}
	const opr_eql = 8;   {eql}
	const opr_neq = 9;   {neq}
	const opr_lss = 10;  {lss}
	const opr_geq = 11;  {geq}
	const opr_gtr = 12;  {gtr}
	const opr_leq = 13;  {leq}
        const opr_and = 14;  {and}
        const opr_or  = 15;  {or}
        const opr_not = 16;  {NOT}

        const opr_peek= 17;  {peek at RAM}
        const opr_poke= 18;  {poke at RAM}


	type errorsym = (eqlExpected, constExpected, varExpected,
		stmtBegsym, paramTypErr, boolErr,
		identexpected,
		stringStore,
		semicolonExpected,
		colonExpected, charExpected,
		CVPFexpected,blockEnd,
		periodExpected, idNotFound, 
		assignToConstant, 
		becomesExpected, identifierExpected,
		procedureExpected, thenExpected, endExpected, doExpected, statenderr, 
		constVarExpected, rparenexpected,
		lparenexpected, commaExpected,
		facbegerr, typeMismatch, charsOnlyinFactor,
		nountil, nmaxnumexpected,blocknumexpected, facnumexpected,procedureLevel);

	{Expression types}

	type vType = (noType,booleanType,uint16Type,integerType,charType,stringType);

	type symbol =
	   (nul,ident,number,quote,charString,plus,minus,times,slash,
	    eql,neq,lss,leq,gtr,geq,lparen,rparen,comma,semicolon,
	    colon,period,becomes,beginsym,endsym,ifsym,thensym,
	    whilesym,dosym,constsym,varsym,procsym,
	    elsesym,repeatsym,untilsym, peeksym, pokesym, arraysym,
	    charsym, int16sym,uint16sym,
            andsym, divsym, modsym, notsym, orsym,
  	    funcsym,forsym,tosym,downtosym,casesym,writesym,writelnsym);

    alfa = packed array [1..al] of char;
    obj = (constant,varible,proc,func,onbekend);
    symset = set of symbol;

    fct = (lit,opr,lod,sto,cal,int,jmp,jpc,ret,tot,tin,xit,stk,ver);   {functions}
    instruction = packed record
                     fn: fct;           {function code}
                     lv: 0..levmax;     {level}
                     ax: 0..amax        {displacement address}
                  end;
{   lit 0,a  :  load constant a
    opr 0,a  :  execute operation a
    lod l,a  :  load varible l,a
    sto l,a  :  store varible l,a
    cal l,a  :  call procedure a at level l
    int 0,a  :  increment t-register by a
    jmp 0,a  :  jump to a
    jpc 0,a  :  jump conditional to a
    ret 0,a  :  return from a procedure call
    tot 0, a : write out a number/string to the output stream
    tin 0, a : read in a number/string from the input stream.
    xit 0,a  :  exit the program.   
    stk l,a  :  increment/decrement stack by a words (16 bits)
}

var ch: char;         {last character read}
    sym: symbol;      {last symbol read}
    id: alfa;         {last identifier read}
    num: integer;     {last number read}
    cc: integer;      {character count}
    ll: integer;      {line length}
    kk, errcount: integer;
    cx: integer;      {code allocation index}
    line: array [1..81] of char;
    a: alfa;
    code: array [0..cxmax] of instruction;
    word: array [1..norw] of alfa;
    wsym: array [1..norw] of symbol;
    ssym: array [char] of symbol;
    mnemonic: array [fct] of
                 packed array [1..5] of char;
    (* for writing out assembler *)
    omnemonic: array [fct] of
                 packed array [1..7] of char;
    exprbegsys, simpexsys, declbegsys, statbegsys, facbegsys, termbegsys: symset;
    table: array [0..txmax] of
           record 
              name: alfa;
              typ: vType;
              case kind: obj of
              constant: (val: integer);
              varible, func, proc: (
                  level, adr, nparams: integer;
                  pType: array[1..maxparams] of vType;
                             )
           end;

    {for constant chars - eg, writeln text}
    constCharIndex: integer;
    constStringStart: integer;
    constCharArray: array[0..constCharMax] of char;

    peekPokeMem: array[0..1023] of integer;

(********************************************************)
procedure outToAssembler;


  var i: integer;
  var tfOut: Text;

  begin {list code generated for this block}
    Assign (tfOut,'assemblerOut.asm');
    rewrite(tfOut);
    writeln(tfOut,'; created from PL0 compiler');
    writeln(tfOut);
    writeln(tfOut,'OPLIT      EQU 000H');
    writeln(tfOut,'OPOPR      EQU 001H');
    writeln(tfOut,'OPLOD      EQU 002H');
    writeln(tfOut,'OPSTO      EQU 003H');
    writeln(tfOut,'OPCAL      EQU 004H');
    writeln(tfOut,'OPINT      EQU 005H');
    writeln(tfOut,'OPJMP      EQU 006H');
    writeln(tfOut,'OPJPC      EQU 007H');
    writeln(tfOut,'OPXIT      EQU 008H');
    writeln(tfOut,'OPRET      EQU 009H');
    writeln(tfOut,'TXOUT      EQU 00AH');
    writeln(tfOut,'TXTIN      EQU 00BH');
    writeln(tfOut,'OPSTK      EQU 00CH');
    writeln(tfOut,'OPVER      EQU 00DH');
    writeln(tfOut);
    writeln(tfOut,'PLPROG    EQU 08000H + 0800H');
    writeln(tfOut,'          ORG  PLPROG');
    writeln(tfOut);

      for i := 0 to cx-1 do
         with code[i] do
            begin
              writeln(tfOut);
              writeln(tfOut, ';  ', i:5, mnemonic[fn]:5, lv:3, ax:5);
              writeln(tfOut, '          DB   ',omnemonic[fn]);
              writeln(tfOut, '          DB ',lv:5);

              case fn of
                opr: begin
                  writeln(tfOut, '          DW ',ax:5);
                end;
  
                stk: begin
                  writeln(tfOut, '          DW     (',ax:0,' SHL 1)');
                end;

                lit: begin
                  writeln(tfOut, '          DW ',ax:5);
                end;
  
                lod: begin
                  writeln(tfOut, '          DW     (',ax:0,' SHL 1)');
                end;
  
                sto: begin
                  writeln(tfOut, '          DW     (',ax:0,' SHL 1)');
                end;
  
                cal: begin
                  writeln(tfOut, '          DW     PLPROG + (',ax:0,' SHL 2)');
                end;
  
                int: begin
                  writeln(tfOut, '          DW     (',ax:0,' SHL 1)');
                end;
  
                jmp: begin
                  writeln(tfOut, '          DW     PLPROG + (',ax:0,' SHL 2)');
                end;
  
                jpc: begin
                  writeln(tfOut, '          DW     PLPROG + (',ax:0,' SHL 2)');
                end;

                ret: begin
                  writeln(tfOut, '          DW ',ax:5);
                end;
  
                xit: begin
                  writeln(tfOut, '          DW ',ax:5);
                end;

                tot: begin
                  if lv = IO_charString then
                  writeln(tfOut, '          DW     CONSTCHARTXT+',ax:0)
                  else if (lv = IO_uint16) or (lv = IO_char) then
                  writeln(tfOut, '          DW     0 ; uint16, on stack')
                  else begin

                  writeln(tfOut, 'XXX unknown type, ',lv);
                  writeln('text out,  unknown type, ',lv);
                  end;
                end;

                tin: begin
                  writeln(tfOut, 'text in not implemented yet');
                end;

                ver: begin
                  writeln(tfOut, '          DW ',ax:5);
                end;
  
             end;
    end;

    {write out any character strings here}
    writeln(tfOut);
    writeln(tfOut,'CONSTCHARTXT');
    for i := 0 to constCharIndex do
      writeln(tfOut, '          DB ',
         Ord(constCharArray[i]), '    ;  ',
         constCharArray[i]); 

    writeln(tfOut,'        END');
    close(tfOut);
  end {outToAssembler};


(********************************************************)
procedure printvType(mysym:vType);
  begin
    case mysym of
      noType:      write ('noType  ');
      booleanType: write ('boolean ');
      uint16Type:  write ('uint16  ');
      integerType: write ('integer ');
      charType:    write ('char    ');
      stringType:  write ('string  ');
    end;
  end;

procedure printSym (mysym:symbol);
  begin
    write('printSym: ');
    case mysym of
      nul: writeln('nul');
      ident: writeln('ident');
      number: writeln('number');
      charString: writeln('charString');
      plus: writeln('plus');
      minus: writeln('minus');
      times: writeln('times');
      slash: writeln('slash');
      eql: writeln('eql');
      neq: writeln('neq');
      lss: writeln('lss');
      leq: writeln('leq');
      gtr: writeln('gtr');
      geq: writeln('geq');
      lparen: writeln('lparen');
      rparen: writeln('rparen');
      comma: writeln('comma');
      semicolon: writeln('semicolon');
      colon: writeln('colon');
      period: writeln('period');
      becomes: writeln('becomes');
      beginsym: writeln('beginsym');
      endsym: writeln('endsym');
      ifsym: writeln('ifsym');
      thensym: writeln('thensym');
      whilesym: writeln('whilesym');
      dosym: writeln('dosym');
      constsym: writeln('constsym');
      varsym: writeln('varsym');
      procsym: writeln('procsym');
      elsesym: writeln('elsesym');
      repeatsym: writeln('repeatsym');
      untilsym: writeln('untilsym');
      charsym: writeln('charsym');
      int16sym: writeln('int16sym');
      uint16sym: writeln('uint16sym');
      funcsym: writeln('funcsym');
      forsym: writeln('forsym');
      tosym: writeln('tosym');
      downtosym: writeln('downtosym');
      casesym: writeln('casesym');
      writesym: writeln('writesym');
      writelnsym: writeln('writelnsym');
      andsym: writeln('andsym');
      orsym: writeln('orsym');
      notsym: writeln('notsym');
      divsym: writeln('divsym');
      modsym: writeln('modsym');
      else writeln('sym not decoded');
    end;
  end;
(********************************************************)

procedure error(n: errorsym);
begin
  {writeln(' ****',' ': cc-1, '^',n: 2); errcount := errcount+1;}
  writeln(' ****',' ': cc-1, '^'); errcount := errcount+1;
  case n of
      paramTypErr : writeln('parameter type mismatch');
      periodExpected : writeln('"." expected');
      colonExpected : writeln('":" expected');
      semicolonExpected : writeln('";" expected');
      eqlExpected: writeln('"=" expected');
      rparenexpected : writeln('")" expected');
      lparenexpected : writeln('"(" expected');
      becomesExpected : writeln('":=" expected');
      commaExpected : writeln('"," expected');

      thenExpected : writeln('keyword "then" expected');
      endExpected : writeln('keyword "end" expected');
      doExpected : writeln('keyword "do" expected');
      nountil: writeln('keyword "until" expected');

      charExpected : writeln('char type expected');
      constExpected: writeln('constant expected');
      varExpected: writeln('const ident found, can not assign to it');
      identExpected: writeln('identifier expected');
      stmtBegsym: writeln('can not start a statement with this');
      stringStore: writeln('constant string store overflow');
      CVPFexpected: writeln('"const", "var", "procedure", "function" expected');
      blockEnd: writeln('keyword can not end a block');
      idNotFound : writeln('id not found');
      assignToConstant : writeln('cant assign a value to constant here');
      identifierExpected: writeln('identifier expected');
      procedureExpected : writeln('procedure ident expected');
      statenderr : writeln('unexpected text at end of statement');
      constVarExpected : writeln('constant or variable expected');
      facbegerr: writeln ('expected factor keywords');
      charsOnlyinFactor: writeln ('charString found, but currently only support chars here');
      typeMismatch: writeln('type mismatch');
      boolErr: writeln('found boolean comparitors, but not a boolean expression?');
      blocknumexpected : writeln('blocknumber expected');
      nmaxnumexpected : writeln('nmaxnumber expected');
      facnumexpected : writeln('facnumber expected');
      procedureLevel: writeln('procedure nesting too great, recompile with bigger levmax constant');
      else writeln('err not decoded... complain please');
      end

end {error};

procedure getsym;
   var i,j,k: integer;
   isHexNumber : boolean;
   thoughtItMightBeHex : boolean;

   function toUpper(ch: char) : char;
   { change uppercase to lowercase - so we are
     case insensitive}
   begin
     { brain dead way of doing this, for now...}
     if ch in ['A'..'Z'] then
       begin
         case ch of
           'A': ch := 'a';
           'B': ch := 'b';
           'C': ch := 'c';
           'D': ch := 'd';
           'E': ch := 'e';
           'F': ch := 'f';
           'G': ch := 'g';
           'H': ch := 'h';
           'I': ch := 'i';
           'J': ch := 'j';
           'K': ch := 'k';
           'L': ch := 'l';
           'M': ch := 'm';
           'N': ch := 'n';
           'O': ch := 'o';
           'P': ch := 'p';
           'Q': ch := 'q';
           'R': ch := 'r';
           'S': ch := 's';
           'T': ch := 't';
           'U': ch := 'u';
           'V': ch := 'v';
           'W': ch := 'w';
           'X': ch := 'x';
           'Y': ch := 'y';
           'Z': ch := 'z';
         end;
       end;
       toUpper := ch;
     end {toUpper};

   procedure getch;
   begin if cc = ll then
      begin if eof(input) then
                 begin write(' program incomplete'); goto 99
                 end;
         ll := 0; cc := 0; 
         write(cx: 5,' ');
         while not eoln(input) do
            begin 
              ll := ll+1; 
              read(ch); 
              write(ch); 
              line[ll]:=ch
            end;
         writeln;

         readln; ll := ll + 1; line[ll] := ' ';
      end;
      cc := cc+1; ch := line[cc];
      {writeln('getch returning:',ch);}
   end {getch};


(********************************************************)
procedure constCharString();
  begin

   getch;
   sym := charString;
   constStringStart := constCharIndex;
   {writeln('in getsym, constStringStart=',constStringStart);
   {writeln('in getsym, constCharIndex=',constCharIndex);}
   while ch <> '''' do
     begin
       {save this string away}
       constCharArray[constCharIndex] := ch;
       constCharIndex := constCharIndex+1;
       if constCharIndex >= constCharMax then begin
         error(stringStore);
         constCharIndex := 0;
       end;
       getch;
     end;
     {make last character a nul}
     constCharArray[constCharIndex] := #0;
     constCharIndex := constCharIndex+1;
     {writeln('in getsym2, constStringStart=',constStringStart);
      writeln('in getsym2, constCharIndex=',constCharIndex);}
   getch
  end {constCharString};


begin {getsym}
   while ch  = ' ' do getch;

   {start of comment}
   while ch = '{' do begin
     repeat 
       getch 
     until ch = '}';
     getch; {get character after closebrace}
     {then go and skip blanks}
     while ch  = ' ' do getch;
   end;

   ch := toUpper(ch);

   if ch in ['a'..'z'] then
   begin {identifier or reserved word} k := 0;
      repeat if k < al then
         begin k := k+1; a[k] := ch
         end;
         getch;
         ch := toUpper(ch);
      until not(ch in ['a'..'z','0'..'9']);
      if k >= kk then kk := k else
         repeat a[kk] := ' '; kk := kk-1
         until kk = k;
      id := a; i := 1; j := norw;
      repeat k := (i+j) div 2;
         if id <= word[k] then j := k-1;
         if id >= word[k] then i := k+1
      until i > j;
      if i-1 > j then sym := wsym[k] else sym := ident

   end else

   if ch in ['0'..'9'] then
   begin {number} 
     k := 0; 
     num := 0; 
     sym := number;
     isHexNumber := false;
     thoughtItMightBeHex := false;

     {is this a possible "0X" hexadecimal number?}
     if ch='0' then
       begin
         getch; 
         if (ch='X') or (ch='x') then
           isHexNumber := true
         else
           {ok, first character is 0, second char
            is NOT X; right now we have the char
            AFTER the 0 - if it is NOT a number
            (eg, a semicolon) we have an issue,
            so assign 0 to the just-got character
            and continue along, but knowing that
            the first getch is already done}

            thoughtItMightBeHex := true;
            {writeln('thoughtitmight, current ch:',ch);}
       end;

     {if (isHexNumber) then writeln('have a hex...') else writeln('not a hex....');}

     if isHexNumber then
       begin
        repeat num := 16*num;
          if ch in ['0'..'9'] then num := num + (ord(ch)-ord('0'));
          if ch in ['A'..'F'] then num := num + 10+ (ord(ch)-ord('A'));
          k := k+1; 
          getch;
        until not(ch in ['0'..'9','A'..'F']);
       end
     else
       begin
        repeat 
          {if we have the next character when testing for hexadecimal,
           but it is NOT (maybe a semicolon??) then use the current value
           and do not do the getch. eg. var := 0; - 2nd char is semicolon}

          if (thoughtItMightBeHex = true) then begin
            thoughtItMightBeHex := false
          end else begin
            num := 10*num + (ord(ch)-ord('0'));
            getch;
          end;

          k := k+1;

        until not(ch in ['0'..'9']);
        end;
     if k > nmax then error(nmaxnumexpected)
   end else

   if ch = ':' then
   begin getch;
      if ch = '=' then
      begin sym := becomes; getch
      end else sym := colon;
   end else

   if ch = '''' then
   begin 
      {get a const char string}
      constCharString();
   end else

   {find:  <, <=, <>, >, >=, = }
   begin
     {get the sym to be what the single char tells us}
     sym := ssym[ch];

     {see if we have a double char or not }
     {possible neq or lss or leq}
     if ch = '<' then begin
       getch;
       if ch = '>' then begin
         sym := neq; getch
       end
       else if ch = '=' then begin
         sym := leq; getch
         end
       else sym := lss;

     {possible gtr, geq}
     end else if ch = '>' then
       begin
         getch;
         if ch = '=' then
           begin
             sym := geq; getch
           end
         else sym := gtr;

       {eql and all other single chars we do a getch} 
       end else getch;

    end;
   
end {getsym};


(********************************************************)
procedure gen(x: fct; y,z: integer);
begin if cx > cxmax then
           begin write(' program too long'); goto 99
           end;
   with code[cx] do
      begin fn := x; lv := y; ax := z
      end;
   cx := cx + 1
end {gen};

(********************************************************)
procedure test(s1,s2: symset; n: errorsym);
begin if not(sym in s1) then
        begin error(n); s1 := s1 + s2;
           while not(sym in s1) do getsym
        end
end {test};

(*************************************************************)
procedure block(lev,tx: integer; 
                parentType : obj;
                fsys: symset);

   var dx: integer;     {data allocation index}
      tx0: integer;     {initial table index}
        i: integer;     {for loop counter}
      vs:  integer;     {define variables, need to assign type after entry}
      cx0: integer;     {initial code index}
      dxSaved: integer; {parsing of proc/func params}
      varType: vType;   {type of variable on declaration}
      procFunc: obj;    {where is this called from?}
      funcEntry: integer;{table entry if a function}

   {return the vType of a variable, from the sym read in}
   function getType(inty : symbol) : vType;
     begin
        {printSym(inty);}
	if inty = int16sym then getType := integerType
	else if inty = charsym then getType := charType
	else if inty = uint16sym then getType := uint16Type
        else getType := noType
     end {getType};

   procedure enter(k: obj; levInc:integer);
   begin {enter obj into table}
      tx := tx + 1;
      {write('enter, have variable ',id,' writing to tx ',tx:2);
      writeln('levInc ',levInc:4);}

      with table[tx] do
      begin name := id; kind := k;
         case k of
         constant: begin if num > amax then
                              begin error(blocknumexpected); num :=0 end;
                      val := num
                   end;
         {variable, could have parameters that are at the body level}
         varible: begin level := lev+levInc; adr := dx; dx := dx + 1;
                  end;
         proc, func:
                  begin
                    level := lev;
                    nparams := 0;
                  end 
         end
      end
   end {enter};

   function position(id: alfa): integer;
      var i: integer;
   begin {find indentifier id in table}
      table[0].name := id; i := tx;
      while table[i].name <> id do i := i-1;
      position := i
   end {position};

   (****************************************)
   procedure constdeclaration;
   begin if sym = ident then
      begin getsym;
         if sym in [eql, becomes] then
         begin if sym = becomes then error(eqlExpected);
            getsym;
            if sym = number then
               begin enter(constant,0); getsym
               end
            else if sym = quote then 
               begin
               writeln ('constdeclaration, have a quote?');
               end
            else
               error(constExpected)


         end else error(eqlExpected)
      end else error(identifierExpected)
   end {constdeclaration};


   (****************************************)
   procedure vardeclaration(levInt: integer);
   
   {note, levInt - normally zero, but for procedure/function
    parameters, they are used at the next level, the body
    of the procedure/function, so the level is +1 more than 
    current level}

   begin if sym = ident then
           begin enter(varible,levInt); getsym
           end else error(identifierExpected)
   end {vardeclaration};

   (****************************************)
   procedure listcode;
      var i: integer;
   begin {list code generated for this block}
      for i := cx0 to cx-1 do
         with code[i] do
            writeln(i:5, mnemonic[fn]:5, lv:3, ax:5)
   end {listcode};

   (****************************************)
{ notes

    table: array [0..txmax] of
           record name: alfa;
              case kind: obj of
              constant: (val: integer);
              varible, proc: (level, adr: integer)
           end;
}
   procedure printTable;
     var i,j: integer;
     
     begin
     writeln ('---------------------------------------------');
     {writeln ('printTable for index ',tx0+1:3,' to ',tx:3);}
     {for i := tx0+1 to tx do}

     writeln ('printTable for index ',1:3,' to ',tx:3);
     for i := 1 to tx do
       with table[i] do
         begin
         write(i:3,' ',name,' ');
         printvType(typ);
         case kind of
           constant: begin
              write ('const: value ',val);
           end;
           varible: begin
              write ('var:   level ',level:3,' stack ',adr:3);
           end;
           proc: begin
              write ('proc:  level ',level:3,' @code ',adr:3,' nparams:',nparams:2);
              writeln();
              for j := 1 to nparams do
                begin
                write('                      param:',j:2,' type: ');
                printvType(ptype[j]);
                writeln();
                end;
           end;
           func: begin
              write ('func:  level ',level:3,' @code ',adr:3,' nparams:',nparams:2);
              writeln();
              for j := 1 to nparams do
                begin
                write('                      param:',j:2,' type: ');
                printvType(ptype[j]);
                writeln();
                end;
           end;
         end;

         writeln();
         end;

       writeln ('---------------------------------------------');
     end {printTable};

(************************************************************)
   procedure statement(fsys: symset);
      var i:integer;
      var returnedTyp: vType;
      {var endsym: symbol;}


(************************************************************)
    function expression(fsys: symset; typ:vType): vType;
         var relop: symbol;
         var returnedTypLHS, returnedTypRHS : vType;

(************************************************************)
      function simpleExpression(fsys: symset; typ:vType) : vType;
         var addop: symbol;
         var returnedTyp: vType;
         var expectedTyp: vType;

(************************************************************)
         function term(fsys: symset; typ:vType): vType;
            var termop: symbol;

(************************************************************)

{functions, with () and params, parse these params}
function parseFuncParams(i:integer) :vType;
  var pcount : integer;

  begin

    {writeln('parseFuncParams, ...'); printSym(sym);}

 
    pcount := 0;
    with table[i] do
      begin
        { first, what is the type? this is what we return}
        returnedTyp := typ;

        {keep track of the number of parameters}

        if sym = lparen then begin
          getsym;
          {create space for parameters}
          gen(stk, 1, DlSlRa_func+1);
          repeat

            {possible to get a "()" pair for zero paramters}
            {do expression if we have the parameter}
            if nparams > 0 then
              begin
              pcount := pcount+1;
              {get the type we expect, and get the returned type}
              expectedTyp := pType[pcount];
              returnedTyp := 
                expression([rparen,comma]+fsys,expectedTyp);
              if expectedTyp <> returnedTyp then
                begin
                    write('note: parseFuncParams, body expectedTyp ');
                     printvType(expectedTyp);writeln();
                    write('note: parseFuncParams, body returnedTyp ');
                     printvType(returnedTyp);writeln();
                  error(paramTypErr);
                end;

              {check if we should expect a comma or not}
              if pcount < nparams then
                begin
                if sym=comma then getsym else error(commaExpected);
                end;
              {else writeln ('pcount >= nparams');}

              end;
          until (pcount >= nparams);
          {remove space for parameters}
          gen(stk, 0, DlSlRa_func + nparams+1);
        end;
      gen(cal, lev-level, adr);
    end;
  parseFuncParams := returnedTyp;
end;

(************************************************************)

            function factor(fsys: symset; typ:vType): vType;
               var i: integer;
            begin 

               expectedTyp := typ;
               returnedTyp := noType;

               test(facbegsys, fsys, facbegerr);
               while sym in facbegsys do begin
                  {write ('while sym in facbegsys... '); printSym(sym);}
                  if sym = ident then begin
                    i:= position(id);
                    if i = 0 then error(idNotFound) else
                    with table[i] do
                     case kind of
                        constant: begin
                          returnedTyp := typ; 
                          gen(lit, 0, val);
                          end;
                        varible: begin
                          returnedTyp := typ; 
                          gen(lod, lev-level, adr);
                          end;
                        proc: begin
                          error(constVarExpected)
                          end;
                        func: begin
                          getsym;
                          returnedTyp := parseFuncParams(i);
                          end;
                     end; {case}
                     getsym
                   end {ident}

                 else if sym = number then begin
                   if num >  uint16amax then
                           begin error(facnumexpected); num := 0
                           end;
                           returnedTyp := uint16Type;
                   gen(lit, 0, num); 
                   getsym
                 end {number}

                 else if sym = charString then begin
                   returnedTyp := charType;

                   {writeln ('factor, have charString of size ',
                         constCharIndex - constStringStart,  
                         ' char as decimal ',byte(constCharArray[constStringStart])
                        );}

                   gen(lit, 0, byte(constCharArray[constStringStart]));

                   if constCharIndex-constStringStart <> 2 then
                     error(charsOnlyinFactor);

                   getsym
                 end {charString}

                 else if sym = lparen then begin
                   getsym; 
                   {writeln('factor, lparen, expectedTyp '); printvType(expectedTyp);}

                   returnedTyp := expression([rparen]+fsys,expectedTyp);
                   if sym = rparen then getsym else error(rparenexpected)
                 end {lparen}

                 else if sym = peeksym then begin
                   getsym;
                   if sym = lparen then begin
                     getsym;
                     expectedTyp := charType;
                     returnedTyp := expression([rparen]+fsys,expectedTyp);
                     gen(opr,0,opr_peek);
                     if sym = rparen then getsym else error(rparenexpected)
                   end
                     else error (lparenexpected);
                 end {peek}
               
                 else if sym = notsym then begin
                   getsym;
                   returnedTyp := factor(fsys,typ);
                   gen(opr,0,opr_not);
                 end
               end; {while}

               {  write('note: factor, expectedTyp ');
                  printvType(expectedTyp);writeln();
                 write('note: factor, returnedTyp ');
                  printvType(returnedTyp);writeln();}

               {test the types}
               if expectedTyp <> returnedTyp then begin
                 if expectedTyp = noType then begin
                   {FACTOR, we NOW have the type we need}
                 end else begin
                   {use the expected type as the type in error condition}
                   {error(typeMismatch);}
                   returnedTyp := expectedTyp;
                 end;
               end; {type check}
             test(fsys, [rparen], rparenexpected);

             {write('note: factor, returning ');
             printvType(returnedTyp);writeln();}

             factor := returnedTyp;
           end {factor};

(************************************************************)
         begin {term} 
           returnedTyp := factor(fsys+termbegsys,typ);

            {write('note: term, at start typ ');
             printvType(typ);writeln();
             write('note: term, at start returnedTyp ');
             printvType(returnedTyp);writeln(); }

            expectedTyp := returnedTyp;

            while sym in termbegsys do begin
               termop:=sym;
               getsym;
               returnedTyp := factor(fsys+termbegsys,expectedTyp);

               { do term operation }
               if termop=times then gen(opr,0,opr_mul) 
               else if termop = slash then gen(opr,0,opr_div)
               else if termop = divsym then gen(opr,0,opr_div)
               else if termop = modsym then gen(opr,0,opr_mod)
               else if termop = andsym then gen(opr,0,opr_and)

               else begin
                 writeln ('term op not supported yet');
               end {if chain}
             end; {while}

             {write('note: term returning typ ');
             printvType(returnedTyp);writeln();}

           term := returnedTyp;
         end {term};

(************************************************************)
      begin {simpleExpression}

        {Write('note: simpleExpression, start typ    ');
        printvType(typ);writeln();}

        returnedTyp := noType;
        expectedTyp := noType;

         if sym in simpexsys then
            begin 
              addop := sym; 
              getsym; 
              returnedTyp := term(fsys+simpexsys,typ);
              if addop = minus then gen(opr, 0,opr_neg)
            end 
         else returnedTyp := term(fsys+simpexsys,typ);

         {Write('note: simpleExpression, returnedTyp    ');
          printvType(returnedTyp);writeln();}

        expectedTyp := returnedTyp;

         while sym in simpexsys do
            begin 
              addop := sym; 
              getsym; 
              returnedTyp := term(fsys+simpexsys,typ);

              if addop=plus then
                 gen(opr,0,opr_plus)
              else if addop = minus then
                 gen(opr,0,opr_minus)
              else gen(opr,0,opr_or);
        
              {Write('note:  in while: simpleExpression, returnedTyp    ');
                printvType(returnedTyp);writeln();}
            end;

            {  Write('note: simpleExpression, returning   ');
              printvType(returnedTyp);writeln();}

         simpleExpression := returnedTyp;
      end {simpleExpression};

(************************************************************)
      begin {expression}
         {write('note: expression, type ');printvType(typ);writeln();
          write('and, current sym is ');printSym(sym);}

         {is this a boolean condition, or an assignment?}
         returnedTypLHS := noType;
         returnedTypRHS := noType;


         {ask simpleExpression to give us the type it thinks it is}
         {boolean expression, tell us that it is expecting a boolean}

         if typ=booleanType then
         returnedTypLHS := simpleExpression(fsys+exprbegsys,booleanType)
         else
         returnedTypLHS := simpleExpression(fsys+exprbegsys,noType);

         if (sym in exprbegsys) then
           begin 
             {if we are expecting a boolean expression, then...}
             if typ = booleanType then
               begin
                   relop := sym; 
                   getsym; 
                   returnedTypRHS := simpleExpression(fsys,noType);
    
                   {write('expression, boolean cond: returnedTypLHS ');
                   printvType(returnedTypLHS); writeln();
                   write('expression, boolean cond: returnedTypRHS ');
                   printvType(returnedTypRHS); writeln();}
                   
    
                   {data type check}
                   {if returnedTypLHS <> returnedTypRHS then
                     error (typeMismatch);}
    
                   case relop of
                      eql: gen(opr, 0, opr_eql);
                      neq: gen(opr, 0, opr_neq);
                      lss: gen(opr, 0, opr_lss);
                      geq: gen(opr, 0, opr_geq);
                      gtr: gen(opr, 0, opr_gtr);
                      leq: gen(opr, 0, opr_leq);
                   end;
               end 
             else  {if typ = booleanType}
               error (boolErr);
         end; {if sym in eql...}


      {write('expression, returining ');
        printvType(returnedTypLHS);writeln();}

      expression := returnedTypLHS;
      end {expression};


      (************************************************************)
      procedure parseProcParams(i:integer);
        var pcount : integer;
           var returnedTyp: vType;
           var expectedTyp: vType;
        begin
      
          pcount := 0;
          with table[i] do
            begin
              {keep track of the number of parameters}
      
              getsym;
              if sym = lparen then begin
                getsym;
                {create space for parameters}
                gen(stk, 1, DlSlRa_proc);
                repeat
      
                  {possible to get a "()" pair for zero paramters}
                  {do expression if we have the parameter}
                  if nparams > 0 then
                    begin
                    pcount := pcount+1;
                    {get the type we expect, and get the returned type}
                    expectedTyp := pType[pcount];
                    returnedTyp := 
                      expression([rparen,comma]+fsys,expectedTyp);
                    if expectedTyp <> returnedTyp then
                      begin
                    write('note: useFuncParams, body expectedTyp ');
                     printvType(expectedTyp);writeln();
                    write('note: useFuncParams, body returnedTyp ');
                     printvType(returnedTyp);writeln();
                      error(paramTypErr);
                      end;
                    
      
                    {check if we should expect a comma or not}
                    if pcount < nparams then
                      begin
                      if sym=comma then getsym else error(commaExpected);
                      end;
                    {else writeln ('pcount >= nparams');}
      
                    end;
                until (pcount >= nparams);
                {remove space for parameters}
                gen(stk, 0, DlSlRa_proc+nparams);
      
                if sym=rparen then getsym else error(rparenexpected);
      
              end;
              gen(cal, lev-level, adr);
            end
      end;


(************************************************************)
    procedure stmtIdent();
     begin

       i := position(id);
       if i = 0 then error(idNotFound) else
         with table[i] do
           begin
             {writeln('stmtIdent: ID position ',i:2);}

             {write('ident statement start, sym is '); printSym(sym);}
             if kind=proc then 
               parseProcParams(i)
             else if kind=func then
               begin
                 {this is a function, but the shadow variable is 1 above
                  the table index. Increment i so we are pointing at this 
                  shadow variable for variable assignment}
                 with table[i+1] do
                   begin
                     {writeln('stmtIdent, func store; genning sto with table entry ',i+1);}
                     getsym; 
                     if sym = becomes then getsym else error(becomesExpected);
                     returnedTyp := expression(fsys,typ);
                     gen(sto, lev-level, adr)
                   end;
               end
             else if kind=varible then
               begin
                 getsym; 
                 if sym = becomes then getsym else error(becomesExpected);
                 returnedTyp := expression(fsys,typ);
                 gen(sto, lev-level, adr)
               end
           end;
       {write('ident statement end, sym is '); printSym(sym);}
     end {stmtIdent};

(************************************************************)
    procedure stmtIf(typ:vType);
      var cx1, cx2: integer;
        begin 
         getsym; 
         returnedTyp := expression([thensym, dosym]+fsys,typ);
         if sym = thensym then getsym else error(thenExpected);
         cx1 := cx; gen(jpc, 0, 0);
         statement([elsesym]+fsys); 
         {fix up the conditional jump to come here}
         {does this have an else? if so, we will re-fix it below}
         code[cx1].ax := cx;

         if sym = elsesym then 
           begin
             getsym;
             cx2 := cx;
             gen(jmp, 0, 0);
             {have an else, fix the "jpc" to now come after this "jmp"}
             {false condition jmp here}
             code[cx1].ax := cx;
             statement(fsys);
             {true condition jmp here}
             code[cx2].ax := cx;
           end {else}
      end; {stmtIf}

(************************************************************)
    procedure stmtRepeat(typ:vType);
      var cx1: integer;
        begin 
          getsym; 
          cx1 := cx;
          statement([untilsym]+fsys); 
          if sym = semicolon then
            repeat
              getsym;
              statement([untilsym]+fsys); 
            until sym <> semicolon
          else error(semicolonExpected);


          if sym = untilsym then
            begin
              getsym;
              returnedTyp := expression([]+fsys,typ);
              gen (jpc, 0, cx1);
            end
          else
              error(nountil);
        end; {stmtRepeat}

(************************************************************)
    procedure stmtFor(typ:vType);
      var todowntosym: symbol;
      var cx1, cx2: integer;
      var returnedLHS: vType;

        begin
          todowntosym:=nul;
          getsym;
          if sym = ident then
            begin
              i := position(id);
              if i = 0 then error(idNotFound) else
                begin
                if table[i].kind <> varible then
                  error(varExpected);
                end;
              getsym;
              if sym = becomes then
                begin
                  getsym;
                  returnedLHS := expression([tosym,downtosym]+fsys,typ);

                  {Write('note: stmtFor, first returnedTyp: ');
                  printvType(returnedLHS);writeln();}


                  if table[i].kind = varible then begin
                    {store initial value}
                    with table[i] do gen(sto, lev-level, adr);
                    {this is where we loop back to}
                    cx1 := cx;
                    {with table[i] do gen(lod,lev-level,adr+200);}

                  end;

                  if ((sym=tosym) or (sym=downtosym)) then begin
                    todowntosym := sym;
                  getsym;

                  {now, do conditional to see if we exit the for loop}
                  with table[i] do gen(lod, lev-level, adr);
                  returnedTyp := expression([dosym]+fsys,typ);

                  {Write('note: stmtFor, second returnedTyp: ');
                  printvType(returnedTyp);writeln();}

                  {type checking}
                  {if returnedLHS <> returnedTyp then error (typeMismatch);}

                  if todowntosym = tosym then
                    gen(opr,0,13) {tops>=tops+1}
                  else
                    gen(opr,0,11); {tops<=tops+1}

                  { this is the jpc to exit, have to touchup}
                  cx2 := cx; 
                  gen(jpc,0,2000);
                  if sym = dosym then
                    begin
                      getsym;
                      statement(fsys);
                    end;

                  {increment or decrement index}
                  with table[i] do gen(lod, lev-level, adr);
                  gen(lit,0,1);
                  if todowntosym = tosym then
                    gen(opr,0,2) {add}
                  else
                    gen(opr,0,3); {subtract}
                  with table[i] do gen(sto, lev-level, adr);

                  {back up to top}
                  gen(jmp,0,cx1);
                end {to downto}
                 
              end; {becomes}
             
              {fixup the jpc}
              code[cx2].ax := cx

            end 
          else
            error(identexpected);
      end {stmtFor};

(************************************************************)

      procedure stmtWrite(typ:vType);
        var writeWriteln: integer;

        begin
        if sym = writesym then writeWriteln:=IO_Write; {flag here }
        if sym = writelnsym then writeWriteln:=IO_Writeln;
        getsym; 
        if sym=lparen then begin
          getsym;
          repeat

          {this is a bug, can start wit a comma, fixit}
          if sym=comma then getsym;

          if sym = charString then begin
            {save charString away, and use this info below}
            getsym;
            gen(tot,IO_charString,constStringStart);
          end else begin
            {value to print is on the stack}
            returnedTyp := expression([rparen,comma]+fsys,typ);
            if returnedTyp =  uint16Type then
            gen(tot,IO_uint16,0)
            else if returnedTyp = charType then
            gen(tot,IO_char,0)
            else begin

            gen(tot,IO_uint16,0);
            writeln ('in stmtWrite, got a type I have not coded writing for yet');
            end;
          end;
          until sym <> comma;

          if sym=rparen then begin
            getsym;
            {writeln?? vs write}
            if writeWriteln=IO_Writeln then begin
              {CR LF at start of string area}
              gen(tot,IO_charString,0);
            end;
            
          end else error(rparenexpected);
        end else begin
          {write or writeln without the parentheses; maybe just a plain CR wanted}

          if writeWriteln=IO_Writeln then
            {CR LF at start of string area}
            gen(tot,IO_charString,0);
        end {if sym = lparen}

      end {stmtWrite};

(************************************************************)
      procedure stmtWhile(typ:vType);
      var cx1, cx2: integer;
      begin 
         cx1 := cx; 
         getsym; 
         returnedTyp := expression([dosym]+fsys,typ);
         cx2 := cx; 
         gen(jpc, 0, 0);
         if sym = dosym then getsym else error(doExpected);
         statement(fsys); 
         gen(jmp, 0, cx1); 
         code[cx2].ax := cx
      end {stmtWhile};

(************************************************************)
    procedure stmtPoke(typ:vType);
      var myvt: vType;
        begin 
         (* char poke(address,value); *)
{
         if typ <> charType then
           error(charExpected);
}
           
         {write('stmtPoke, typ '); printvType(typ);}

         getsym; 
         if sym = lparen then
           begin
             getsym;
             returnedTyp := expression(fsys+[comma],typ);
             if sym = comma then
               begin
                 getsym;
                 {writeln ('poke, 2nd param, forcing to charType');}
                 myvt := expression(fsys+[rparen],charType);
                 if myvt <> charType then begin
                   write ('myvt is not chartype, is ');
                   printvType(myvt);
                 end;

                 gen(opr,0,opr_poke);
                 if sym = rparen then
                   getsym
               end
             else error (commaExpected);
           end
         else error (lparenExpected);
      end; {stmtPoke}

(************************************************************)
      procedure stmtBegin();
      begin 
        getsym;
        statement([semicolon, endsym]+fsys);
        while sym in [semicolon]+statbegsys do
          begin
            if sym <> semicolon then error(semicolonExpected);
            getsym;
            statement([semicolon, endsym]+fsys)
          end;
        if sym = endsym then getsym else error(endExpected)
      end {stmtBegin};

(************************************************************)
(************************************************************)
   begin {statement}
     {endsym := nul;}

     case sym of
        ident     : stmtIdent();
        ifsym     : stmtIf(booleanType);
        repeatsym : stmtRepeat(booleanType);
        writesym, 
        writelnsym: stmtWrite(noType);
        whilesym  : stmtWhile(noType);
        forsym    : stmtFor(noType);
        pokesym   : stmtPoke(uint16Type);
        beginsym  : stmtBegin();
        else; {if there is an error, catch it somewhere else}
      end;

      {write('end statement, sym is '); printSym(sym);}
      test(fsys, [], statenderr)
   end {statement};
(************************************************************)


procedure parameterList(fromWhere:obj);
  var txOfParamFunc: integer;
      k : obj;
      pi : integer;

  {procedure/func param decls; we can have comma separated types,
   and semicolon separated type lists}

  {plIdentVars parses one possibly-comma-seperated list}
  procedure plIdentVars();
    var mtx: integer;
        mtyp: vType;
        i : integer;
    begin {plIdentVars}

      {varsym not used, just skip it}
      if sym = varsym then getsym;

      {we can have multiple variables separated by commas}
      vardeclaration(1);
      mtx := tx;
      while sym in [comma] do
        begin
          getsym;
          vardeclaration(1);
        end;

      if sym = colon then begin
        getsym;
        {find type here}
        mtyp := getType(sym);

        { copy type into the symbol table}
        for i := mtx to tx do begin
          {writeln('filling in type for table entry ',i:1,table[i].name);}
          table[i].typ := mtyp;
        end;
        getsym;
      end else error (colonExpected);
    end {plIdentVars};

(***********)

  {procedure/func param decls; we can have comma separated types,
   and semicolon separated type lists}
  {plIdentOneVarList scans possibly multiple semicolon separated lists}

  procedure plIdentOneVarlist;
  begin {plIdentOneVarList}
        if sym in [ident,varsym] then
          begin
            plIdentVars;
          end
        else if sym in [procsym, funcsym] then
          begin
          writeln('procedures and functions not implemented in parameterList yet');
          getsym;
          end;
  end; {plIdentOneVarList}


  begin {parameterList}

    {parse a procedure/function parameter list}
    {copy tx, because we'll restore it after parsing
     parameters. We keep the number of parameters,
     and their types, with the proc/func table entry,
     but nobody at this level can see them, only in
     the body of the proc/func}

    txOfParamFunc := tx;
    
    if fromWhere = func then
      begin
        {writeln ('parameterList, from a func');}
        {writeln('pl, txOfParma ',txOfParamFunc);}
        {printvType(table[txOfParamFunc].typ);}
        id:='-rvForMe- ';
        enter (varible,1);
        {table[tx].typ :=  table[txOfParamFunc].typ;}
      end;
    {(write ('parameterList, at start tx=',tx:3);
    writeln(' dx=',dx:3);}

    {handle openBracket and any parameters if they are there}
    if sym = lparen then
      begin
        getsym;
        plIdentOneVarList;
        while sym = semicolon do
          begin;
            getsym;
            plIdentOneVarList;
          end;
        if sym = rparen then getsym else error (rparenExpected);
      end;

    {record the number of paramters here}
    k := table[txOfParamFunc].kind;
    with table[txOfParamFunc] do 
      case k of
         constant: begin 
                   end;
         varible: begin 
                  end;
         proc:
                  begin
                    nparams := tx-txOfParamFunc;
                    for pi := 1 to nparams do
                      begin
                        {write ('copying type of param:',pi:2,' name:',
                        table[pi+txOfParamFunc].name, ' type:');
                        printvType(table[pi+txOfParamFunc].typ);
                        writeln();}

                        pType[pi] := table[pi+txOfParamFunc].typ;                      
                    end;
                  end;
         func:
                  begin
                    {same code as proc, but because of the "shadow" return
                     value variable, we alter nparams and initialization
                     value types}
                    nparams := tx-txOfParamFunc-1;
                    {writeln('pl, func nparams =',nparams:2);}
                    for pi := 1 to nparams do
                      begin
                        {write ('copying type of param:',pi:2,' name:',
                        table[pi+txOfParamFunc].name, ' type:');
                        printvType(table[pi+txOfParamFunc].typ);
                        writeln();}

                        {note the addition of 1 here}
                        pType[pi] := table[pi+txOfParamFunc+1].typ;                      
                    end;
                  end
         end;
    {restore tx to where it was before parsing these parameters}
    tx := txOfParamFunc;

    {writeln(' end parameterlist, tx:',tx:1,' txOfParamFunc:',txOfParamFunc:1);
    writeln(' end paramterList, have #params:', tx -txOfParamFunc);}
  end {parameterList};


begin {block} 
   
   {writeln ('beginning of block,tx:',tx:2,'nparams',table[tx].nparams);}

   { begin block - tx is the index of possibly a function or procedure
    we increment the data param to include not only the 3 normal entries
    (stack, static link, dynamic link) but also the number of parameters
    that the procedure/function call put on the stack}

   if parentType = func then 
     dx := DlSlRa_func + table[tx].nparams+1
   else 
     dx := DlSlRa_proc + table[tx].nparams;

   {writeln ('beginning block, now dx=',dx:2,' tx=',tx:2);}
   tx0:=tx; 
   vs :=tx;

   { for fixing up later}
   table[tx0].adr:=cx; 
   gen(jmp,0,0);

   {now, add in the parameters, so they are seen, if any exist}
   {printTable;}


   {tx - table index is incremented, if we have funcs/procedures 
    with parameters. These are now visible in this level}
   {note that with functions, we have the "shadow" return value,
    so we need to add 1 to take that into account}

   {write('block, incrementing tx from ',tx:2,' to '); }
   tx := tx + table[tx0].nparams;
   if parentType = func then tx:= tx+1;

   {writeln(tx,' (at beginning of block)'); }


   if lev > levmax then error(procedureLevel);

   repeat
     {write('beginning of repeat in block, lev ',lev:2, ' sym ');printSym(sym);}
      {CONSTANTS}
      if sym = constsym then
      begin getsym;
         repeat constdeclaration;
            while sym = comma do
               begin getsym; constdeclaration
               end;
            if sym = semicolon then getsym else error(semicolonExpected);

            {if we have another const keyword, we are still parsing constants}
            if sym = constsym then getsym;
         until sym <> ident
      end;

      {VARIABLES}     
      while sym = varsym do
      begin getsym;
         vs := tx+1;
         repeat 
            {possibly multiple variables of same type}
            vardeclaration(0);
            while sym = comma do
              begin
                getsym; 
                vardeclaration(0)
              end;


            if sym = colon then
              begin 
                getsym;
                { find type here }
                varType := getType(sym);
                { fill in types for variables}
                for i := vs to tx do
                  begin 
                    {write ('fixing up table ',i,' to '); 
                     printvType(varType); writeln;}
                    table[i].typ := varType;
                  end;
                vs := tx+1; {move the table index along}
                getsym;
              end;

            if sym = semicolon then getsym else error(semicolonExpected);

            {if we have another var keyword, we are still parsing variables}
            if sym = varsym then 
              begin
                getsym;
                vs := tx+1;
              end;
         until sym <> ident
      end {VARIABLES};

      {PROCEDURES FUNCTIONS}
      if sym in [procsym,funcsym] then
      begin 
        if sym = procsym then procFunc := proc
        else procFunc := func;

        getsym;
         if sym = ident then
            begin 
              enter(procFunc,0); 
              getsym 
            end
         else error(identifierExpected);

         {find any parameters the procedure/function has}
         {save tx, because we'll need the type of the function
          to update type of "shadow" assignment variable}
         funcEntry := tx;
          
         dxSaved := dx;
         if procFunc = proc then dx := DlSlRa_proc
         else dx := DlSlRa_func;

         parameterList(procFunc);
         dx := dxSaved;

         {functions must have a type}
         if procFunc = func then
           begin
             {writeln ('scanning function for a type');}
             if sym = colon then 
               begin
                getsym;
                varType := getType(sym);
                table[tx].typ := varType;

                {update the "shadow" assignment variable}
                table[funcEntry+1].typ := table[tx].typ;

                {printTable;}

                getsym; {get next token after the type}
               end
             else error(colonExpected);
           end;

         if sym = semicolon then getsym else error(semicolonExpected);

         {parse the procedure/function body}
         block(lev+1, tx, procFunc, [semicolon]+fsys);
         if sym = semicolon then
            begin getsym;
            end
         else error(semicolonExpected);

      end {PROCEDURES FUNCTIONS};

      {---------------}

      {broad swath testing; let some things through}
      test(statbegsys+declbegsys+[ident], declbegsys, CVPFexpected);

   until not(sym in declbegsys);

   {-----------------}
   {tidy up the jump operation to bypass this code until called}
   code[table[tx0].adr].ax := cx;
   {writeln('tidyup lev:',lev:1,' tx0:',tx0:0,' cx',cx:2);}
   with table[tx0] do
      begin adr := cx; {start adr of code}
      end;

   {printTable;}

   cx0 := 0{cx}; gen(int, 0, dx);
   statement([semicolon, endsym]+fsys);

   (* either a return or end of program, which is it? *)
   if lev > 0 then
     begin
       if parentType = func then
         gen(ret, 1, 0) {return}
       else
         gen(ret, 0, 0) {return}
     end
   else 
     gen (xit, 0, 0); {exit program}

   test(fsys, [], blockEnd);

   {write('end of block, sym:');printSym(sym);}
   printTable;
   listcode;
end {block};


(********************************************************)

procedure interpret;
   const stacksize = 5000;
   var progPtr,
       dynamicLink, 
       tops: integer; {program-, DynamicLink-, topstack-registers}

      i: instruction; {instruction register}
      s: array [1..stacksize] of integer; {datastore}
      rv: integer;

      count:integer;
      charCounter:integer;

   function base(reqlev: integer): integer;
      var b1: integer;
   begin 
      {writeln('    base: wantlevel ', reqlev:4, ' at start dynamicLink=',dynamicLink:2);}
      b1 := dynamicLink; {find base l levels down}
      while reqlev > 0 do
         begin b1 := s[b1]; reqlev := reqlev - 1;
         {writeln('    ... base, b1 now ',b1:2,'  reqlev now ',reqlev:2);}
         
         end;
      base := b1;
      {writeln('    ...base returning ',b1:2);}
   end {base};

  procedure printstatus();
    var tmp:integer;
  begin
    with i do
      begin
        writeln('step',count:3);
        writeln('progPtr=',progPtr:3,' tops=',tops:3,' dynamicLink:',
                 dynamicLink:3, ' i:' , mnemonic[fn], ' ax:',ax:5);
      end;
    tmp := tops;

    while tmp > 0 do
      begin
        writeln (tmp,': [',s[tmp]:3,']');
        tmp := tmp-1;
      end;
  
    writeln('------------------------------------------------');
  end;

begin writeln(' start TinyPascal');
   count := 1;
   tops := 0; dynamicLink := 1; progPtr := 0;
   s[1] := 0; s[2] := 0; s[3] := 0;

   repeat

      i := code[progPtr];
     {printstatus;}

      progPtr := progPtr + 1;

      with i do
      case fn of
      lit: begin tops := tops + 1; s[tops] := ax
           end;

      ret: begin
             if lv=1 then
               begin
                 {write ('returning a function value... dynamicLink:',dynamicLink:3);}
                 rv := s[dynamiclink+3];
                 {writeln (tops:5,' value:',rv:3);}
                 tops := dynamicLink - 1; 
                 progPtr := s[tops + 3]; 
                 dynamicLink := s[tops + 2];

                 tops := tops+1;
                 s[tops] := rv;
                 {writeln('ret 1, tos is:',tops:2);}
                 
               end
             else 
               begin
                 {normal procedure return}
                 tops := dynamicLink - 1; 
{
                 write('ret, tops now ',tops:4);
}
                 progPtr := s[tops + 3]; 

{
                 write (' progptr now ',progPtr:4);
}
                 dynamicLink := s[tops + 2];
{
                 writeln(' dynamicLink now ',dynamicLink:4);
                 printstatus;
}
               end;
           end;

      xit: begin
             progPtr := 0; {signal normal exit of progPtrogram}
           end;

      stk: 
           case lv of {increment or decrement}
           
          0: begin {decrement stack to remove procedure params
                that were placed where the proc/func body expects them}
              tops := tops-ax;
              end;
          1: begin {increment stack to allow for procedure params
                to be placed where the proc/func body expects them}
              tops := tops+ax;
              end;
           end;

      opr: case ax of {operator}
           0: begin writeln ('version code is broken'); 
              end;
           opr_neg: s[tops] := -s[tops];
           opr_plus: begin {2, plus}
                 tops := tops - 1; s[tops] := s[tops] + s[tops + 1]
              end;
           opr_minus: begin tops := tops - 1; s[tops] := s[tops] - s[tops + 1]
              end;
           opr_mul: begin tops := tops - 1; s[tops] := s[tops] * s[tops + 1]
              end;
           opr_div: begin tops := tops - 1; s[tops] := s[tops] div s[tops + 1]
              end;
           (* not in Pascal 6: s[tops] := ord(odd(s[tops])); *)
           opr_mod: begin 
                      tops := tops -1;
                      s[tops] := s[tops] mod s[tops + 1];
                    end;
           opr_eql: begin tops := tops - 1; s[tops] := ord(s[tops] = s[tops + 1])
              end;
           opr_neq: begin tops := tops - 1; s[tops] := ord(s[tops] <> s[tops + 1])
              end;
           opr_lss: begin tops := tops - 1; s[tops] := ord(s[tops] < s[tops + 1])
              end;
           opr_geq: begin tops := tops - 1; s[tops] := ord(s[tops] >= s[tops + 1])
              end;
           opr_gtr: begin tops := tops - 1; 
              s[tops] := ord(s[tops] > s[tops + 1]);
              end;
           opr_leq: begin {13, leq}
                 tops := tops - 1; s[tops] := ord(s[tops] <= s[tops + 1])
              end;

           opr_and: begin {14, AND}
                 tops := tops - 1; 
                 if (s[tops]=1) and (s[tops+1]=1) then 
                   s[tops] := 1 else s[tops] := 0;
              end;

           opr_or: begin {15, OR}
                 tops := tops - 1; 
                 if (s[tops]=1) or (s[tops+1]=1) then 
                   s[tops] := 1 else s[tops] := 0;
              end;

           opr_not: begin {16, NOT}
                if s[tops] = 0 then s[tops] := 1 else s[tops] := 0;
              end;

           opr_peek: begin {14, peek}
                {write(' peek[',s[tops]:4,'] is ');}
                s[tops] := peekPokeMem[s[tops]];
                {writeln(s[tops]:3);}
           end;

           opr_poke: begin {15, poke}
                tops := tops -2;
                peekPokeMem[s[tops+1]] := s[tops+2];
                {writeln ('poked ',s[tops+2], ' into ',s[tops+1]);}
           end;
                


          end;
      lod: begin tops := tops + 1; s[tops] := s[base(lv) + ax]
           end;
      sto: begin 
             s[base(lv)+ax] := s[tops]; 
{
             writeln('STO: lv:',
                lv:2,' ax:',ax:2, ' := ',s[tops]:3); 
}
             tops := tops - 1
           end;
      cal: begin {generate new block mark}
              s[tops + 1] := base(lv); s[tops + 2] := dynamicLink; s[tops + 3] := progPtr;
{
writeln('cal, lv ',lv:4);
writeln('cal, stored in ',tops+1:4, ' base(lv)    ', s[tops+1]:4);
writeln('cal, stored in ',tops+2:4, ' dynamicLink ', s[tops+2]:4);
writeln('cal, stored in ',tops+3:4, ' progPtr     ', s[tops+3]:4);
}
              dynamicLink := tops + 1; progPtr := ax;
{
writeln('cal, DL now ',dynamicLink:4,' progPtr ',progPtr:4);
     printstatus;
}
           end;
      int: begin
             tops := tops + ax;
             {writeln('int, now tops ',tops:4);
             printstatus;}
           end;
      jmp: progPtr := ax;
      jpc: begin if s[tops] = 0 then progPtr := ax; tops := tops - 1
           end;
      tot: begin
             {writeln('tot, i.lv = ',i.lv);}

             {ascii char string}
             if i.lv = IO_charString then begin
               charCounter := i.ax;
               while constCharArray[charCounter] <> #0 do
                 begin
                   write(constCharArray[charCounter]);
                   charCounter := charCounter+1;
                 end;
             end 
                 
             {uint16 on the stack}
             else if i.lv = IO_uint16 then begin
               write(s[tops]:8); 
               tops := tops - 1;
             
             end else if i.lv = IO_char then begin
               write(chr(s[tops]):1);
               tops := tops - 1
             end else begin
               writeln ('interpret, tot, unknown type:',i.lv);
               tops := tops - 1
             end 

           end;
      tin: begin
           writeln('TXT IN:');
           end;
      ver: begin
           writeln('version: ',ax);
           end;

      end {with, case};

      count := count+1;
   until progPtr = 0;
   write(' end TinyPascal');
end {interpret};


(********************************************************)

begin {main program}
  {output character strings, eg, writeln text}
  constCharArray[0] := #$0D;
  constCharArray[1] := #$0A;
  constCharArray[2] := #$00;
  constCharIndex := 3;

  for ch := chr(0) to chr(255) do ssym[ch] := nul;
   
  word[ 1] := 'and       '; wsym[ 1] := andsym;
  word[ 2] := 'array     '; wsym[ 2] := arraysym;
  word[ 3] := 'begin     '; wsym[ 3] := beginsym;
  word[ 4] := 'case      '; wsym[ 4] := casesym;
  word[ 5] := 'char      '; wsym[ 5] := charsym;
  word[ 6] := 'const     '; wsym[ 6] := constsym;
  word[ 7] := 'div       '; wsym[ 7] := divsym;
  word[ 8] := 'do        '; wsym[ 8] := dosym;
  word[ 9] := 'downto    '; wsym[ 9] := downtosym;
  word[10] := 'else      '; wsym[10] := elsesym;
  word[11] := 'end       '; wsym[11] := endsym;
  word[12] := 'for       '; wsym[12] := forsym;
  word[13] := 'function  '; wsym[13] := funcsym;
  word[14] := 'if        '; wsym[14] := ifsym;
  word[15] := 'int16     '; wsym[15] := int16sym;
  word[16] := 'mod       '; wsym[16] := modsym;
  word[17] := 'not       '; wsym[17] := notsym;
  word[18] := 'or        '; wsym[18] := orsym;
  word[19] := 'peek      '; wsym[19] := peeksym;
  word[20] := 'poke      '; wsym[20] := pokesym;
  word[21] := 'procedure '; wsym[21] := procsym;
  word[22] := 'repeat    '; wsym[22] := repeatsym;
  word[23] := 'then      '; wsym[23] := thensym;
  word[24] := 'to        '; wsym[24] := tosym;
  word[25] := 'uint16    '; wsym[25] := uint16sym;
  word[26] := 'until     '; wsym[26] := untilsym;
  word[27] := 'var       '; wsym[27] := varsym;
  word[28] := 'while     '; wsym[28] := whilesym;
  word[29] := 'write     '; wsym[29] := writesym;
  word[30] := 'writeln   '; wsym[30] := writelnsym;

  ssym[ '+'] := plus;       ssym[ '-'] := minus;
  ssym[ '*'] := times;      ssym[ '/'] := slash;
  ssym[ '('] := lparen;     ssym[ ')'] := rparen;
  ssym[ '='] := eql;        ssym[ ','] := comma;
  ssym[ '.'] := period;     
  ssym[ '<'] := lss;        ssym[ '>'] := gtr;
  ssym[ ';'] := semicolon;  ssym[ ':'] := colon; 
  ssym[ ''''] := quote;

  mnemonic[lit] := '  lit';   mnemonic[opr] := '  opr';
  mnemonic[lod] := '  lod';   mnemonic[sto] := '  sto';
  mnemonic[cal] := '  cal';   mnemonic[int] := '  int';
  mnemonic[jmp] := '  jmp';   mnemonic[jpc] := '  jpc';
  mnemonic[ret] := '  ret';   mnemonic[xit] := '  xit';
  mnemonic[tot] := '  tot';   mnemonic[tin] := '  tin';
  mnemonic[stk] := '  stk';   mnemonic[ver] := '  ver';

  omnemonic[lit] := '  OPLIT';   omnemonic[opr] := '  OPOPR';
  omnemonic[lod] := '  OPLOD';   omnemonic[sto] := '  OPSTO';
  omnemonic[cal] := '  OPCAL';   omnemonic[int] := '  OPINT';
  omnemonic[jmp] := '  OPJMP';   omnemonic[jpc] := '  OPJPC';
  omnemonic[ret] := '  OPRET';   omnemonic[xit] := '  OPXIT';
  omnemonic[tot] := '  TXOUT';   omnemonic[tin] := '  TXTIN';
  omnemonic[stk] := '  OPSTK';   omnemonic[ver] := '  OPVER';


  declbegsys := [constsym, varsym, procsym, funcsym];
  statbegsys := [beginsym, ifsym, whilesym, repeatsym, forsym,pokesym];
  facbegsys  := [ident, number, charstring, peeksym, lparen, notsym];
  termbegsys := [times,slash,divsym,modsym,andsym];
  simpexsys  := [plus, minus, orsym];
  exprbegsys := [eql, neq, lss, leq, gtr, geq];

  page(output); errcount := 0;
  cc := 0; cx := 0; ll := 0; ch := ' '; kk := al; getsym;

  
  { insert version here}
  {write out the version here for the interpreter to check}
  {gen is ascii '0' * 256 + ascii '1' for version 01}
  {writeln('should be genning for version ',48*256+49);}

  gen(ver,0,48*256+52);


  block(0, 0, onbekend, [period]+declbegsys+statbegsys);
  if sym <> period then error(periodExpected);
  if errcount=0 then begin
    {interpret;}
    outToAssembler;
  end else write(' errors in TinyPascal program');

99: writeln
end.
