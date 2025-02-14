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

Feb14 2025: mistake on main block; look for DlSlRa_main for fix. :-|

Feb 10 2025: 
	- typing should work.
	- added in pre-defined types, and true and false
	  variables; so have:
		boolean (incl. true and false)
		uint16 (0->65535)
		char (0->255)

	- added enumerations;

	- added  functions:
		x := ord(true);
		c := chr (33);
		c := peek (0xFF00);
		poke (0xFF00,'Z');
                b := succ(false);
                b := pred(b);

	NOTE that types have a range built-in; HOWEVER
	range checking not currently implemented.

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

	const norw = 32;      {no. of reserved words}
	   txmax = 200;       {length of identifier table}
	   nmax = 5;         {max. no. of digits in numbers}
	   al = 10;           {length of identifiers}
	   amax = 32768;       {maximum address}
	   uint16amax = 65536;      {maximum uint16}
	   levmax = 20;       {maximum depth of block nesting}
	   cxmax = 20000;     {size of code array}
	   constCharMax=1024; {size of static string store}
	   maxparams=10;      {max number of params for func/proc}
           numReservedTypes=7;{the number of reserved types}
           startingLevel=0;   {block starting level, keep at 0}
                
           DlSlRa_main = 3;   {stack space for dynamic link, static
                               link and return address for main body}

	   DlSlRa_proc = 3;   {stack space for dynamic link, static
			       link and return address for procedures}

	   DlSlRa_func = 3;   {stack space for dynamic link, static
			       link and return address for functions}

           noType = -1;       {type not (yet?) found on table}

           {table entry for built-in types}
           unknownType = 1;
           uint16Type = 2;
           charType = 3;
           booleanType = 4;
           {not really supported fully:}
           charStringType = 5;


	(* I/O for read/write *)
        {have to map internal types to types in the interpreter.
         we may change the order here, but have to keep them as the 
         interpreter expects}

	const IO_newLine = 0; {not a valid table entry, so we just use this}
	const IO_charString = 1 {charStringType};
	const IO_uint16 = 2 {uint16Type};
	const IO_char = 3 {charType};

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

        const peekPokeMemSize = 32767;


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
		lparenexpected, commaExpected, equalsExpected,
		facbegerr, typeMismatch, typeExpected, charsOnlyinFactor, invOpForType,
		nountil, nmaxnumexpected,blocknumexpected, facnumexpected,procedureLevel);

        {on-screen representation stype}
        type displayStyle = (noDisplay, numberDisplay, charDisplay, booleanDisplay,enumDisplay);

	type symbol =
	   (nul,ident,number,quote,charString,plus,minus,times,slash,
	    eql,neq,lss,leq,gtr,geq,lparen,rparen,comma,semicolon,
	    colon,period,becomes,beginsym,endsym,ifsym,thensym,
	    whilesym,dosym,constsym,varsym,procsym,
	    elsesym,repeatsym,untilsym, peeksym, pokesym, arraysym,
	    typesym, andsym, divsym, modsym, notsym, orsym,
            predsym,succsym,ordsym, chrsym,
  	    funcsym,forsym,tosym,downtosym,casesym,writesym,writelnsym);

    alfa = packed array [1..al] of char;
    obj = (const_def,type_def,var_def,proc_def,func_def,onbekend);
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
    mnemonic: array [fct] of packed array [1..5] of char;

    (* for writing out assembler *)
    omnemonic: array [fct] of packed array [1..7] of char;

    exprbegsys, simpexsys, declbegsys, statbegsys, facbegsys, termbegsys: symset;

    table: array [0..txmax] of
           record 
              {ASCII name}
              name: alfa;

              {Internal type - if > 0, points to a table index of type}
              typePtr:integer;

              case kind: obj of
                const_def: (
                           value, parent: integer);

                type_def: (size,lowerBound,upperBound:integer;
                           display:displayStyle) ;

                var_def, func_def, proc_def: (
                  level, adr, nparams: integer;
                  {parameter types, points to table entry for param type}
                  pType: array[1..maxparams] of integer;
                             );
                onbekend: (); {unknown}
           end;


    {for constant chars - eg, writeln text}
    constCharIndex: integer;
    constStringStart: integer;
    constCharArray: array[0..constCharMax] of char;

    peekPokeMem: array[0..peekPokeMemSize] of integer;

(********************************************************)
procedure outToAssembler;


  var i: integer;
  var tfOut: Text;

  begin {list code generated for this block}
    Assign (tfOut,'assemblerOut.asm');
    rewrite(tfOut);
    writeln(tfOut,'; created from TinyPascal 1802 compiler');
    writeln(tfOut);
    writeln(tfOut,';;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;');
    writeln(tfOut,'; Do we fit this into 0x0000 -> 0x7FFF or 0x8000 -> 0xFFFF?');
    writeln(tfOut,'; Lee Harts MemberCHIP card ROM is 0x0000, the SHIP card is at 0x8000');
    writeln(tfOut,'; Choose one of these to set the RAM block for us to go into');
    writeln(tfOut,'; MEMBERCHIP rom is at 0x0000, ram starts at 0x8000');
    writeln(tfOut,'; MEMBERSHIP rom is at 0x0000, ram starts at 0x0000');
    writeln(tfOut,'');
    writeln(tfOut,'MEMBERSHIP EQU     0 ; 1 == memberSHIP card - must set MC20ANSA as well.');
    writeln(tfOut,'MEMBERCHIP EQU     1 ; 1 == memberCHIP card - must set MC20ANSA as well.');
    writeln(tfOut,'');
    writeln(tfOut,';;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;');
    writeln(tfOut,'; ');
    writeln(tfOut,'; MC20ANSA - default EPROM for Lee Harts MemberCHIP card, but use for');
    writeln(tfOut,'; both MemberSHIP and MemberCHIP cards; tested with MCSMP20J.bin for');
    writeln(tfOut,'; MemberSHIP cards (Shows Ver. 2.0J on start) and MC20ANSA shows');
    writeln(tfOut,'; v2.0AR 14 Feb 2022. Other versions likely ok, but need to ensure serial');
    writeln(tfOut,'; function addresses are correct.');
    writeln(tfOut,'');
    writeln(tfOut,'	IF MEMBERCHIP');
    writeln(tfOut,'; MemberCHIP card: ROM at 0000H');
    writeln(tfOut,'; MemberCHIP card: RAM at 8000H');
    writeln(tfOut,'ORGINIT    EQU     08000H');
    writeln(tfOut,'ROMISAT    EQU     0');
    writeln(tfOut,'STACKST	EQU	0FEFFH	; note: FFxx last lines used by MemberCHIP monitor');
    writeln(tfOut,'	ENDI ; memberCHIP card');
    writeln(tfOut,'');
    writeln(tfOut,'	IF MEMBERSHIP');
    writeln(tfOut,'; MemberSHIP card: ROM at 8000H');
    writeln(tfOut,'; MemberSHIP card: RAM at 0000H');
    writeln(tfOut,'ORGINIT     EQU    0');
    writeln(tfOut,'ROMISAT     EQU     08000H');
    writeln(tfOut,'STACKST	EQU	07EFFH	; note: 7Fxx last lines used by MemberSHIP monitor');
    writeln(tfOut,'	ENDI ; memberSHIP card');
    writeln(tfOut,'');
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
    writeln(tfOut,'PASPROG    EQU ORGINIT + 0800H');
    writeln(tfOut,'          ORG  PASPROG');
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
                  writeln(tfOut, '          DW     PASPROG + (',ax:0,' SHL 2)');
                end;
  
                int: begin
                  writeln(tfOut, '          DW     (',ax:0,' SHL 1)');
                end;
  
                jmp: begin
                  writeln(tfOut, '          DW     PASPROG + (',ax:0,' SHL 2)');
                end;
  
                jpc: begin
                  writeln(tfOut, '          DW     PASPROG + (',ax:0,' SHL 2)');
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

procedure printStyle(mysym:displayStyle); 
  begin
    case mysym of
      noDisplay:        write ('blank       ');
      numberDisplay:    write ('number      ');
      charDisplay:      write ('character   ');
      booleanDisplay:   write ('boolean     ');
      enumDisplay:      write ('enumeration ');
    end;
  end;

procedure printvtype(mysym:integer);
  begin
    {writeln('printvtype...',mysym:3);}
    if mysym < 1 then begin
      {writeln ('printvtype, number too small:',mysym:2) }
    end else if mysym > norw then writeln('printvtype, number index too large',mysym:5) else
    begin
      with table[mysym] do begin
        if kind <> type_def then
          writeln('printvtype, mysym ',mysym:2,' points to alpha ',name)
        else 
          write ('typeNode: ',mysym:3, ' typedef: ',name);
      end;
    end;
  end;

   {for printing initial builtin entries}
   {procedure printInitTable;
     var i,j: integer;
     
     begin
     j := booleanType+2;

     writeln ('---------------------------------------------');
     writeln ('printInitTable for index ',1:3,' to ',j:3);
     for i := 1 to j  do

       with table[i] do
         begin
         write(i:3,' ',name,' ');
         printvtype(typePtr);

         case kind of
           const_def: begin
              write ('const: value ',value:5,' of enum type table entry: ',parent:3);
           end;

           var_def: begin
              write ('var:   level ',level:3,' stack ',adr:3);
           end;

           proc_def: begin
              write ('proc:  level ',level:3,' @code ',adr:3,' nparams:',nparams:2);
              writeln();
              for j := 1 to nparams do
                begin
                write('                      param:',j:2,' type: ');
                printvtype(ptype[j]);
                writeln();
                end;
           end;

           func_def: begin
              write ('func:  level ',level:3,' @code ',adr:3,' nparams:',nparams:2);
              writeln();
              for j := 1 to nparams do
                begin
                write('                      param:',j:2,' type: ');
                printvtype(ptype[j]);
                writeln();
                end;
           end;

           type_def: begin
              write('type:  size:',size:5,' lower bound:',lowerBound:2,
                    ' upperBound:',upperBound:6,' displayStyle:');
              printStyle(display);
           end;
          
           onbekend: begin
              writeln('unknown table entry - huh??');
           end;
         end;

         writeln();
         end;

       writeln ('---------------------------------------------');
     end; printInitTable}


procedure loadBuiltinTypes;
   begin {enter obj into table}
     with table[unknownType] do begin
       name := '-unknown-  ';
       kind := type_def;
       {typ := uint16Type;}
       size := 0;
       lowerBound :=0;
       upperBound :=0;
       display := noDisplay;
     end;
    
     with table[uint16Type] do begin
       name := 'uint16    ';
       kind := type_def;
       {typ := uint16Type;}
       size := 32767;
       lowerBound :=0;
       upperBound :=65535;
       display := numberDisplay;
     end;
    
     with table[charType] do begin
       name := 'char      ';
       kind := type_def;
       {typ := charType;}
       size := 256;
       lowerBound :=0;
       upperBound :=255;
       display := charDisplay;
     end;

     with table[booleanType] do begin
       name := 'boolean   ';
       kind := type_def;
       {typ := booleanType;}
       size := 2;
       lowerBound :=0;
       upperBound :=1;
       display := booleanDisplay;
     end;

     {pre-define true and false here}
     with table[booleanType+1] do begin
       name := 'false     ';
       kind := const_def;
       value := 0;
       parent := booleanType;
       typePtr := booleanType;
     end;
     with table[booleanType+2] do begin
       name := 'true      ';
       kind := const_def;
       value := 1;
       parent := booleanType;
       typePtr := booleanType;
     end;

     {print this table...}
     {have to uncomment the procedure!}
     {printInitTable;}


   end; 

(********************************************************)

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
      chrsym: writeln('chrsym');
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
      equalsExpected: writeln('"=" expected');

      thenExpected : writeln('keyword "then" expected');
      endExpected : writeln('keyword "end" expected');
      doExpected : writeln('keyword "do" expected');
      nountil: writeln('keyword "until" expected');

      typeExpected : writeln('builtin or defined type identifier expected');
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
      invOpForType: writeln('invalid operation for type');
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

   { get a character from input.
     this WILL PRINT out source, with code index, at each
     line. If you don'w want this output, then comment out
     both the "write cx: 5,' ');" line 
        AND
     "write(ch);" line in this procedure}

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
      dxSaved: integer; {parsing of proc/func params}
      varType: integer; {type of variable on declaration- 
                         should point to table entry, or -1(noType)}
      procFunc: obj;    {where is this called from?}
      funcEntry: integer;{table entry if a function}
      mainBody:  integer;{if gtr 0 the address of the main body}


   {find identifier position in ID table}
   function position(id: alfa): integer;
      var i: integer;
   begin {find indentifier id in table}
      {writeln ('position, tx:',tx:2,' id ',id);}
      table[0].name := id; i := tx;
      while table[i].name <> id do i := i-1;
      position := i
   end {position};



   {return the integer of a variable, from the sym read in}
   function getType(inty : symbol) : integer;
     var i:integer;
         found:boolean;
         returning:integer;
     begin {1}
        found := true;

        {write ('getType for ',id,':'); printSym(inty);}

        {enum etc types}
        {else}
        if inty = ident then begin {2}
          i:= position(id);
          {writeln ('getType, we have an ident here.',id);
           writeln('we have position ',i:2);}

          if i = 0 then begin {3}
            found := false;
            error(idNotFound) 
          end {3} else begin {3}
            if table[i].kind = type_def then begin {4}
                found := true;
                returning := i;
              end {4}
            else
              found := false;
          end; {3}
        end; {2}


        {error checking}
        if not found then begin {2}
          error(typeExpected);
          returning :=-1; 
        end; {2}
       {write('getType, returning:');printvtype(-1);}

       getType := returning;
     end {1, getType};



   procedure enterNewType;
   begin {enter obj into table}
     tx := tx + 1;
     with table[tx] do begin
       name := id;
       kind := type_def;
       {typ := enumType;}
       display:= enumDisplay;
       size := 0;
       lowerBound :=0;
       upperBound :=0;
     end;
   end; 

   procedure enterNewEnumElement(var p_entry,val:integer) ;
   begin {enter obj into table}
     tx := tx + 1;
     {writeln('newEnumElement, tx:',tx:2,' value ',val:2);}
     with table[tx] do begin
       name := id;
       kind := const_def;
       {typ := enumElement;}
       value := val;
       parent := p_entry;
     end;
     if (p_entry >=0) then 
       with table[p_entry] do begin
         {bounds 0->6, size 7, so do bound first}
         upperBound := size; 
         size := size + 1;
       end;
   end; 



   { enter a variable, procedure, function into the table}
   procedure enterVPFC (k: obj; levInc:integer);
   begin {enter obj into table}
      tx := tx + 1;
      {write('enterVPFC, have variable ',id,' writing to tx ',tx:2);
      writeln(' levInc:',levInc:4);}

      with table[tx] do
      begin name := id; kind := k;
         case k of
         const_def: begin if num > amax then
                              begin error(blocknumexpected); num := 0 end;
                      value := num;
                      parent := -1;
                   end;
         {variable, could have parameters that are at the body level}
         var_def: begin level := lev+levInc; adr := dx; dx := dx + 1;
                  end;
         proc_def, func_def:
                  begin
                    level := lev;
                    nparams := 0;
                  end;
         type_def: begin 
                     write('enter, type_def should not be here  not coded yet'); 
                   end;
         onbekend: begin writeln('enter, unknown - onbekend - not coded properly');end;
        end; {with end}
      end
   end {enter};

   (****************************************)
   procedure typedeclaration;
   var myTypetx: integer;
       myval: integer;

   begin {1}
     myTypetx := -1; { incredibly invalid}
     myval := 0; {ordinal value of first index}

     if sym = ident then
      begin {2}
         enterNewType;
         myTypetx := tx;
         getsym;
         if sym in [eql, becomes] then
           begin {3}
             {writeln('have either eql or becomes');}
             if sym = becomes then error(eqlExpected);
             getsym;
             if sym = lparen then 
               begin {4}
               {writeln ('have lparen');}
               getsym;
               while sym = ident do
                 begin {5}
{writeln ('ident value ',num:3,' is part of type def at ',myTypetx:3);
writeln ('make it a new table entry');}
                   {increment the number of elements of the enum}
                   {and save this}
                   if (myTypetx>0) then begin
                     enterNewEnumElement(myTypetx,myval);
                     myval := myval+1;
                   end;

                   if sym = ident then getsym else error(identExpected);
                   if sym = comma then 
                     begin {6}
                       getsym;
                     end {6}
                  end; {5}

                if sym = rparen then 
                  begin {5}
                    {finish this enumeration off}
                    getsym;
                    {writeln('type enumeration, got rparen');}
                  end {5}
              else error (commaExpected);

            end; {4} {lparen}
         end {3}
         else error(eqlExpected)
      end {2}
      else error(identifierExpected);
      {writeln('end typedeclaration');}
   end {typedeclaration};

   (****************************************)
   procedure constdeclaration;
   begin if sym = ident then
      begin getsym;
         if sym in [eql, becomes] then
         begin if sym = becomes then error(eqlExpected);
            getsym;
            if sym = number then
               begin enterVPFC(const_def,0); getsym
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
           begin enterVPFC(var_def,levInt); getsym
           end else error(identifierExpected)
   end {vardeclaration};

   (****************************************)
   procedure listcode;
      var i: integer;
   begin {list code generated for this block}
      writeln('running listcode for 0 to:' ,cx-1:3);
      for i := 0 to cx-1 do
         with code[i] do
            writeln(i:5, mnemonic[fn]:5, lv:3, ax:5)
   end {listcode};

   (****************************************)
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
         printvtype(typePtr);

         case kind of
           const_def: begin
              write ('const: value: ',value:5,' of enum type table entry: ',parent:3);
           end;

           var_def: begin
              write ('var:   level: ',level:3,' stack: ',adr:3);
           end;

           proc_def: begin
              write ('proc:  level: ',level:3,' code: ',adr:3,' nparams:',nparams:2);
              for j := 1 to nparams do
                begin
                writeln();
                write('                      param:',j:2,' type: ');
                printvtype(ptype[j]);
                end;
           end;

           func_def: begin
              write ('func:  level: ',level:3,' code: ',adr:3,' nparams:',nparams:2);
              for j := 1 to nparams do
                begin
                writeln();
                write('                      param:',j:2,' type: ');
                printvtype(ptype[j]);
                end;
           end;

           type_def: begin
              write('type:  size:',size:5,' lower bound:',lowerBound:2,
                    ' upperBound:',upperBound:6,' displayStyle:');
              printStyle(display);
           end;
          
           onbekend: begin
              writeln('unknown table entry - huh??');
           end;
         end;

         writeln();
         end;

       writeln ('---------------------------------------------');
     end {printTable};

(************************************************************)
   procedure statement(fsys: symset);
      var i:integer;
      var returnedTyp: integer;
      {var endsym: symbol;}


(************************************************************)
    function expression(fsys: symset; typ:integer): integer;
         var relop: symbol;
         var returnedTypLHS, returnedTypRHS : integer;

(************************************************************)
      function simpleExpression(fsys: symset; typ:integer) : integer;
         var addop: symbol;
         var returnedTyp: integer;
         var expectedTyp: integer;

(************************************************************)
         function term(fsys: symset; typ:integer): integer;
            var termop: symbol;

(************************************************************)

{functions, with () and params, parse these params}
function parseFuncParams(i:integer) :integer;
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
                    {write('note: parseFuncParams, body expectedTyp ');
                     printvtype(expectedTyp);writeln();
                    write('note: parseFuncParams, body returnedTyp ');
                     printvtype(returnedTyp);writeln();}
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
            function factor(fsys: symset; typ:integer): integer;
               var i: integer;
                   mysym:symbol;

(************************************************************)
            procedure factor_ident;
            begin
                i:= position(id);
                {writeln('factor, ident, id:',i:3,' num:',num:4);}
                if i = 0 then error(idNotFound) else
                with table[i] do
                 case kind of
                    const_def: begin
                      {writeln('factor, have const_def, typePtr:',typePtr:3,' parent:',parent:3,' value:',value:3);}
                      returnedTyp := parent; 
                      gen(lit, 0, value);
                      end;
                    var_def: begin
                      {writeln('factor, found a var. typePtr:',typePtr);}
                      {Variable, return the type if we don't know statement type,
                       or if known type, check if correct, if not, error}
            
                      {writeln('factor, var_def pt 1, typ:',typ:2,' returnedTyp:',returnedTyp:2,
                      ' typePtr:',typePtr:2);}
            
                      {did we know what type to expect?}
                      if expectedTyp = noType then expectedTyp := typePtr;
                      {do we know what we are expected to return?}
                      if returnedTyp = noType then returnedTyp := typePtr;

                      {writeln('factor, var_def pt 2, typ:',typ:2,' returnedTyp:',returnedTyp:2,
                      ' typePtr:',typePtr:2);}
            
                      {if we had a known type, and this var doesnt match...}
                      if returnedTyp <> expectedTyp then begin
                        error (typeMismatch);
                        writeln('at posn rr (factor) in pascal');
                      end; 
            
                      gen(lod, lev-level, adr);
                      end;
                    proc_def: begin
                      error(constVarExpected)
                      end;
                    func_def: begin
                      getsym;
                      returnedTyp := parseFuncParams(i);
                      end;
                    type_def: begin
                      returnedTyp := typ;
                      gen(lod, lev-level, adr);
                    end;
                 end; {case}
                 {writeln('factor, while, ident, returnedTyp is ',returnedTyp);}
                 getsym
            end; {factor_ident}

            procedure factor_constants;
              begin
                {is this the correct type for a number?}
                returnedTyp := uint16Type;
                if num >  uint16amax then
                 begin 
                   error(facnumexpected); 
                   num := 0
                 end;
                gen(lit, 0, num); 
                getsym
              end; {factor_constants}


            procedure factor_charString;
              begin
                returnedTyp := charType;

                {writeln ('factor, have charString of size ',
                      constCharIndex - constStringStart,  
                      ' char as decimal ',byte(constCharArray[constStringStart])
                     );}

                gen(lit, 0, byte(constCharArray[constStringStart]));

                if constCharIndex-constStringStart <> 2 then
                  error(charsOnlyinFactor);

                getsym
              end; {factor_charString}


            procedure factor_lparen;
              begin
                getsym; 
                {writeln('factor, lparen, expectedTyp '); printvtype(expectedTyp);}

                returnedTyp := expression([rparen]+fsys,expectedTyp);
                if sym = rparen then getsym else error(rparenexpected)
              end; {factor_lparen}

            procedure factor_peek;
              begin {1}
                getsym;
                if sym = lparen then begin {2}
                  getsym;

                  {peek expects a uint address and returns a char}
                  expectedTyp := uint16Type;
                  returnedTyp := expression([rparen]+fsys,expectedTyp);

                  {writeln ('factor, the peek expression returned type:',returnedTyp:3);}
                  returnedTyp := charType;
                  expectedTyp := charType;
                  gen(opr,0,opr_peek);

                  {writeln('after gen for peek, returnedTyp:',returnedTyp:2);}

                  if sym = rparen then getsym
                  else error (rparenexpected)
                end {2}
              else error (lparenExpected);
            end; {factor_peek}


            procedure factor_ord_etc;
              begin {1}
                {save this so that we know which}
                mysym := sym;
                getsym;

                if sym = lparen then begin {2}
                  getsym;

                  {can only work on identifiers, constants, etc}
                  if sym<>ident then 
                    error(identExpected)
                  else begin {3}
                    i := position (id);
                    if i = 0 then  
                      error(idNotFound) 
                    else begin {4}
                      {writeln('ord, have const_def, typePtr:',typePtr:3,' parent:',parent:3,' value:',value:3);}
                      {writeln('ord, var_def pt 1, typ:',typ:2,' returnedTyp:',returnedTyp:2,
                      ' typePtr:',typePtr:2);
                      }
                      with table[i] do
                        case kind of
  
                        const_def: begin {5}
                          returnedTyp := parent; 
                          gen(lit, 0, value);
                          end; {5}
  
                        var_def: begin {5}
                          {writeln('factor, found a var. typePtr:',typePtr);}
                          {Variable, return the type if we don't know statement type,
                           or if known type, check if correct, if not, error}
  
                          gen(lod, lev-level, adr);
                          end; {5}
                      end; {with and case}

                      {go past the ident, hopefully rparen}
                      getsym;
                        
                      {now what do we do with this?}
                      if mysym = succsym then begin
                        gen(lit,0,1); 
                        gen(opr,0,opr_plus); {add}
                        end;
                      if mysym = predsym then begin
                        gen(lit,0,1); 
                        gen(opr,0,opr_minus); {subtract}
                        end;

                      returnedTyp := uint16Type;
                      expectedTyp := returnedTyp;
                      {writeln ('factor, the ORD,SUCC,PRED expression returned type:',returnedTyp:3);}
                    end; {4} {ident found ok}
                  end; {3} {not an ident}

                  if sym = rparen then getsym else error(rparenexpected)
                end {2}

                else error (lparenexpected);
              end; {factor ord_etc}
            

(************************************************************)
            begin {factor}
               expectedTyp := typ;
               returnedTyp := noType;
               {writeln('factor, type param:',typ:3);}

               test(facbegsys, fsys, facbegerr);
               
               {variables, functions}
               if sym = ident then factor_ident

               {unsigned constants}
               else if sym = number then factor_constants

               {character strings}
               else if sym = charString then factor_charString

               {left parenthesis}
               else if sym = lparen then factor_lparen

               {peek}
               else if sym = peeksym then factor_peek

               {ord chr pred succ}
               else if sym in [ordsym,chrsym,predsym,succsym] then 
                 factor_ord_etc

               {NOT}
               else if sym = notsym then begin
                 getsym;
                 returnedTyp := factor(fsys,typ);
                 gen(opr,0,opr_not);
               end;

               {writeln('note: factor, expectedTyp:',expectedTyp);}
               {writeln('note: factor, returnedTyp:',returnedTyp);}

               {test the types}
               if expectedTyp <> returnedTyp then begin
                 if expectedTyp = noType then begin
                   {FACTOR, we NOW have the type we need}
                 end else begin
                   {use the expected type as the type in error condition}
                   writeln('invOpForType at 1');
                   error(invOpForType);
                   returnedTyp := expectedTyp;
                 end;
               end; {type check}

             {writeln('factor, returning: ',returnedTyp);}

             factor := returnedTyp;
           end {factor};

(************************************************************)
         begin {term} 
           {writeln('term, typ:',typ:3);}
           {is this a boolean condition, or an assignment?}
           returnedTypRHS := noType;

           returnedTypLHS := factor(fsys+termbegsys,noType);

           {term can loop through these operators}
           while sym in termbegsys do begin {while}

             {writeln('term, returnedTypRHS:',returnedTypRHS:3);}
    
             termop:=sym;
             getsym;
             returnedTypRHS := factor(fsys+termbegsys,expectedTyp);

             {writeln('expression, returnedTypRHS:',returnedTypRHS:3);}
    
             {data type check}
             if returnedTypLHS <> returnedTypRHS then begin {check}
               writeln('typeMismatch in term');
               error (typeMismatch);
             end; {check}
    
             {ok, we know the term types match;
              do term operation }
             if termop = andsym then
               if returnedTypLHS <> booleanType then begin
                 writeln('invOpForType at 2');
                 error (invOpForType);
               end
             else
               if returnedTypLHS <> returnedTypRHS then begin
                 write('term, symbol in question:');
                   printSym(termop);
                 writeln('; invOpForType at 3 termop:');
                 error (invOpForType);
               end;

             if termop=times then gen(opr,0,opr_mul) 
             else if termop = slash then gen(opr,0,opr_div)
             else if termop = divsym then gen(opr,0,opr_div)
             else if termop = modsym then gen(opr,0,opr_mod)
             else if termop = andsym then gen(opr,0,opr_and)
            
           end; {while}

           term := returnedTypLHS;
           {writeln('term, returning:',returnedTypLHS:2);}
         end {term};

(************************************************************)
      begin {simpleExpression}

        {Writeln('note: simpleExpression, start typ:',typ:3);}

        returnedTyp := noType;
        expectedTyp := noType;


        {check that the type is able to use simpleExpression
         operators}
        addop := sym;

        {are we in the middle of figuring out the type of RHS?}

        {initial plus or minus - I know, uint16s can't be negative...}
        if (sym = plus) or (sym = minus) then begin
          {gosh - maybe this is the first thing on rhs of := 
           so maybe it's noType? if so, assume number}
          if typ = noType then typ := uint16type;

          if typ <> uint16type then
            writeln('invOpForType at 4');
            error (invOpForType);
          getsym;
        end;

        {writeln('calling term, typ currently is ',typ:3);}
        returnedTyp := term(fsys+simpexsys,typ);
        {writeln('after term, typ currently is ',typ:3,' returnedTyp:',returnedTyp:3);}

        {term will return a type if we did not specify one,
         so we use the returned type as our type here,
         no matter what.}
        typ := returnedTyp;

        {if we got an initial minus sign at the beginning of simpleExpression}
        if addop = minus then gen(opr, 0,opr_neg);
{old
        if sym=minus  then
          begin 
            returnedTyp := term(fsys+simpexsys,typ);
            if addop = minus then gen(opr, 0,opr_neg)
          end 
        else returnedTyp := term(fsys+simpexsys,typ);
}

        {writeln('note: simpleExpression, after +- typ:',typ:3,' returnedTyp:',returnedTyp:3);}

        expectedTyp := returnedTyp;

         while sym in simpexsys do
            begin 
              {writeln ('simpleExpression, in while loop');}
              addop := sym; 
              getsym; 
              returnedTyp := term(fsys+simpexsys,typ);

              {check to see if this term type matches}

              {writeln('simpleExpression, while, t1:',
                typ:3, ' returnedTyp:',returnedTyp:3);}

              if returnedTyp <> typ then 
                begin
                  writeln('typeMismatch 2');
                  error(typeMismatch);
                end;

              {type checking for the simpleExpression
               operators}
              if addop in [plus,minus] then begin
                if returnedTyp <> uint16Type then begin
                  writeln('invOpForType simpleExpression 1');
                  error(invOpForType);
                end;

                if addop=plus then
                   gen(opr,0,opr_plus)
                else gen (opr,0,opr_minus);
              end

              else if addop = orsym then begin
                if returnedTyp <> booleanType then begin
                  writeln('invOpForType simpleExpression 2');
                  error(invOpForType);
                end;
                gen(opr,0,opr_or);
              end;
        
            end {while};
         simpleExpression := returnedTyp;
      end {simpleExpression};

(************************************************************)
      begin {expression}
         {writeln('expression, typ:',typ:3);}

         {is this a boolean condition, or an assignment?}
         returnedTypRHS := noType;

         returnedTypLHS := simpleExpression(fsys+exprbegsys,noType);

         {writeln('expression, returnedTypLHS:',returnedTypLHS:3);}

         { is this possibly a boolean?}
         if (sym in exprbegsys) then
           begin 
             relop := sym; 
             getsym; 
             returnedTypRHS := simpleExpression(fsys,noType);
    
             {writeln('expression, returnedTypRHS:',returnedTypRHS:3);}
    
             {data type check}
             if returnedTypLHS <> returnedTypRHS then begin
               writeln('typeMismatch 22');
               error (typeMismatch);
             end;
    
             case relop of
               eql: gen(opr, 0, opr_eql);
               neq: gen(opr, 0, opr_neq);
               lss: gen(opr, 0, opr_lss);
               geq: gen(opr, 0, opr_geq);
               gtr: gen(opr, 0, opr_gtr);
               leq: gen(opr, 0, opr_leq);
             end;
             { for return value from this expression HERE}
             returnedTypLHS := booleanType;
           end; 

         {writeln('expression, returining:',returnedTypLHS:2);}

        expression := returnedTypLHS;
      end {expression};


      (************************************************************)
      procedure parseProcParams(i:integer);
        var pcount : integer;
           var returnedTyp: integer;
           var expectedTyp: integer;
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
                      {write('note: useFuncParams, body expectedTyp ');
                       printvtype(expectedTyp);writeln();
                       write('note: useFuncParams, body returnedTyp ');
                       printvtype(returnedTyp);writeln();}
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
             if kind=proc_def then 
               parseProcParams(i)
             else if kind=func_def then
               begin
                 {this is a function, but the shadow variable is 1 above
                  the table index. Increment i so we are pointing at this 
                  shadow variable for variable assignment}
                 with table[i+1] do
                   begin
                     {writeln('stmtIdent, func store; genning sto with table entry ',i+1);}
                     getsym; 
                     if sym = becomes then getsym else error(becomesExpected);
                     returnedTyp := expression(fsys,typePtr);
                     gen(sto, lev-level, adr)
                   end;
               end
             else if kind=var_def then
               begin
                 getsym; 
                 if sym = becomes then getsym else error(becomesExpected);
                 returnedTyp := expression(fsys,typePtr);
                 
                 {type match check}
                 {writeln ('stmtIdent, my type:',table[i].typePtr:3, 
                   ' returnedTyp:',returnedTyp:3);}
                 if table[i].typePtr <> returnedTyp then begin
                   {writeln('typeMismatch at 33');}
                   error (typeMismatch);
                 end;
                 gen(sto, lev-level, adr)
               end
           end;
       {write('ident statement end, sym is '); printSym(sym);}
     end {stmtIdent};

(************************************************************)
    procedure stmtIf(typ:integer);
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
    procedure stmtRepeat(typ:integer);
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
    procedure stmtFor(typ:integer);
      var todowntosym: symbol;
      var cx1, cx2: integer;
      var returnedLHS: integer;

        begin
          todowntosym:=nul;
          getsym;
          if sym = ident then
            begin
              i := position(id);
              if i = 0 then error(idNotFound) else
                begin
                if table[i].kind <> var_def then
                  error(varExpected);
                end;
              getsym;
              if sym = becomes then
                begin
                  getsym;
                  returnedLHS := expression([tosym,downtosym]+fsys,typ);

                  {Write('note: stmtFor, first returnedTyp: ');
                  printvtype(returnedLHS);writeln();}


                  if table[i].kind = var_def then begin
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
                  printvtype(returnedTyp);writeln();}

                  {type checking}
                  {if returnedLHS <> returnedTyp then begin
                      error (typeMismatch);}

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

      procedure stmtWrite(typ:integer);
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

            {writeln('stmtWrite, have returned type:',
               returnedTyp:3,' from param typ:',typ:3);}

            if returnedTyp =  uint16Type then
              gen(tot,IO_uint16,0)
            else if returnedTyp = charType then
              gen(tot,IO_char,0)
            else begin
              {hope we can print it out as a uint16???}
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
      procedure stmtWhile(typ:integer);
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
    procedure stmtPoke(typ:integer);
      var myvt: integer;
        begin 
         (* char poke(address,value); *)
{
         if typ <> charType then
           error(charExpected);
}
           
         {write('stmtPoke, typ '); printvtype(typ);}

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
                   printvtype(myvt);
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
        mtyp: integer;
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
          table[i].typePtr := mtyp;
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
    
    if fromWhere = func_def then
      begin
        {writeln ('parameterList, from a func');}
        {writeln('pl, txOfParma ',txOfParamFunc);}
        {printvtype(table[txOfParamFunc].typ);}
        id:='-rvForMe- ';
        enterVPFC (var_def,1);
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
         const_def: begin 
                   end;
         var_def: begin 
                  end;
         proc_def:
                  begin
                    nparams := tx-txOfParamFunc;
                    for pi := 1 to nparams do
                      begin
                        {write ('copying type of param:',pi:2,' name:',
                        table[pi+txOfParamFunc].name, ' type:');
                        printvtype(table[pi+txOfParamFunc].typePtr);
                        writeln();}

                        pType[pi] := table[pi+txOfParamFunc].typePtr;                      
                    end;
                  end;
         func_def:
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
                        printvtype(table[pi+txOfParamFunc].typePtr);
                        writeln();}

                        {note the addition of 1 here}
                        pType[pi] := table[pi+txOfParamFunc+1].typePtr;
                    end;
                  end
         end;
    {restore tx to where it was before parsing these parameters}
    tx := txOfParamFunc;

    {writeln(' end parameterlist, tx:',tx:1,' txOfParamFunc:',txOfParamFunc:1);
    writeln(' end paramterList, have #params:', tx -txOfParamFunc);}
  end {parameterList};


begin {block} 
   {if this is the main, (ie not a proc or func) this will be set}   
   mainBody := -1;

   {writeln ('beginning of block,tx:',tx:2,'nparams',table[tx].nparams);}

   { begin block - tx is the index of possibly a function or procedure
    we increment the data param to include not only the 3 normal entries
    (stack, static link, dynamic link) but also the number of parameters
    that the procedure/function call put on the stack}

   dx := 0;
   if parentType = func_def then 
     dx := DlSlRa_func + table[tx].nparams+1
   else if parentType = proc_def then
     dx := DlSlRa_proc + table[tx].nparams
   else dx := DlSlRa_main;

   {writeln ('beginning block, now dx=',dx:2,' tx=',tx:2);}
   tx0:=tx; 
   vs :=tx;

   if (parentType = func_def) or (parentType = proc_def) then
     begin
     {call address of function}
     table[tx0].adr:=cx; 
     end
   else
     begin
       {writeln('assuming this is the main, as it is not a proc or func:',
          cx);}
     mainBody := cx;
   end;

   {this jumps around other nested code, such as procedures}
   {or, the jump to the main body}
   gen(jmp,0,0);

   {now, add in the parameters, so they are seen, if any exist}
   {tx - table index is incremented, if we have funcs/procedures 
    with parameters. These are now visible in this level}
   {note that with functions, we have the "shadow" return value,
    so we need to add 1 to take that into account}

   if (parentType = proc_def) or (parentType = func_def) then 
   tx := tx + table[tx0].nparams;
   if parentType = func_def then tx:= tx+1;

   {writeln(tx,' (at beginning of block)'); 
   printTable;}


   if lev > levmax then error(procedureLevel);

   repeat
     {write('beginning of repeat in block, lev ',lev:2, ' sym ');printSym(sym);}
      {TYPES}
      if sym = typesym then
      begin getsym;
         repeat typedeclaration;
            while sym = comma do
               begin getsym; typedeclaration
               end;
            if sym = semicolon then getsym else error(semicolonExpected);

            {if we have another type keyword, we are still parsing types}
            if sym = typesym then getsym;
         until sym <> ident
      end;


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
                     printvtype(varType); writeln;}
                    table[i].typePtr := varType;
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
        if sym = procsym then procFunc := proc_def
        else procFunc := func_def;

        getsym;
         if sym = ident then
            begin 
              enterVPFC (procFunc,0); 
              getsym 
            end
         else error(identifierExpected);

         {find any parameters the procedure/function has}
         {save tx, because we'll need the type of the function
          to update type of "shadow" assignment variable}
         funcEntry := tx;
          
         dxSaved := dx;
         if procFunc = proc_def then dx := DlSlRa_proc
         else dx := DlSlRa_func;

         parameterList(procFunc);
         dx := dxSaved;

         {functions must have a type}
         if procFunc = func_def then
           begin
             {writeln ('scanning function for a type');}
             if sym = colon then 
               begin
                getsym;
                varType := getType(sym);
                table[tx].typePtr := varType;

                {update the "shadow" assignment variable}
                table[funcEntry+1].typePtr := table[tx].typePtr;

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
{
   code[table[tx0].adr].ax := cx;
}
   {writeln('tidyup lev:',lev:1,' tx0:',tx0:0,' cx',cx:2);}
   if mainBody>=0 then begin
     {writeln ('mainbody at:',mainBody:2,' should jump to:',cx:3);}
     with code[mainbody] do
       ax := cx;
     end
   else 
     code[table[tx0].adr].ax := cx;

   {printTable;}

   gen(int, 0, dx);
   statement([semicolon, endsym]+fsys);

   (* either a return or end of program, which is it? *)
   if lev > 0 then
     begin
       if parentType = func_def then
         gen(ret, 1, 0) {return}
       else
         gen(ret, 0, 0) {return}
     end
   else 
     begin
       gen (xit, 0, 0); {exit program}
       {listcode;}
     end;

   test(fsys, [], blockEnd);

   {write('end of block, sym:');printSym(sym);}
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
                if (s[tops]<0) or (s[tops]>peekPokeMemSize) then begin
                  writeln('opr_peek, request out of bounds:',s[tops]);
                  s[tops] := 147; 
                end 
                else s[tops] := peekPokeMem[s[tops]];
                {writeln(s[tops]:3);}
           end;

           opr_poke: begin {15, poke}
                tops := tops -2;
                if (s[tops+1]<0) or (s[tops+1]>peekPokeMemSize) then begin
                  writeln('opr_poke, request out of bounds:',s[tops+1]);
                end else 
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


  {built-in types}
  {uint16}
  {char}
  {boolean, with false and true consts}
  loadBuiltinTypes;


  for ch := chr(0) to chr(255) do ssym[ch] := nul;
   
  word[ 1] := 'and       '; wsym[ 1] := andsym;
  word[ 2] := 'array     '; wsym[ 2] := arraysym;
  word[ 3] := 'begin     '; wsym[ 3] := beginsym;
  word[ 4] := 'case      '; wsym[ 4] := casesym;
  word[ 5] := 'chr       '; wsym[ 5] := chrsym;
  word[ 6] := 'const     '; wsym[ 6] := constsym;
  word[ 7] := 'div       '; wsym[ 7] := divsym;
  word[ 8] := 'do        '; wsym[ 8] := dosym;
  word[ 9] := 'downto    '; wsym[ 9] := downtosym;
  word[10] := 'else      '; wsym[10] := elsesym;
  word[11] := 'end       '; wsym[11] := endsym;
  word[12] := 'for       '; wsym[12] := forsym;
  word[13] := 'function  '; wsym[13] := funcsym;
  word[14] := 'if        '; wsym[14] := ifsym;
  word[15] := 'mod       '; wsym[15] := modsym;
  word[16] := 'not       '; wsym[16] := notsym;
  word[17] := 'or        '; wsym[17] := orsym;
  word[18] := 'ord       '; wsym[18] := ordsym;
  word[19] := 'peek      '; wsym[19] := peeksym;
  word[20] := 'poke      '; wsym[20] := pokesym;
  word[21] := 'pred      '; wsym[21] := predsym;
  word[22] := 'procedure '; wsym[22] := procsym;
  word[23] := 'repeat    '; wsym[23] := repeatsym;
  word[24] := 'succ      '; wsym[24] := succsym;
  word[25] := 'then      '; wsym[25] := thensym;
  word[26] := 'to        '; wsym[26] := tosym;
  word[27] := 'type      '; wsym[27] := typesym;
  word[28] := 'until     '; wsym[28] := untilsym;
  word[29] := 'var       '; wsym[29] := varsym;
  word[30] := 'while     '; wsym[30] := whilesym;
  word[31] := 'write     '; wsym[31] := writesym;
  word[32] := 'writeln   '; wsym[32] := writelnsym;

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


  declbegsys := [typesym, constsym, varsym, procsym, funcsym];
  statbegsys := [beginsym, ifsym, whilesym, repeatsym, forsym,pokesym];
  facbegsys  := [ident, number, charstring, peeksym, lparen, notsym,
                ordsym,predsym,succsym];
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


  block(startingLevel, 
     numReservedTypes -1 {does a pre increment, so subtract 1 here}, 
     onbekend, [period]+declbegsys+statbegsys);
  if sym <> period then error(periodExpected);
  if errcount=0 then begin
    interpret;
    outToAssembler;
  end else write(' errors in TinyPascal program');

99: writeln
end.
