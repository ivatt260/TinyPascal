program TinyPascal(input,output, stdErr);
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
        - goes to fixed-name assembler output file.}
{JAS - July12 2024, writing output to assembler code for RCA1802}
{JAS - June23 2024, working on error prints, and on following the "base" flow}

{TinyPascal compiler with code generation}

label 99;

	const 
           setParsing = true; {are we parsing and generating SET code?}
           normalParsing = false; {NON-set parsing and generation of code}
           maxerrors = 10;    {max number of errors before aborting}
           norw = 41;        {no. of reserved words}
	   txmax = 200;       {length of identifier table}
	   nmax = 5;         {max. no. of digits in numbers}
	   al = 10;           {length of identifiers}
	   amax = 32768;       {maximum address}
	   uint16amax = 65536;      {maximum uint16}
	   levmax = 20;       {maximum depth of block nesting}
	   cxmax = 20000;     {size of code array}
	   constCharMax=2048; {size of static string store}
	   maxparams=10;      {max number of params for func/proc}
           numReservedTypes=7;{the number of reserved types}
           startingLevel=0;   {block starting level, keep at 0}

	   DlSlRa_main = 3;   {stack space for dynamic link, static
			       link and return address for main body}

	   DlSlRa_proc = 3;   {stack space for dynamic link, static
			       link and return address for procedures}

	   DlSlRa_func = 3;   {stack space for dynamic link, static
			       link and return address for functions}

           noType = -123;       {type not (yet?) found on table}

           {table entry for built-in types}
           unknownType = 1;
           uint16Type = 2;
           charType = 3;
           booleanType = 4;
           {... highest number of type, for "Type" type checking}
           topBuiltInType = booleanType;

           {not really supported fully:}
           charStringType = 5;

           {set size}
           const maxSetSize = 64;


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

        const IO_Read = 34;
        const IO_Readln = 35;

        {uint16 operators}
	const opr_neg_uint16 = 0;   {negative number uint16}
	const opr_plus_uint16 = 1;  {plus uint16}
	const opr_minus_uint16= 2;  {minus}
	const opr_mul_uint16 = 3;   {multiply}
	const opr_div_uint16 = 4;   {divide}
	const opr_mod_uint16 = 5;   {MOD}
	const opr_eql_uint16 = 6;   {eql}
	const opr_neq_uint16 = 7;   {neq}
	const opr_lss_uint16 = 8;   {lss}
	const opr_geq_uint16 = 9;   {geq}
	const opr_gtr_uint16 = 10;  {gtr}
	const opr_leq_uint16 = 11;  {leq}
        const opr_and_uint16 = 12;  {and}
        const opr_or_uint16  = 13;  {or}
        const opr_not_uint16 = 14;  {NOT}

        {direct memory access operators}
        const opr_peek= 15;  {peek at RAM}
        const opr_poke= 16;  {poke at RAM}

        {Set word-wide (16 bit) operators}
        const opr_or_set16     = 17;
        const opr_and_set16    = 18;
        const opr_dotdot_set16 = 19;       {".." operator}
        const opr_invert_set16 = 20;       {16 bit "not"}
        const opr_int_toSet16  = 21;       {promote enum to set for comparison}
        const opr_eql_set16    = 22;       {"=" operator}
        const opr_neq_set16    = 23;       {"<>" operator}
        const opr_incl_set16   = 24;       {"<=" operator}
        const opr_flip_tos16   = 25;       {tos := tos-1, tos-1 := tos}



        const peekPokeMemSize = 32767;


	type errorsym = (eqlExpected, constExpected, varExpected,
                typeNotSupported, packedNotSupported, 
		stmtBegsym, boolErr,
		stringStore, setSize, setTypeExpected,
		semicolonExpected,
		colonExpected, charExpected,
		CVPFexpected,blockEnd,
		periodExpected, idNotFound, 
		assignToConstant, 
		beginExpected, becomesExpected, identifierExpected,
		procedureExpected, thenExpected, endExpected, doExpected, statenderr, 
		constVarExpected, rparenExpected, ofExpected, rbracketExpected,
		lparenExpected, commaExpected, equalsExpected, dotdotExpected,
		facbegerr, typeMismatch, typeExpected, charNotCharStringExpected, invOpForType,
		nountil, nmaxnumexpected,blocknumexpected, facnumexpected,procedureLevel);



        {on-screen representation stype}
        type displayStyle = (noDisplay, numberDisplay, charDisplay, booleanDisplay,enumDisplay);

	type symbol =
	   (nul,ident,number,quote,charString,plus,minus,times,slash,
	    eql,neq,lss,leq,gtr,geq,lparen,rparen,comma,semicolon,rbracket,lbracket,
	    colon,period, dotdot, becomes,beginsym,endsym,ifsym,insym,thensym,
	    whilesym,dosym,constsym,varsym,procsym, programsym,
	    elsesym,repeatsym,untilsym, peeksym, pokesym,
	    typesym, andsym, divsym, modsym, notsym, orsym,
            predsym,succsym,ordsym, chrsym, pointer,
            packedsym, arraysym, filesym, setsym, recordsym, ofsym, 
            readsym, readlnsym,
  	    funcsym,forsym,tosym,downtosym,casesym,writesym,writelnsym);

    alfa = packed array [1..al] of char;
    obj = (const_def,simpType_def,var_def,proc_def,func_def,set_def,onbekend);
    symset = set of symbol;

    {PCode functions}
    fct = (ver, lit, lod, sto, opr, bbnd,
           stk, int, pcal, fcal, pret, fret,
           jmp, jpc, tot, tin, xit);

    instruction = packed record
                     createLabel: boolean;   {if true create label}
                     fn: fct;           {function code}
                     lv: 0..levmax;     {level}
                     ax: 0..amax        {displacement address}
                  end;

{table likely needs revamping; see fct and code for more}
{XXX edits needed!}
{   lit x,a  :  load constant a
    opr x,a  :  execute operation a
    lod l,a  :  load varible l,a
    sto l,a  :  store varible l,a
    cal l,a  :  call procedure a at level l
    int l,a  :  increment t-register by a
    jmp x,a  :  jump to a
    jpc x,a  :  jump conditional to a
    ret x,a  :  return from a procedure call
    tot x, a : write out a number/string to the output stream
    tin x, a : read in a number/string from the input stream.
    xit x,a  :  exit the program.   
    stk l,a  :  increment/decrement stack by a words (16 bits)
}

var 
    rvForMe: ShortString;
    ch: char;         {last character read}
    sym: symbol;      {last symbol read}
    id: alfa;         {last identifier read}
    num: integer;     {last number read}
    cc: integer;      {character count}
    ll: integer;      {line length}
    kk, errcount: integer;
    cx: integer;      {code allocation index}
    line: array [1..1024] of char;
    a: alfa;
    code: array [0..cxmax] of instruction;
    word: array [1..norw] of alfa;
    wsym: array [1..norw] of symbol;
    ssym: array [char] of symbol;
    mnemonic: array [fct] of packed array [1..5] of char;

    (* for writing out assembler *)
    omnemonic: array [fct] of packed array [1..7] of char;

    typebegsys, exprbegsys, simpexsys, declbegsys, statbegsys, facbegsys, termbegsys: symset;

    table: array [0..txmax] of
           record 
              {ASCII name}
              name: alfa;

              {Internal type - if > 0, points to a table index of type}
              typePtr:integer;

              case kind: obj of
                const_def: (
                           value,parent: integer);

                simpType_def: (size,lowerBound,upperBound:integer;
                           display:displayStyle) ;

                var_def, func_def, proc_def, set_def: (
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


procedure parseCommandLine;

{just a framework test for now}
{var i: integer;}
begin

	writeLn({$ifDef Darwin}
			// on Mac OS X return value depends on invocation method
			'This program was invoked via: ',

		{$else}

			// Turbo Pascal-compliant paramStr(0) returns location
			'This program is/was stored at: ',

		{$endIf}

		paramStr(0));


  if paramCount() > 0 then begin
    writeln();
    writeln('to invoke TinyPascal, use std input redirection, e.g. "./TinyPascal < myProg.mod"'); 
    writeln('... This will change in the future, but until then... :-|');
    writeln();
    goto 99;
  end;
{
writeln('parseCommandLine; paramCount:',paramCount());

	for i := 1 to paramCount() do
	begin
		writeLn(i:2, '. argument: ', paramStr(i));
	end;
}
    end;
(********************************************************)
{ wordWideOp - do binary math on bits in an integer
               for packing "set" bits and and/or/etc
               with what is there. 

               Used at compile time for optimizing set
               initializer code, and for the interpreter
               for interpreting the pcode on the PC.
}
  function wordWideOp(opr,start, fin:integer ):integer;
    var divisor, result, ctr, newStart, newFin: integer;
    begin
      divisor := 2; {divisor}
      result := 0;
      newStart := start;
      newFin := fin;

      {writeln('START WWO - opr:',opr:3,' start:', start:5, ' fin:',fin:5);}

      for ctr := 1 to 16  do
        begin
         {remove the LSB}
         newStart := newStart div divisor; 
         newStart := newStart * divisor;

         newFin := newFin div divisor; 
         newFin := newFin * divisor;
                 
         {writeln('oos, opr:',opr:0,
            ' newStart:',newStart:4,
            ' start:',start:4, 
            ' newFin:',newFin:4,
            ' fin:',fin:4, ' divisor ',divisor:4);}
            

         if opr = opr_or_set16 then begin
           if (newStart <>start) or (newFin <> fin) then begin
           {writeln ('bit is 1'); }
           result := result + 65536; end
         end;
         if opr = opr_and_set16 then begin
           if (newStart <>start) and (newFin <> fin) then begin
           {writeln ('bit is 1');} 
           result := result + 65536; end
         end;

         if opr = opr_invert_set16 then begin
           {writeln ('invert_set, newStart:',newStart:3,' start:',start:3);}
           if newStart = start then 
             result := result + 65536;
         end;

                
           {s[tops] := fin; s[tops+1] := start;}
           {ok, now lets "reset" our bit test flag and continue}
           fin := newFin; start := newStart;

           {increase the divisor}
           divisor := divisor * 2;

           {slide the result to the right}
           result := result div 2;
         end;


       {writeln('wordWideOp:',opr:0,' returning:',result:6);}
       wordWideOp := result;
     end;

(********************************************************)
procedure outToAssembler;
  type instr = set of fct;
  var i: integer;
  var tfOut: Text;
  var instr1, instr2, instr3, instr4: instr;

  {flag lines for jumps, calls, etc label printing}
  procedure genLabelFlags;
    var i: integer;
    begin

    {writeln('genLabelFlags starting');}
    for i := 0 to cx-1 do
      with code[i] do
        if fn in [fcal,pcal,jpc,jmp] then begin
          {writeln ('setting genLabelFlags true for ',i:4,ax:4);}
          code[ax].createLabel := true;
         end;
    end; {genLabelFlags}
     
  begin {list code generated for this block}
    {mnemonic, level, ax}
    instr4 := [lod, sto,tot,stk]; 

    {mnemonic, ax}
    instr3 := [lit,ver,bbnd,pcal,fcal,int,jmp,jpc];

    {mnemonic, level, or, for opr, mnemonic, ax.0<<2}
    instr2 := [opr];

    {mnemonic only}
    instr1 := [pret,fret,tin,xit];

    Assign (tfOut,'assemblerOut.asm');
    rewrite(tfOut);

    {tag lines for labels, if required}
    genLabelFlags;

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
    writeln(tfOut,'OPVER      EQU (000H SHL 1)');

    writeln(tfOut,'OPLIT      EQU (001H SHL 1)');
    writeln(tfOut,'OPLOD      EQU (002H SHL 1)');
    writeln(tfOut,'OPSTO      EQU (003H SHL 1)');
    writeln(tfOut,'OPOPR      EQU (004H SHL 1)');
    writeln(tfOut,'BBOUND     EQU (005H SHL 1)');

    writeln(tfOut,'OPSTK      EQU (006H SHL 1)');
    writeln(tfOut,'OPINT      EQU (007H SHL 1)');
    writeln(tfOut,'OPPCAL     EQU (008H SHL 1)');
    writeln(tfOut,'OPFCAL     EQU (009H SHL 1)');
    writeln(tfOut,'OPPRET     EQU (00AH SHL 1)');
    writeln(tfOut,'OPFRET     EQU (00BH SHL 1)');

    writeln(tfOut,'OPJMP      EQU (00CH SHL 1)');
    writeln(tfOut,'OPJPC      EQU (00DH SHL 1)');

    writeln(tfOut,'TXOUT      EQU (00EH SHL 1)');
    writeln(tfOut,'TXTIN      EQU (00FH SHL 1)');
    writeln(tfOut,'OPXIT      EQU (010H SHL 1)');
    writeln(tfOut);
    writeln(tfOut,'PASPROG    EQU ORGINIT + 0800H');
    writeln(tfOut,'          ORG  PASPROG');
    writeln(tfOut);

      for i := 0 to cx-1 do
         with code[i] do
            begin
              writeln(tfOut);
              writeln(tfOut, ';  ', i:5, mnemonic[fn]:5, lv:3, ax:5);

              {write label, if required}
              if createLabel then
                 writeln(tfOut,'LINE',i:0);

              {write the name}
              writeln(tfOut, '          DB      ',omnemonic[fn]);

              {do we have the level for this instruction?}
              if (fn in instr4) or (fn in instr2) then begin
                if fn in instr2 then
                writeln(tfOut, '          DB        (',ax:0,' SHL 2) ; instr2, ax, opr')
                else
                writeln(tfOut, '          DB      ',lv:0,'   ; instr2 not opr, so using level');
                end;

              {do we have ax for this instruction?}
              if (fn in instr4) or (fn in instr3) then
                case fn of
                  opr:  writeln(tfOut, '          DW     ',ax:5);
                  stk:  writeln(tfOut, '          DW     (',ax:0,' SHL 1)');
                  lit:  writeln(tfOut, '          DW     ',ax:5);
                  lod:  writeln(tfOut, '          DW     (',ax:0,' SHL 1)');
                  sto:  writeln(tfOut, '          DW     (',ax:0,' SHL 1)');
                  fcal: writeln(tfOut, '          DW     LINE',ax:0);
                  pcal: writeln(tfOut, '          DW     LINE',ax:0);
                  int:  writeln(tfOut, '          DW     (',ax:0,' SHL 1)');
                  jmp:  writeln(tfOut, '          DW     LINE',ax:0);
                  jpc:  writeln(tfOut, '          DW     LINE',ax:0);
                  pret: writeln(tfOut, '          DW     ',ax:5);
                  fret: writeln(tfOut, '          DW     ',ax:5);
                  xit:  writeln(tfOut, '          DW     ',ax:5);
                  tin:  writeln(tfOut, 'text in not implemented yet');
                  ver:  writeln(tfOut, '          DW     ',ax:5);
  
                  tot: begin
                    if lv = IO_charString then
                    writeln(tfOut, '          DW       CONSTCHARTXT+',ax:0)
                    else if (lv = IO_uint16) or (lv = IO_char) then
                    writeln(tfOut, '          DW     0 ; uint16, on stack')
                    else begin
  
                    writeln(tfOut, 'XXX unknown type, ',lv);
                    writeln('text out,  unknown type, ',lv);
                    end;
                  end;
  
                end
              {else writeln(tfOut, '; no ax field');}
         
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
        if kind <> simpType_def then
          {writeln('printvtype, mysym ',mysym:2,' points to alpha ',name)}
        else begin
          writeln ('TypeIdx: ',mysym:2, ' of type: ',name);
          write   ('  ...                         ');
        end;
      end;
    end;
  end;

(******************************************************)
procedure loadBuiltinTypes;
   begin {enter obj into table}
     with table[unknownType] do begin
       name := '-unknown-  ';
       kind := simpType_def;
       {typ := uint16Type;}
       size := 0;
       lowerBound :=0;
       upperBound :=0;
       display := noDisplay;
       typePtr := unknownType; {point to itself}
     end;
    
     with table[uint16Type] do begin
       name := 'uint16    ';
       kind := simpType_def;
       {typ := uint16Type;}
       size := 32767;
       lowerBound :=0;
       upperBound :=65535;
       display := numberDisplay;
       typePtr := uint16Type; {point to itself}
     end;
    
     with table[charType] do begin
       name := 'char      ';
       kind := simpType_def;
       {typ := charType;}
       size := 256;
       lowerBound :=0;
       upperBound :=255;
       display := charDisplay;
       typePtr := charType; {point to itself}
     end;

     with table[booleanType] do begin
       name := 'boolean   ';
       kind := simpType_def;
       {typ := booleanType;}
       size := 2;
       lowerBound :=0;
       upperBound :=1;
       display := booleanDisplay;
       typePtr := booleanType; {point to itself}
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
     {printTable;}


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
      dotdot: writeln ('dot-dot');
      quote: writeln('quote');
      peeksym: writeln('peeksym');
      pokesym: writeln('pokesym');
      typesym: writeln('typesym');
      predsym: writeln('predsym');
      succsym: writeln('succsym');
      ordsym: writeln('ordsym');
      chrsym: writeln('chrsym');
      pointer: writeln('pointer');
      packedsym: writeln('packedsym');
      arraysym: writeln('arraysym');
      filesym: writeln('filesym');
      setsym: writeln('setsym');
      recordsym: writeln('recordsym');
      ofsym: writeln('ofsym');
      readsym: writeln('readsym');
      readlnsym: writeln('readlnsym');
      else writeln('sym not decoded');
    end;
    if sym=ident then writeln('... ident is ',id);
  end;
(********************************************************)

procedure error(n: errorsym);
begin
  writeln(' ****',' ': cc-1, '^'); errcount := errcount+1;
  write(' err count:',errcount:0,' ');
  case n of
      periodExpected : writeln('"." expected');
      colonExpected : writeln('":" expected');
      semicolonExpected : writeln('";" expected');
      eqlExpected: writeln('"=" expected');
      rbracketExpected : writeln('"]" expected');
      rparenExpected : writeln('")" expected');
      lparenExpected : writeln('"(" expected');
      becomesExpected : writeln('":=" expected');
      commaExpected : writeln('"," expected');
      equalsExpected: writeln('"=" expected');
      dotdotExpected: writeln('".." expected');

      beginExpected : writeln('keyword "begin" expected');
      thenExpected : writeln('keyword "then" expected');
      endExpected : writeln('keyword "end" expected');
      doExpected : writeln('keyword "do" expected');
      ofExpected : writeln('keyword "of" expected');
      nountil: writeln('keyword "until" expected');

      setSize: writeln('set exceeds max size');
      setTypeExpected: writeln('a "set" type expected');
      typeExpected : writeln('builtin or defined type identifier expected');
      charExpected : writeln('char type expected');
      constExpected: writeln('constant expected');
      varExpected: writeln('const ident found, can not assign to it');
      stmtBegsym: writeln('can not start a statement with this');
      stringStore: writeln('constant string store overflow');
      CVPFexpected: writeln('"type", "const", "var", "procedure", "function" expected');
      blockEnd: writeln('keyword can not end a block');
      idNotFound : writeln('id not found');
      assignToConstant : writeln('cant assign a value to constant here');
      identifierExpected: writeln('identifier expected');
      procedureExpected : writeln('procedure ident expected');
      statenderr : writeln('unexpected text at end of statement');
      constVarExpected : writeln('constant or variable expected');
      facbegerr: writeln ('expected factor keywords');
      charNotCharStringExpected: writeln ('charString found, but currently only support single char here');
      typeMismatch: writeln('type mismatch');
      invOpForType: writeln('invalid operation for type');
      boolErr: writeln('found boolean comparitors, but not a boolean expression?');
      blocknumexpected : writeln('blocknumber expected');
      nmaxnumexpected : writeln('nmaxnumber expected');
      facnumexpected : writeln('facnumber expected');
      procedureLevel: writeln('procedure nesting too great, recompile with bigger levmax constant');
      typeNotSupported: writeln ('type not supported yet');
      packedNotSupported: writeln ('"PACKED" not supported yet');

      else writeln('err not decoded... complain please');
      end;

      if errcount > maxErrors then begin
        writeln('---------------- too many errors ------------------');
        goto 99;
      end;

end {error};


(******************************************************
 *
 *  TYPE CHECKING
 *
 *  standards not great at solving this; if some idiot 
 *  (i.e. me) renames a type for type checking, but assigns
 *  a base type to it, eg j:=2 (see example below) is that
 *  an error? is assigning i:=j an error? FreePascal says
 *  no, so we:
 * 
 *  try and find the base types; everything should point to
 *   using field "typePtr" to the base (or, basic) type.
 *  
 *  eg, in the example below, the only error will be 
 *  assigning a uint16 to a char (l := k;)
 *  
 *  type
 *    integer = uint16;
 *    int2 = integer;
 *  
 *    var i: uint16;
 *    var j: integer;
 *    var k: int2;
 *    var l: char;
 *    begin 
 *      j := 10; i := j; j := i; k := i; j := k;
 *      l := k;
 *    end.
 *****************************************************)

procedure checkTypes(lhs,rhs:integer; where:ShortString);
  begin

  {writeln('1:checkTypes:lhs:',lhs:0,' rhs:',rhs:0,' at ',where);}

  {FIRST, check to see if one of the types is "noType"}
  {if we have a "noType" on one side, (eg, on comparisons)
   then try and copy over a valid type from the other side}
  if rhs=noType then rhs := lhs;
  if lhs=noType then lhs := rhs;
  if rhs=noType then begin
    writeln ('checkTypes, both sides noType');
    error(typeMismatch);
  end;

  {go and find actual type entries - hopefully a base type}
  if (lhs>0) and (lhs<=txmax) then lhs := table[lhs].typePtr;
  if (rhs>0) and (rhs<=txmax) then rhs := table[rhs].typePtr;

  {writeln('2:checkTypes:lhs:',lhs:0,' rhs:',rhs:0);}

    if lhs<>rhs then begin
      writeln('checkTypes ERROR: at ',where);
      writeln('lhs type entry:',lhs:0,' rhs type entry:',rhs:0);
      error (typeMismatch);
    end;
  end; {checkTypes}


(******************************************************
 *
 * set routines
 *
 ******************************************************)

function setToBit16(intValue:integer):integer;
  var rv:integer;

  {oh... to have SHL 3 or equivalent ...}
begin
  {write ('setToBit16, getting:',intValue:0);}

  rv := intValue mod 16;

  {write ('...after MOD 16 ...', intValue:0);}

  case rv of
    0: rv := 1;
    1: rv := 2;
    2: rv := 4;
    3: rv := 8;
    4: rv := 16;
    5: rv := 32;
    6: rv := 64;
    7: rv := 128;
    8: rv := 256;
    9: rv := 512;
   10: rv := 1024;
   11: rv := 2048;
   12: rv := 4096;
   13: rv := 8192;
   14: rv := 16384;
   15: rv := 32768;
  end;

  {writeln('...as bit:',rv:0);}
  setToBit16 := rv;
end;


(******************************************************)
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
   writeln('in getsym, constCharIndex=',constCharIndex);}
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
     {writeln('ccs, after while ch:',ch,':');}
     {make last character a nul}
     constCharArray[constCharIndex] := #0;
     constCharIndex := constCharIndex+1;
     {writeln('in getsym2, constStringStart=',constStringStart);
      writeln('in getsym2, constCharIndex=',constCharIndex);}
   getch;
  {writeln('ccs, final ch:',ch,':');}
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
  
   if ch = '.' then
     begin getch;
     if ch = '.' then
     begin sym := dotdot; getch
     end else sym := period;
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
  {writeln('end of getsym:');printSym(sym);}
end {getsym};

(********************************************************)

(* parse Program symbol, just skip until first semicolon,
   then getsym. Not used yet, but there so that pascal progs
   can be parsed in most parsers *)

procedure parseProgram();
  begin
    repeat getsym; until sym = semicolon;
    if sym = semicolon then getsym;
  end;


(********************************************************)
procedure gen(x: fct; y,z: integer);
begin if cx > cxmax then
           begin write(' program too long'); goto 99
           end;
   with code[cx] do
      begin createLabel := false; fn := x; lv := y; ax := z
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
                         should point to table entry, or "noType"}
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



   (************************************************************)
   {is this type a set type? Used in Factor }
   function isSetType (inty:integer) : boolean;
     begin
       isSetType := true;
       if inty = noType then isSetType := false
       else if (inty<1) or (inty>tx) then isSetType := false
       else isSetType := table[inty].kind = set_def;
     end;


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
            if (table[i].kind = simpType_def) or
               (table[i].kind = set_def)  then begin {4}
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
          returning :=noType; 
        end; {2}
       {write('getType, returning:');printvtype(returning);}

       getType := returning;
     end {1, getType};

   (************************************************************)
   procedure enterNewType;
   begin {enter obj into table}
     tx := tx + 1;
     with table[tx] do begin
       typePtr := tx; {point to ourselves}
       name := id;
       kind := simpType_def;
       display:= enumDisplay;
       size := 0;
       lowerBound :=0;
       upperBound :=0;
     end;
   end; 

   (************************************************************)
   procedure enterNewEnumElement(var p_entry,val:integer) ;
   begin {enter obj into table}
     tx := tx + 1;
     {writeln('newEnumElement, tx:',tx:2,' value ',val:2);}
     with table[tx] do begin
       name := id;
       kind := const_def;
       {typ := enumElement;}
       typePtr := p_entry;
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

    (************************************************************)
    {some places we expect a single char, but we parse single chars
     in quotes as a charString, so if this charString is a single
     char, (2 bytes; char + NULL) then just return it as such}

    function extractCharTypeFromCharString():integer;
      begin
       
        {writeln ('constCharIndex:',constCharIndex:3,
          'constStringStart:',constStringStart:3);}
        {writeln (' have charString of size ',
          constCharIndex - constStringStart,  
          ' char as decimal ',byte(constCharArray[constStringStart])
          );}
        

        if constCharIndex-constStringStart <> 2 then begin
          error(charNotCharStringExpected);
          extractCharTypeFromCharString := noType;
        end else begin
          extractCharTypeFromCharString := 
            ord(constCharArray[constStringStart]);
        end;

        {remove this character from the string pool}
        constCharIndex := constStringStart;
      end; {extractCharFromCharString}

   (************************************************************)
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
                      parent := uint16Type;
                   end;
         {variable, could have parameters that are at the body level}
         var_def: begin level := lev+levInc; adr := dx; dx := dx + 1;
                  end;
         proc_def, func_def:
                  begin
                    level := lev;
                    nparams := 0;
                  end;
         simpType_def: begin 
                     write('enter, simpType_def should not be here  not coded yet'); 
                   end;
         set_def: begin
                    writeln('enterVPFC, set_def, fill this out');
                  end;
         onbekend: begin writeln('enter, unknown - onbekend - not coded properly');end;
        end; {with end}
      end
   end {enter};

   (****************************************)

   procedure blockTypeDeclaration;
   var myTypetx: integer;
       myval: integer;

     (*****************************)
     procedure parseTypeDeclaration;
       { do the type declaration as part of block type decl}
       var packedFound: boolean;

       (************************)
       procedure parseSimpleType;
         {for ranges:}
         var firstIdentifier: integer;
         var secIdentifier: integer;
         var lhsParent, rhsParent, lhsValue, rhsValue: integer;
         var iIsTypeConst: boolean;
         var iIsTypeType: boolean;

         {parseSimpleType}
         {looking for an identifier, lparen, or constant}
        
         begin {3}
           {ok, lets see if we have an ident here, that is a type or constant}

           {Enumerations are fairly easy, as we have "(a,b,c)", while ranges
            or just copying a type involves finding an ident, and working
            out what path to take}

           {DECLARATION is an identifier}
           iIsTypeConst := false;
           iIsTypeType := false;

           if sym = ident then begin
             { writeln ('we have an ident');}
             firstIdentifier := position(id); 
             if firstIdentifier >0 then begin
               {writeln ('parseSimpleType, have firstIdentifier:',firstIdentifier:2);}
               iIsTypeConst := table[firstIdentifier].kind = const_def;
               iIsTypeType := table[firstIdentifier].kind = simpType_def;
             end else begin
              writeln('at parseSimpleType, ');
              error(idNotFound);
            end;
           end;

           {writeln('after ident, ...');
           if iIsTypeConst then writeln ('IT is a constant ident');
           if iIsTypeType then writeln ('IT is a type ident');}
           
           {------------------------------------------------------}

           {TYPE IDENTIFIER - is this just a re-definition of a type?}
           {eg: type juice = uint16;}

           if iIsTypeType then begin {4}
             {found an id, just copy fields over, and we will
              check it out later}
             {writeln('have valid id:',firstIdentifier);}
             {writeln('isTypeType starting,myTypetx:',myTypetx:0, ' firstIdentifier:',firstIdentifier:0);}

             {myval := getType(sym);
             writeln('myval from getType:',myval);
             writeln('copy all this over to id:',myTypetx:3);}
             table[myTypetx].kind := table[firstIdentifier].kind;
             table[myTypetx].size := table[firstIdentifier].size;
             table[myTypetx].lowerBound := table[firstIdentifier].lowerBound;
             table[myTypetx].upperBound := table[firstIdentifier].upperBound;
             table[myTypetx].display := table[firstIdentifier].display;

             {writeln('typyptt,myTypetx:',myTypetx:0,' fd:',firstIdentifier:0);}
             table[myTypetx].typePtr := table[firstidentifier].typePtr;
             getsym;
           end {4}

           {------------------------------------------------------}
           {ENUMERATIONS 
             eg: type weekday = (Monday, Tuesday); }

           else if sym = lparen then begin {4}
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
  
               if sym = ident then getsym else error(identifierExpected);
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
  
           end {4} {lparen}

           {------------------------------------------------------}
           {RANGES:
            type arrRange = 'A'..'C'; or
            type arrRange = 0..9; or
            type zingaro = false..true; }

           else 
             begin {4}
               {write ('hmmm pst :');printSym(sym);}

               if iIsTypeConst or (sym in [number, charstring]) then begin {5}
                 if iIsTypeConst then begin {6}
                   lhsParent := table[firstIdentifier].parent;
                   lhsValue := table[firstIdentifier].value;
                end {6}
                else if sym = number then begin {6}
                   lhsParent := uint16Type;
                   lhsValue := num; {global value for a parsed number}
                end {6}
               else if sym = charstring then begin {6}
                 lhsParent := charType;
                 lhsValue := extractCharTypeFromCharString();
                 {if we had an error in extraction, to ward
                  off a bunch of other error checks:}
                 if lhsValue = noType then lhsValue := 0;
               end; {6}

               getsym;
             end; {5}

             if sym = dotdot then begin {6}
               getsym;

               {write ('after dotdot, sym is:');printSym(sym);}

              if sym in [ident, number, charstring] then begin {7}
                if sym = ident then begin
                  secIdentifier := position(id);
                  if secIdentifier >0 then begin
                    rhsParent := table[secIdentifier].parent;
                    rhsValue := table[secIdentifier].value;
                  end else begin
                    writeln('in dotdot:');
                    error(idNotFound);
                    rhsParent := 0;
                    rhsValue := 0;
                  end;

               end else if sym = number then begin
                  rhsParent := uint16Type;
                  rhsValue := num; {global value for a parsed number}
               end else if sym = charstring then begin
                 rhsParent := charType;
                 rhsValue := extractCharTypeFromCharString();
                 {if we had an error in extraction, to ward
                  off a bunch of other error checks:}
                 if rhsValue = noType then rhsValue := 1;
                   
               end; {7}

               {hopefully the range has same parent types and
                values are ascending}

               if (rhsParent = lhsParent) and 
                  (rhsValue > lhsValue) then begin
                {writeln ('range seems ok, enter data');}

                with table[myTypetx] do begin
                  typePtr := lhsParent;
                  lowerBound := lhsValue;
                  upperBound := rhsValue;
                  size := rhsValue - lhsValue + 1;
                  {displayStyle := numberDisplay;}
                end;

              end;

              {Whew!!!!}
              getsym

             end {6}
              else error (dotdotExpected);
            end {5}
          end; {4}
        end; {parseSimpleType}

      (*********************************)
      procedure parseArrayType(pkd:boolean);
      begin {parseArrayType}
        if pkd then error(packedNotSupported);
        writeln ('parseArrayType not coded yet');
      end; {parseArrayType}

      (*********************************)
      procedure parseFileType(pkd:boolean);
      begin {parseFileType}
        if pkd then error(packedNotSupported);
        writeln ('parseFileType not coded yet');
      end; {parseFileType}

      (*********************************)
      procedure parseSetType(pkd:boolean);
        var typeId:integer;
        begin {parseSetType}
          if pkd then error(packedNotSupported);

          {writeln ('myTypetx is:',myTypetx:3);}
          table[myTypetx].kind := set_def;


          getsym;
  
          if sym = ofsym then begin {1}
            getsym;
            if sym = ident then begin {2}
              typeId := position(id);
              {writeln ('set, typeId:',typeId:3);}
              if typeId >0 then begin {3}
                if table[typeId].kind = simpType_def then begin {4}
                  if table[typeId].size <= maxSetSize then begin {5}
                    table[myTypetx].typePtr := typeId;
                    table[myTypetx].lowerBound := table[typeId].lowerBound;
                    table[myTypetx].upperBound := table[typeId].upperBound;
                    table[myTypetx].size := table[typeId].size;
       

                  end {5}
                    else error(setSize); 
                   
                end{4} else error(typeExpected);
              end {3}
               else error (identifierExpected);
              getsym;
  
            end {2}
              else error(identifierExpected); 
          end {1}
            else error (ofExpected);
        end; {parseSetType}

      (*********************************)
      procedure parseRecordType(pkd:boolean);
      begin {parseRecordType}
        if pkd then error(packedNotSupported);
        writeln ('parseRecordType not coded yet');
      end; {parseRecordType}

      (*********************************)
      begin {parseTypeDeclaration}
        packedFound := false;

        if sym in typebegsys then begin
            {writeln ('in parseTypeDeclaration');}
            if sym = packedsym then begin
              packedFound := true; 
              getsym;
            end;

            case sym of
              arraysym: parseArrayType(packedFound);
              filesym:  parseFileType(packedFound);
              setsym:   parseSetType(packedFound);
              recordsym: parseRecordType(packedFound);
              pointer: error (typeNotSupported);
           end;
        end else begin
          parseSimpleType;
        end;
      end; {parseTypeDeclaration}

   (*********************************)
   begin {blockTypeDeclaration}
     myTypetx := noType; { incredibly invalid}
     myval := 0; {ordinal value of first index}

     if sym = ident then
      begin {2}
         enterNewType;
         myTypetx := tx;
         {writeln('blockTypeDeclaraion my tx is ',tx:3);}
         getsym;
         if sym in [eql, becomes] then
           begin {3}
             {writeln('have either eql or becomes');}
             if sym = becomes then error(eqlExpected);
             getsym;
             parseTypeDeclaration;
         end {3}
         else error(eqlExpected)
      end {2}
      else error(identifierExpected);
      {writeln('end blockTypeDeclaration');}
   end {blockTypeDeclaration};

   (****************************************)
   procedure blockConstDeclaration;
   var orig:integer;

   begin if sym = ident then
      begin getsym;
         if sym in [eql, becomes] then
         begin if sym = becomes then error(eqlExpected);

            {start by enter the name in TABLE}
            enterVPFC(const_def,0);

            getsym;
            if sym = ident then 
              begin
               orig := position(id); 
               {writeln ('blockConstDec, orig is:',orig:3);}
               if table[orig].kind = const_def then
                 begin
                    {copy const to const}
                    table[tx].value := table[orig].value;
                    table[tx].parent := table[orig].parent;
                    {typePtr is a "all type" pointer}
                    table[tx].typePtr := table[orig].typePtr;

                  getsym
                 end
               else error (constExpected);

              end
            else if sym = number then
               begin 
                 {num is global id for last number read}
                 table[tx].value := num;
                 table[tx].typePtr := uint16Type;
                 getsym
               end
            else if sym = charString then 
               begin
                {if 1 char in string, get this if not an error will be printed}
                table[tx].value := extractCharTypeFromCharString();
                table[tx].parent := charType;
                {typePtr is a "all type" pointer}
                table[tx].typePtr := charType;
                getsym;
              end
            else
               error(constExpected)
         end else error(eqlExpected)
      end else error(identifierExpected)
   end {blockConstDeclaration};


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
   procedure printTable(where:ShortString);
     var i,j: integer;
     
     begin
     writeln ('---------------------------------------------');
     writeln(where);
     {writeln ('printTable for index ',tx0+1:3,' to ',tx:3);}
     {for i := tx0+1 to tx do}

     writeln ('printTable for index ',1:3,' to ',tx:3);
     for i := 1 to tx do
       with table[i] do
         begin
         write(i:3,' ',name,' ');
         write('*** typePtr:',typePtr:0,'*** ');
         printvtype(typePtr);

         case kind of
           const_def: begin
              write ('cnst;  val: ',value:5,' of enum type table entry: ',parent:3);
           end;

           var_def: begin
              write ('var;  lev: ',level:5,' stack: ',adr:3);
           end;

           proc_def: begin
              write ('proc: lev: ',level:5,' code: ',adr:3,' nparams:',nparams:2);
              for j := 1 to nparams do
                begin
                writeln();
                write('                      param:',j:2,' type: ');
                printvtype(ptype[j]);
                end;
              writeln;
           end;

           func_def: begin
              write ('func; lev: ',level:5,' code: ',adr:3,' nparams:',nparams:2);
              for j := 1 to nparams do
                begin
                writeln();
                write('                      param:',j:2,' type: ');
                printvtype(ptype[j]);
                end;
              writeln;
           end;

           simpType_def: begin
              write('type;  siz: ',size:5,' lbound:',lowerBound:2,
                    ' uBound:',upperBound:6,' dispStyle:');
              printStyle(display);
              {writeln;}
           end;

           set_def: begin
             writeln('set; lev: ', level:5,' Stack: ',adr:3, ' size: ',size:3);
           end;
          
           onbekend: begin
              writeln('unknown table entry - huh??');
           end;
else writeln('unknown case entry in printTable');
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
    function expression(fsys: symset; 
                        typ:integer;
                        expressionSet:boolean): integer;
         var relop: symbol;
         var expRTypLHS, expRTypRHS : integer;

(************************************************************)
      function simpleExpression(fsys: symset; typ:integer) : integer;
         var addop: symbol;
         var returnedTyp: integer;
         var expectedTyp: integer;

(************************************************************)
         function term(fsys: symset; typ:integer): integer;
            var termop: symbol;
         var termRTypLHS, termRTypRHS : integer;

(************************************************************)

{functions, with () and params, parse these params}
procedure parseFuncParams(i:integer);
  var pcount : integer;

  begin {1}
    pcount := 0;
    with table[i] do
      begin {2}
        { first, what is the type? this is what we return}
        returnedTyp := typ;

        {keep track of the number of parameters}

        if sym = lparen then begin {3}
          getsym;
          {create space for parameters}
          gen(stk, 1, DlSlRa_func+1);
          repeat

            {possible to get a "()" pair for zero paramters}
            {do expression if we have the parameter}
            if nparams > 0 then
              begin {4}
              pcount := pcount+1;
              {get the type we expect, and get the returned type}
              expectedTyp := pType[pcount];
              returnedTyp := 
                expression([rparen,comma]+fsys,expectedTyp,expressionSet);

              checkTypes(expectedTyp,returnedTyp,'func parameter check');

              {check if we should expect a comma or not}
              if pcount < nparams then
                begin {5}
                if sym=comma then getsym else error(commaExpected);
                end; {5}
              {else writeln ('pcount >= nparams');}

              end; {4}
          until (pcount >= nparams);
          {remove space for parameters}

          {we should have a rparen here to match the one above}
          if sym=rparen then getsym else error (rparenExpected);

          gen(stk, 0, DlSlRa_func + nparams+1);
        end  {3} 
        else if nparams>0 then error (lparenExpected);


      gen(fcal, lev-level, adr);
    end; {2}
end; {1}

(************************************************************)
            function factor(fsys: symset; typ:integer): integer;
               var i: integer;
                   mysym:symbol;

(************************************************************)
            {------------------------------}
            procedure factor_ident;
            begin
                i:= position(id);
                {write('QQQ:factor_ident, id:',i:0,' num:',num:0);
                writeln(' tx:',tx:0,' lev:',lev:0);}

                if i = 0 then error(idNotFound) else
                with table[i] do
                 case kind of
                    const_def: begin
                      {writeln('factor, have const_def, typePtr:',
                        typePtr:3,' parent:',parent:3,' value:',value:3);}
                      returnedTyp := parent; 
                      getsym;

                      {write('genLit in factor_ident: '); 
                      if expressionSet then writeln ('expressionSet') 
                      else writeln('NOT expressionSet');
                      writeln('factor ident, value:',value);
                      writeln('factor ident, cx: ',cx);}
                      returnedTyp := typePtr;

                      if expressionSet then gen(lit,0,setToBit16(value))
                      else gen(lit, 0, value);
                      end;
                    var_def: begin
                      {writeln('factor, found a var. typePtr:',typePtr);}
                      {Variable, return the type if we don't know statement type,
                       or if known type, check if correct, if not, error}
            
                      {writeln('factor, var_def pt 1, typ:',typ:2,' returnedTyp:',returnedTyp:2,
                      ' typePtr:',typePtr:2);}
            
                      {did we know what type to expect?}
                      if expectedTyp = noType then expectedTyp := typePtr;
                      returnedTyp := typePtr;

                      {writeln('factor, var_def pt 2, typ:',typ:2,' returnedTyp:',returnedTyp:2,
                      ' typePtr:',typePtr:2);}
            
                      {if we had a known type, and this var doesnt match...}
                      {checkTypes(expectedTyp,returnedTyp,'factor identifier');}
            
                      getsym;
                      gen(lod, lev-level, adr);
                      end;
                    proc_def: begin
                      error(constVarExpected);
                      getsym;
                      end;
                    func_def: begin
                      getsym;
                      parseFuncParams(i);

                      {ok, types. The function returns a type, no matter
                       what we expect, and no matter what the parameter
                       types are. So we get the returned type from the
                       function def. } 

                       expectedTyp := table[i].typePtr;
                       returnedTyp := table[i].typePtr;
                      end;
                    simpType_def: begin
                      returnedTyp := typ;
                      getsym;
                      gen(lod, lev-level, adr);
                    end;

                    set_def: begin
                     writeln ('set_def found hwwre');
                    end;

                 end; {case}
                 {writeln('QQQQ:factor, while, ident, returnedTyp is ',returnedTyp);
                 write('QQQQ: END factor_ident factot_ident end ');printSym(sym);}

            end; {factor_ident}

            {------------------------------}
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


            {------------------------------}
            procedure factor_charString;
              var intFromChar:integer;
              begin
                returnedTyp := charType;

                {only handle single chars here; the extract will check
                 that the incoming string is 1 character long, error if not}

                intFromChar := extractCharTypeFromCharString();
                {writeln ('factor_charString, have char of value ',intFromChar);}

                gen(lit, 0, byte(constCharArray[constStringStart]));
                getsym
              end; {factor_charString}


            {------------------------------}
            procedure factor_lparen;
              begin
                getsym; 
                {writeln('factor_lparen, expectedTyp '); printvtype(expectedTyp);}

                returnedTyp := expression([rparen]+fsys,expectedTyp,expressionSet);
                if sym = rparen then getsym else error(rparenExpected)
              end; {factor_lparen}

            {------------------------------}
            procedure factor_lbracket;
              var haveComma:boolean;
              var setElementType:integer;
              var curCX:integer;

              {lets see if we can compress some set initializer code}
              { example code:
                      9  lit  0    0 - zero at start push
                     10  lit  0    1 - push bit 1
                     11  opr  0   19 - OR it and leave on stack
                     (repeat lit/OR sequence for other bits)
                     12  sto  0    4 - store it.

                     hmmm - code not finished for "dotdot" sets.
              }

              procedure optimizeSetInitializer(initcx:integer);
                var ctr:integer;
                    finalCx: integer;
                    mysp: integer;
                    mystk: array[0..5] of integer;

                function canOptimize:boolean;
                  var c: integer;
                  var ret:boolean;
                  begin
                    ret := true;
                    for c := initcx to (cx-1) do
                      begin
                        if (code[c].fn = lit) or
                           (code[c].fn = opr) then begin
                             {writeln ('code at ',c:2,' is a lit or opr');}
                           end else begin
                             ret := false;
                             {writeln ('code at ',c:2,' is NOT a lit or opr');}
                           end;
                       end;
                   canOptimize := ret;
                 end; {canOptimize}
                             

                begin {optimizeSetInitializer}
                  {writeln('OP');
                  writeln('optimizeSetInitializer, cx:', cx:3,
                    ' initcx:',initcx:3);}
                  if canOptimize then begin {1}
                    {writeln ('canopt');}
                    mysp := 0;

                    {start in the lit/opr stream}
                    ctr := initcx;
                    finalCx := initcx+1;
  
                    
                    {go through producing literals, folowed by consuming (or, dotdot)
                     and, as this is not really a stack (produce-consume, etc) we know
                     the final result goes into the start element of the stack.

                     we will have a lit 0,0 at the beginning, which is the accumulator
                     for the final value.}

                      while ctr < cx do begin {2}
                        {writeln('op while, ctr:',ctr:0);}
                        if code[ctr].fn = lit then begin {3}
                          {producing literals on the stack}
                          mystk[mysp] := code[ctr].ax;
                          mysp := mysp + 1;
                          {writeln ('pushed ',mystk[mysp-1]:0,' on stack, mysp now:',mysp:0);}
                        end {3}

                        else if code[ctr].fn = opr then begin {3}
                          {consume pushed literals, and or them into the initial value}
                          mysp := 1; {sp 0 is the final result}

                          if code[ctr].ax = opr_or_set16 then begin {4}
                            mystk[0] := wordWideOp(opr_or_set16,mystk[1],mystk[0]);
                          end {4}
                          else if code[ctr].ax = opr_dotdot_set16 then begin {4}
                            {we have beginning bit and ending bit on our mini-stack}
                            while (mystk[1] > 0) and (mystk[1] <= mystk[2]) do begin
                              mystk[0] := wordWideOp(opr_or_set16, mystk[1],mystk[0]);
                              mystk[1] := mystk[1] * 2; {go for next bit}
                            end;
                          end {4}
                          else writeln ('can not be here, either');
                        end {3}
                        else writeln ('can NOT be here');

                        ctr := ctr+1;
                      end; {2}{while}
                       
  
                      {save the result}
                      code[initcx].ax := mystk[0];

                      {we have done some stuff, make cx point to next step}
                      {note that this will REMOVE the non-optimized code from
                       here, as the final number is saved in the step above}
                      cx := finalCx;
                    end {1}
                  else writeln ('can not optimize this stream');
                end; {optimizeSetInitializer}



              begin {factor_lbracket}
                haveComma := false;
                getsym; 

                {if expressionSet then write ('factor_lbracket, expressionSet, ')
                else write ('factor_lbracket, NOT expressionSet, ');
                writeln('factor_lbracket, expectedTyp ',expectedTyp:3);}

                if isSetType(expectedTyp) then begin {1}
                  {for code optimizations}
                  curCX := cx;
                  {we likely have a "set" but now we need to look at the elements}
                  setElementType := table[expectedTyp].typePtr;
                  {writeln('now looking for elementType of ',setElementType:3);}

                  {"OR" all the expressions here}
                  gen(lit,0,0); {start the value with NULL, or in elements}

                  {possible null set?}
                  if sym <> rbracket then 
                    begin {2}

                      repeat
      
                        returnedTyp := expression([rbracket,dotdot,comma]+fsys,noType,setParsing);

                        {writeln ('factor_pbracket start, expectedTyp:',expectedTyp:3,
                          ' returnedTyp:',returnedTyp:3);}

                        {ensure it is a set type}
                        checkTypes(setElementType,returnedTyp,'set before dotdot check');
    
                        if sym = dotdot then begin {3}
                          getsym;
                          returnedTyp := expression([rbracket,dotdot,comma]+fsys,noType,setParsing);

                          {"OR" it in with the (lit,0,0) above}
                          gen (opr,0,opr_dotdot_set16);

                          checkTypes(setElementType,returnedTyp,'set within dotdot');
                          {writeln ('factor_pbracket after dotdot , returnedTyp:',returnedTyp:3);}

                        end else begin {3}
                          {just not a dotdot, only 1 on stack to or in}
                          {"OR" it in with the (lit,0,0) above}
                          gen (opr,0,opr_or_set16);
                        end; {3}
      

                        haveComma := sym = comma;
                        if haveComma then  getsym
                      until haveComma = false;

                      {optimize this possible bit/or chain}
                      {if it can't because of say, a fn call, it
                       will not bother optimizing}
                      optimizeSetInitializer(curCX);

                    end {2}

                end else begin {1}
                  error (setTypeExpected);
                end; {1}

                if sym = rbracket then getsym else error(rbracketExpected)
              end; {factor_lbracket}


            {------------------------------}
            {handle: peek ord chr pred succ}
            procedure factor_peek_etc;
              var myFactorReturnType:integer;
              var myExpressionReturnType:integer;

              {process the stuff between the brackets, 
               e.g. xx := ord(THIS); }

              {parse the stuff in parens}
              function f_pocps_param:integer;
                var 
                  myExpectedType:integer;
                  myReturnedType:integer;
                begin {f_pocps_param}
                  {this is for the parameter to the (eg) peek command}
                  {what type in the brackets}
                  {lets see what expression returns...}

                  myExpectedType := noType;
                  myReturnedType := expression([rparen]+fsys,myExpectedType,expressionSet);
                  {writeln('f_pocps returns ',myReturnedType);}

                  {the returned type had better be a real type, if not there
                   is an error. 

                   We should also make sure it is not something stupid like
                   an array, or something large like that. But, as we don't
                   currently support arrays, lets just let it slide}

                  if myReturnedType = noType then begin
                    writeln('complex error in factor for built-in function');
                    error(typeNotSupported);
                  end;

                  {return the type, for further processing, if required}
                  f_pocps_param := myReturnedType;

                end; {f_pocps_param}


              begin {factor_peek_etc} {1}
                {save this so that we know which}
                {writeln('... peek-etc my exptc: ',expectedTyp:0);}
                myFactorReturnType := expectedTyp;
                mysym := sym;
                getsym;
                if sym = lparen then begin {2}
                  { STEP 1: PARSE WHAT IS IN THE PARENS}
                  getsym;
                  myExpressionReturnType := f_pocps_param;
                  {writeln('f_pocks returns:',myExpressionReturnType);}

                  { STEP 2: NOW, WHAT SHOULD THE FACTOR RETURN?}
                  {some, like peek and chr return specifics}
                  case mysym of
                    peeksym: returnedTyp := charType;
                    ordsym:  returnedTyp := uint16Type;
                    chrsym:  returnedTyp := charType;
                    predsym: returnedTyp := noType;
                    succsym: returnedTyp := noType;
                  end; 

                  {OK! maybe we get:
                   myFactorReturnType: type wd=(mon, tue, wed);
                   returnedTyp:noType 
                   mtExprRetTyp:char}
                  {check the types - we have some type changes here}

                  if returnedTyp = noType then begin
                    if myFactorReturnType <> myExpressionReturnType then
                      {hmmm - if the case above says "noType", it means that
                       types MUST match...}
                      checkTypes(myFactorReturnType,
                        myExpressionReturnType,'factor peek, ord, etc')
                  end;
                  

                  {do the operation, if anything required}
                  case mysym of
                    peeksym: gen(opr,0,opr_peek);
                    ordsym:  {do nothing};
                    chrsym:  {do nothing};
                    predsym: begin
                               gen(lit,0,1); {pred: change by 1}
                               gen(opr,0,opr_minus_uint16); {subtract}
                             end;
                    succsym: begin
                               gen(lit,0,1); {succ: change by 1}
                               gen(opr,0,opr_plus_uint16); {add}
                             end;
                  end; {case}

                  if sym = rparen then getsym
                  else error (rparenExpected)
                end {2}
              else error (lparenExpected);
            end; {1}

(************************************************************)
            begin {factor}
              expectedTyp := typ;
              returnedTyp := typ;

              {write('BEGIN factor, expectedType:',typ:0, ' sym:'); printSym(sym);}

              test(facbegsys, fsys, facbegerr);
               
              {variables, functions}
              if sym = ident then factor_ident

              {unsigned constants}
              else if sym in [number] then factor_constants

              {character strings}
              else if sym = charString then factor_charString

              {left parenthesis}
              else if sym = lparen then factor_lparen

              {peek ord chr pred succ}
              else if sym in [peeksym,ordsym,chrsym,predsym,succsym] then 
                factor_peek_etc

              {NOT}
              else if sym = notsym then begin
                getsym;
                returnedTyp := factor(fsys,typ);
                gen(opr,0,opr_not_uint16);
                end

              {set constructor}
              else if sym=lbracket then begin
                factor_lbracket
              end;



              {ok. If we are in a conditional, say something like
               x <> y, we will have typ as booleanType, (the <>)
               and we'll later on do a check. We might have further
               boolean operations, so we'll just assume that this
               is ok, and will get sussed out later}
              if typ <> booleanType then
                checkTypes(expectedTyp,returnedTyp,'factor main');
   
              {write('END factor, expectedType:',typ:0, ' sym:'); printSym(sym);
              writeln('END factor, returning: ',returnedTyp); writeln;}

             factor := returnedTyp;
           end {factor};

(************************************************************)
         begin {term} 
           
           {write('BEGIN term, sym:'); printSym(sym);}
           {is this a boolean condition, or an assignment?}
           termRTypRHS := typ;
           {writeln ('term, typ:',typ);}

           termRTypLHS := factor(fsys+termbegsys,typ);
           {writeln('term, after lhs factor call; ',termRTypLHS);}

           {term can loop through these operators}
           while sym in termbegsys do begin {while}

             {writeln('term, termRTypRHS:',termRTypRHS:3);}
    
             termop:=sym;
             getsym;

             {lets do an operation type check here}
             if expressionSet then begin
               {write ('expressionSet in term, have:');printSym(termop);}
               if not (termop in [times]) then begin
                 writeln('issue expressionSet in term, typ:',typ:3);
                 error (invOpForType);
               end;
             end else begin
             end;
             termRTypRHS := factor(fsys+termbegsys,expectedTyp);

             {writeln('term, termRTypRHS:',termRTypRHS:3);}
    

             {data type check}
             checkTypes(termRTypLHS,termRTypRHS,'term identifier');
    
             {ok, we know the term types match;
              do term operation }
             if termop = andsym then
               if termRTypLHS <> booleanType then begin
                 writeln('invOpForType at 2');
                 error (invOpForType);
               end
             else
               if termRTypLHS <> termRTypRHS then begin
                 write('term, symbol in question:');
                   printSym(termop);
                 writeln('; invOpForType at 3 termop:');
                 error (invOpForType);
               end;

             if expressionSet then begin
               if termop=times then gen(opr,0,opr_and_set16) {equiv to opr_intersection_set}
               else writeln ('term, expressionSet, should not be here');
             end else begin
               if termop=times then gen(opr,0,opr_mul_uint16) 
               else if termop = slash then gen(opr,0,opr_div_uint16)
               else if termop = divsym then gen(opr,0,opr_div_uint16)
               else if termop = modsym then gen(opr,0,opr_mod_uint16)
               else if termop = andsym then gen(opr,0,opr_and_uint16)
             end;
            
           end; {while}

           term := termRTypLHS;
           {writeln('term, returning:',termRTypLHS:2);}
           {write('END term, sym:'); printSym(sym);}
         end {term};

(************************************************************)
      begin {simpleExpression}

       { write('BEGIN simpleExpression, sym:'); printSym(sym);}
        {Writeln('note: simpleExpression, start typ:',typ:3);}

        returnedTyp := noType;
        expectedTyp := typ;


        {check that the type is able to use simpleExpression
         operators}
        addop := sym;

        {are we in the middle of figuring out the type of RHS?}

        {initial plus or minus - I know, uint16s can't be negative...}
        if (sym = plus) or (sym = minus) then begin
          if expressionSet then begin
            writeln('expressionSet and leading plus or minus');
            error (invOpForType);
          end;

          {gosh - maybe this is the first thing on rhs of := 
           so maybe it's noType? if so, assume number}
          if typ = noType then typ := uint16type;

          if typ <> uint16type then begin
            writeln('invOpForType at 4');
            error (invOpForType);
          end;

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
        if addop = minus then gen(opr, 0,opr_neg_uint16);

        {writeln('note: simpleExpression, after +- typ:',typ:3,' returnedTyp:',returnedTyp:3);}

        expectedTyp := returnedTyp;

         while sym in simpexsys do
            begin 
              addop := sym; 
              getsym; 
              returnedTyp := term(fsys+simpexsys,typ);

              {check to see if this term type matches}

              {writeln('simpleExpression, while, t1:',
                typ:3, ' returnedTyp:',returnedTyp:3);}

              {if we had a known type, and this var doesnt match...}
              checkTypes(typ, returnedTyp,'simpleExpression');

              {type checking for the simpleExpression
               operators}
              if addop in [plus,minus] then begin {+-}

                if expressionSet then begin {is a set}
                  {a set, so we CAN do this}
                  if addop = plus then 
                    gen(opr,0,opr_or_set16)
                  else begin
                    gen(opr,0,opr_invert_set16);
                    gen(opr,0,opr_and_set16);
                  end
                end else begin {is NOT a set}
                  {NOT a set, so normal add/subtract}
                  if returnedTyp <> uint16Type then begin
                    writeln('invOpForType simpleExpression 1');
                    error(invOpForType);
                  end;
  
                  if addop=plus then
                     gen(opr,0,opr_plus_uint16)
                  else gen (opr,0,opr_minus_uint16)
                end {if addop in +-}
              end 

              else if addop = orsym then begin
                if returnedTyp <> booleanType then begin
                  writeln('invOpForType simpleExpression 2');
                  error(invOpForType);
                end;
                gen(opr,0,opr_or_uint16);
              end;
        
            end {while};
         simpleExpression := returnedTyp;
        {write('END simpleExpression, sym:'); printSym(sym);}
      end {simpleExpression};

(************************************************************)
      begin {expression}
         {var expRTypLHS, expRTypRHS : integer;}
         {writeln('expression start, typ:',typ:3);}

         {are we in a set or numeric type?}
         {if expressionSet then writeln('start expression, expressionSet') else writeln('expression, normal');}

         if (typ>0) and (typ<txmax) then
           if table[typ].kind = set_def then begin {1}
             expressionSet := true;
             {writeln ('expression, NOW SET TO PARSE SETS!');}
           end; {1}


         {is this a boolean condition, or an assignment?}
         expRTypRHS := noType;

         expRTypLHS := simpleExpression(fsys+exprbegsys,typ);

         {writeln('expression before symcheck expRTypLHS:',expRTypLHS:3);}

         { is this possibly a boolean?}
         {NOTE that we skim out invalid syms with the if test
          at the start of this procedure}

         if (sym in exprbegsys) then begin {1}
         {writeln('after if have sym in exprbegsys, LHS:',expRTypLHS:3,' RHS:',expRTypRHS:3);}
          relop := sym; 
           getsym; 
           expRTypRHS := simpleExpression(fsys,noType);
    
           {write('expression, expRTypLHS:',expRTypLHS:3);
           writeln(', expRTypRHS:',expRTypRHS:3);}
           if (expRTypRHS>0) and (expRTypRHS<txmax) then
             if table[expRTypRHS].kind = set_def then begin {2}
               expressionSet := true;
               {now, was the LHS an element or a set?}
               if table[expRTypLHS].kind <>
                   table[expRTypRHS].kind then begin {3}
                 {promote TOS to set type}
                 gen(opr, 0,opr_flip_tos16);
                 gen(opr, 0,opr_int_toSet16);
               end; {3}
             end; {2}
    
           {data type check}
           checkTypes(expRTypLHS,expRTypRHS,'expression');

           {expression sets have "in" but no ">" or "<"}
           if expressionSet then begin {2}
             {set expression}
             case relop of
               insym: gen (opr, 0, opr_and_set16);
               eql:   gen (opr, 0, opr_eql_set16);
               neq:   gen (opr, 0, opr_neq_set16);
               leq:   gen (opr, 0, opr_incl_set16);
               geq:   begin
                        {like leq, just flip params}
                        gen (opr, 0, opr_flip_tos16);
                        gen (opr, 0, opr_incl_set16);
                      end;
               else begin {3}
                 write('expression, for sets, we found'); printSym(relop);
                 error (invOpForType);
               end; {3}
             end; {case}
             { for return value from this expression HERE}
             expRTypLHS := booleanType;
           end else begin {2}

             {16 bit expression}
             case relop of
               eql: gen(opr, 0, opr_eql_uint16);
               neq: gen(opr, 0, opr_neq_uint16);
               lss: gen(opr, 0, opr_lss_uint16);
               geq: gen(opr, 0, opr_geq_uint16);
               gtr: gen(opr, 0, opr_gtr_uint16);
               leq: gen(opr, 0, opr_leq_uint16);
               else begin {3}
                 write('expression, after the skimming'); printSym(relop);
                 error (invOpForType);
               end; {3}
             end; {case}
             { for return value from this expression HERE}
             expRTypLHS := booleanType;
           end; {2}
         end; {1}

         {writeln('expression, returining:',expRTypLHS:2);}

        expression := expRTypLHS;
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
                      expression([rparen,comma]+fsys,expectedTyp,normalParsing);

                    checkTypes(expectedTyp,returnedTyp,'proc parameters');
      
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
      
                if sym=rparen then getsym else error(rparenExpected);
      
              end;
              gen(pcal, lev-level, adr);
            end
      end;


(************************************************************)
    procedure stmtIdent();
     begin {1}

       i := position(id);
       if i = 0 then error(idNotFound) else
         with table[i] do
           begin {2}
             if kind=proc_def then 
               parseProcParams(i)
             else if kind=func_def then
               begin {3}
                 {this is a function, but the shadow variable is 1 above
                  the table index. Increment i so we are pointing at this 
                  shadow variable for variable assignment}
                 with table[i+1] do
                   begin {4}
                     {writeln('stmtIdent, func store; genning sto with table entry ',i+1);}
                     getsym; 
                     if sym = becomes then getsym else error(becomesExpected);
                     returnedTyp := expression(fsys,typePtr,normalParsing);
                     gen(sto, lev-level, adr)
                   end; {4}
               end {3}
             else if kind=var_def then
               begin {3}
                 getsym; 
                 if sym = becomes then getsym else error(becomesExpected);
                 returnedTyp := expression(fsys,typePtr,normalParsing);
                 
                 {type match check}
                 {writeln ('stmtIdent, my table[',i:0,'] type:',table[i].typePtr:3, 
                   ' returnedTyp:',returnedTyp:3);}

                 checkTypes(table[i].typePtr,returnedTyp,'statement identifier');

                 gen(sto, lev-level, adr)
               end {3}
             else if kind =set_def then
               begin {3}
                 writeln('set def in stmtIdent');
               end; {3}
           end; {2}
     end {1} {stmtIdent};

(************************************************************)
    procedure stmtIf(typ:integer);
      var cx1, cx2: integer;
        begin 
         getsym; 
         returnedTyp := expression([thensym, dosym]+fsys,typ,normalParsing);
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
             gen(jmp, 0, 0); {cx2 points to his jmp for fixup}
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
              returnedTyp := expression([]+fsys,typ,normalParsing);
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
                  returnedLHS := expression([tosym,downtosym]+fsys,typ,normalParsing);

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
                  returnedTyp := expression([dosym]+fsys,typ,normalParsing);

                  {Write('note: stmtFor, second returnedTyp: ');
                  printvtype(returnedTyp);writeln();}

                  {type checking}
                  checkTypes(returnedLHS,returnedTyp,'for loop');

                  if todowntosym = tosym then
                    gen(opr,0,opr_leq_uint16) {tops>=tops+1}
                  else
                    gen(opr,0,opr_geq_uint16); {tops<=tops+1}

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
                  gen(lit,0,1); {for increment/decrement count}
                  if todowntosym = tosym then
                    gen(opr,0,opr_plus_uint16) {add}
                  else
                    gen(opr,0,opr_minus_uint16); {subtract}
                  with table[i] do gen(sto, lev-level, adr);

                  {back up to top}
                  gen(jmp,0,cx1);
                end {to downto}
                 
              end; {becomes}
             
              {fixup the jpc}
              code[cx2].ax := cx

            end 
          else
            error(identifierExpected);
      end {stmtFor};

(************************************************************)
      procedure stmtRead(typ:integer);
        var readReadln : integer;
        var readDest: integer;

        begin {stmtRead}

	if sym = readsym then readReadln:=IO_Read; {flag here }
	if sym = readlnsym then readReadln:=IO_Readln;
        getsym; 
        if sym=lparen then begin
          getsym;
          repeat

            {this is a bug, can start wit a comma, fixit}
            if sym=comma then getsym;
              if sym = ident then begin
                readDest := position(id);
                {writeln ('read, have ident:',readDest);
                writeln ('read, assuming char read for now');}
                gen (tin,IO_char,0);
                with table[readDest] do gen(sto, lev-level, adr);
                getsym;
              end;
          until sym <> comma;
  
          if sym=rparen then begin
            getsym;
            {readln?? vs read}
            if readReadln=IO_Readln then begin
              {CR LF at start of string area}
              gen(tot,IO_charString,0);
            end;
              
          end else error(rparenExpected);
        end else begin
          {read or readln without the parentheses; maybe just a plain CR wanted}
  
          if readReadln=IO_Readln then
            {CR LF at start of string area}
            {gen(tot,IO_charString,0);}
        end {if sym = lparen}
      end; {stmtRead}

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
            returnedTyp := expression([rparen,comma]+fsys,typ,normalParsing);

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
            
          end else error(rparenExpected);
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
         returnedTyp := expression([dosym]+fsys,typ,normalParsing);
         cx2 := cx; 
         gen(jpc, 0, 0); {cx2 points to this jpc for fixup}
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
             returnedTyp := expression(fsys+[comma],typ,normalParsing);
             if sym = comma then
               begin
                 getsym;
                 {writeln ('poke, 2nd param, forcing to charType');}
                 myvt := expression(fsys+[rparen],charType,normalParsing);
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

   (**********************************)
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
      
   (**********************************)
   begin {statement}
     {writeln('begin Statement, sym is '); printSym(sym);}
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
        readsym,
        readlnsym : stmtRead(noType);

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
        id:=rvForMe;
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
                  end;
         set_def: begin
           writeln('set_def found at this spot');
                  end;
         end;

    {restore tx to where it was before parsing these parameters}
    tx := txOfParamFunc;

    {writeln(' end parameterlist, tx:',tx:1,' txOfParamFunc:',txOfParamFunc:1);
    writeln(' end paramterList, have #params:', tx -txOfParamFunc);}
  end {parameterList};

  (************************************************************)
  procedure beginStmtEnd();
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

   {writeln(tx,' (at beginning of block)'); }
   {printTable;}


   if lev > levmax then error(procedureLevel);

   repeat
     {write('beginning of repeat in block, lev ',lev:2, ' sym ');printSym(sym);}
      {TYPES}
      if sym = typesym then
      begin getsym;
         repeat blockTypeDeclaration;
            while sym = comma do
               begin getsym; blockTypeDeclaration
               end;
            if sym = semicolon then getsym else error(semicolonExpected);

            {if we have another type keyword, we are still parsing types}
            if sym = typesym then getsym;
         until sym <> ident
      end;


      {CONSTANTS}
      if sym = constsym then
      begin getsym;
         repeat blockConstDeclaration;
            while sym = comma do
               begin getsym; blockConstDeclaration
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
   {ok, finished the block declarations, go and
    do the last statement}


   {writeln('tidyup lev:',lev:1,' tx0:',tx0:0,' cx',cx:2);}
   if mainBody>=0 then begin
     {writeln ('mainbody at:',mainBody:2,' should jump to:',cx:3);}
     with code[mainbody] do
       ax := cx;
     end
   else 
     code[table[tx0].adr].ax := cx;

   {uncomment this if you want to see the definitions table}
   {printTable('before beginsym in BLOCK');}

   {almost finished! must do a}
   {begin statement[;statement] end}

   gen(int, 0, dx);

   (****************************)
   {Pascal - Block MUST HAVE a begin-statement-end at the end}
   if sym = beginsym then begin
     getsym;
     statement([semicolon, endsym]+fsys);
      while sym in [semicolon]+statbegsys do
        begin
          if sym <> semicolon then error(semicolonExpected);
          getsym;
          statement([semicolon, endsym]+fsys)
        end;
      if sym = endsym then getsym else error(endExpected)
   end else error (beginExpected);


   (****************************)
   (* either a return or end of program, which is it? *)
   if lev > 0 then
     begin
       if parentType = func_def then
         gen(fret, 1, 0) {return}
       else
         gen(pret, 0, 0) {return}
     end
   else 
     begin
       gen (xit, 0, 0); {exit program}
        {uncomment this "listcode" if you want to see
        the pcode generated.}
        {listcode;}
     end;

   test(fsys, [], blockEnd);

   {write('end of block, sym:');printSym(sym);}
end {block};


(********************************************************)

procedure interpret;
   const stacksize = 5000;
   var inchar:char; {input character}
   var progPtr,
       dynamicLink, 
       tops: integer; {program-, DynamicLink-, topstack-registers}

      i: instruction; {instruction register}
      s: array [1..stacksize] of integer; {datastore}
      rv: integer;
      tmp: integer;
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

  procedure boundsCheckUint16();
    begin
      {is TOS out of range for a uint16?}
      if (s[tops]<0) or (s[tops]>65535) then begin
        writeln ('uint16 issue, at cx:',progPtr:0,
          ' value out of range, is:',s[tops]:0);
        goto 99;
      end;
    end;
           

  {--------------------------------------------------}

begin writeln(' start TinyPascal');
   count := 1;
   tops := 0; dynamicLink := 1; progPtr := 0;
   s[1] := 0; s[2] := 0; s[3] := 0;

   repeat

      i := code[progPtr];

      progPtr := progPtr + 1;

      with i do
      case fn of
      lit: begin tops := tops + 1; s[tops] := ax
           end;

      fret: begin
                 {write ('returning a function value... dynamicLink:',dynamicLink:3);}
                 rv := s[dynamiclink+3];
                 {writeln (tops:5,' value:',rv:3);}
                 tops := dynamicLink - 1; 
                 progPtr := s[tops + 3]; 
                 dynamicLink := s[tops + 2];

                 tops := tops+1;
                 s[tops] := rv;
                 {writeln('ret 1, tos is:',tops:2);}
               end;
                 
      pret: begin
                 {normal procedure return}
                 tops := dynamicLink - 1; 
                 progPtr := s[tops + 3]; 
                 dynamicLink := s[tops + 2];
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
           opr_neg_uint16: s[tops] := -s[tops];
           opr_plus_uint16: begin {2, plus}
                 tops := tops - 1; s[tops] := s[tops] + s[tops + 1];
                 boundsCheckUint16();
              end;
           opr_minus_uint16: begin 
                 tops := tops - 1; 
                 s[tops] := s[tops] - s[tops + 1]; 
                 boundsCheckUint16();
              end;
           opr_mul_uint16: begin 
                 tops := tops - 1; 
                 s[tops] := s[tops] * s[tops + 1]; 
                 boundsCheckUint16();
              end;
           opr_div_uint16: begin 
                 tops := tops - 1; 
                 s[tops] := s[tops] div s[tops + 1]; 
                 boundsCheckUint16();
              end;
           (* not in Pascal 6: s[tops] := ord(odd(s[tops])); *)
           opr_mod_uint16: begin 
                      tops := tops -1;
                      s[tops] := s[tops] mod s[tops + 1];
                    end;
           opr_eql_uint16: begin 
                tops := tops -1;
                s[tops] := ord(s[tops] = s[tops + 1])
              end;
           opr_neq_uint16: begin tops := tops - 1; s[tops] := ord(s[tops] <> s[tops + 1])
              end;
           opr_lss_uint16: begin tops := tops - 1; s[tops] := ord(s[tops] < s[tops + 1])
              end;
           opr_geq_uint16: begin tops := tops - 1; s[tops] := ord(s[tops] >= s[tops + 1])
              end;
           opr_gtr_uint16: begin tops := tops - 1; 
              s[tops] := ord(s[tops] > s[tops + 1]);
              end;
           opr_leq_uint16: begin {13, leq}
                 tops := tops - 1; s[tops] := ord(s[tops] <= s[tops + 1])
              end;

           opr_and_uint16: begin {14, AND}
                 tops := tops - 1; 
                 if (s[tops]=1) and (s[tops+1]=1) then 
                   s[tops] := 1 else s[tops] := 0;
              end;

           opr_or_uint16: begin {15, OR}
                 tops := tops - 1; 
                 if (s[tops]=1) or (s[tops+1]=1) then 
                   s[tops] := 1 else s[tops] := 0;
              end;

           opr_not_uint16: begin {16, NOT}
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
                
           
           opr_or_set16: begin {19, 16 bit wide boolean or}
             tops := tops-1;
             s[tops] := wordWideOp(opr_or_set16,s[tops+1],s[tops]); 
             {writeln('opr_or_set16 returning:',s[tops]:6);}
           end;
           opr_and_set16: begin {20, 16 bit wide boolean and}
             tops := tops-1;
             s[tops] := wordWideOp(opr_and_set16,s[tops+1], s[tops]); 
           end;
           opr_dotdot_set16: begin {21, set with expression dotdot expression}

             {writeln('dotdot, stack: ',s[tops-2], s[tops-1], s[tops-0]);}
             tops := tops -2;
             {tmp2 := s[tops+2];} {final element in set}
             {tmp1 := s[tops+1];} {first element in set}
             {tmp3 := s[tops];  } {current set contents}
             {writeln('dotdot before while, s[tops]:',s[tops]:3,
               ' s[tops+1] ' ,s[tops+1]:3,' s[tops+2] ',s[tops+2]:3);}

             {because we don't know in compile time what the bounds are,
              we loop here and add each bit one at a time} 
             {writeln ('dotdot, t:',s[tops]:3, ' t+1:',s[tops+1]:3,' t+2:',s[tops+2]:3);}
             while (s[tops+1] > 0) and (s[tops+1] <= s[tops+2]) do begin
               s[tops] := wordWideOp(opr_or_set16, s[tops+1], s[tops]);
               s[tops+1] := s[tops+1] * 2; {go for next bit}
             end;
           end;

           opr_invert_set16: begin {24, set with inversion}
             {writeln('stack tops invert start:',s[tops]:3, ' t+1:',s[tops]);}
             {first, invert the TOS}
             s[tops] := wordWideOp(opr_invert_set16,s[tops],0);
             {writeln('stack tops invert is now: TOS:', s[tops]:3,' TOS-1:', s[tops-1]:3);}
           end;

           {if we have an enumeration IN set, promote the enum to a set bit}
           opr_int_toSet16: begin {25, promote enum @TOS to set}
             {write('promoting TOS:',s[tops]:0,' to set Element:');}
             s[tops] := setToBit16(s[tops]);
             {writeln(s[tops-1]:0);}
           end; 

           opr_eql_set16: begin { = 27; "=" operator}
             {same as opr_eql_uint16}
                tops := tops -1;
                s[tops] := ord(s[tops] = s[tops + 1]);
           end;
           opr_neq_set16: begin {    = 28; "<>" operator}
             {same as opr_neq_uint16}
              tops := tops - 1; 
              s[tops] := ord(s[tops] <> s[tops + 1]);
           end;
           opr_incl_set16: begin {  = 29; "<=" operator}
              tops := tops - 1; 
              tmp := s[tops];
writeln ('step 1: set inclusion, tmp(stops) ',tmp:3, ' s[tops+1]:',s[tops+1]:3);
              {AND the inclusion with the full;}
              s[tops] := wordWideOp(opr_and_set16,s[tops+1], s[tops]); 

writeln ('step 2: after AND, s[tops] ',s[tops]:3);
              {and see if the inclusion equals the AND result}
              s[tops] := ord(s[tops] = tmp);
writeln ('step 3: after equals comparison, s[tops] ',s[tops]:3);
           end;

           opr_flip_tos16: begin {   = 31; tos := tos-1, tos-1 := tos}
              {exchange TOS and TOS-1}
              tmp := s[tops];
              s[tops] := s[tops-1];
              s[tops-1] := tmp;
           end;

           end; {opr types}

      lod: begin tops := tops + 1; s[tops] := s[base(lv) + ax]
           end;

      sto: begin 
             s[base(lv)+ax] := s[tops]; 
             tops := tops - 1
           end;
      pcal,fcal: begin {generate new block mark}
              s[tops + 1] := base(lv); s[tops + 2] := dynamicLink; s[tops + 3] := progPtr;
              dynamicLink := tops + 1; progPtr := ax;
           end;
      int: begin
             tops := tops + ax;
           end;
      jmp: progPtr := ax;
      jpc: begin 
           if s[tops] = 0 then progPtr := ax; tops := tops - 1
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
               write(s[tops]:0); 
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
             {writeln('TXT IN - one char SVP:');}
             read(inchar);
             writeln('interpreter read in char: ',inchar);
             tops := tops + 1; s[tops] := ord(inchar);
           end;
      ver: begin
           writeln('version: ',ax);
           end;

      end {with, case};

      {want to show stack, etc?}
      {printstatus;}

      count := count+1;
   until progPtr = 0;
   writeln(' end TinyPascal');
end {interpret};


(********************************************************)

begin {main program}
  {parse command line arguments}
  parseCommandLine;


  {output character strings, eg, writeln text}
  constCharArray[0] := #$0D;
  constCharArray[1] := #$0A;
  constCharArray[2] := #$00;
  constCharIndex := 3;

  {function return value - an "invalid" ID}
  rvForMe := '-rvForMe- ';

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
  word[12] := 'file      '; wsym[12] := filesym;
  word[13] := 'for       '; wsym[13] := forsym;
  word[14] := 'function  '; wsym[14] := funcsym;
  word[15] := 'if        '; wsym[15] := ifsym;
  word[16] := 'in        '; wsym[16] := insym;
  word[17] := 'mod       '; wsym[17] := modsym;
  word[18] := 'not       '; wsym[18] := notsym;
  word[19] := 'of        '; wsym[19] := ofsym;
  word[20] := 'or        '; wsym[20] := orsym;
  word[21] := 'ord       '; wsym[21] := ordsym;
  word[22] := 'packed    '; wsym[22] := packedsym;
  word[23] := 'peek      '; wsym[23] := peeksym;
  word[24] := 'poke      '; wsym[24] := pokesym;
  word[25] := 'pred      '; wsym[25] := predsym;
  word[26] := 'procedure '; wsym[26] := procsym;
  word[27] := 'program   '; wsym[27] := programsym;
  word[28] := 'read      '; wsym[28] := readsym;
  word[29] := 'readln    '; wsym[29] := readlnsym;
  word[30] := 'record    '; wsym[30] := recordsym;
  word[31] := 'repeat    '; wsym[31] := repeatsym;
  word[32] := 'set       '; wsym[32] := setsym;

  word[33] := 'succ      '; wsym[33] := succsym;
  word[34] := 'then      '; wsym[34] := thensym;
  word[35] := 'to        '; wsym[35] := tosym;
  word[36] := 'type      '; wsym[36] := typesym;
  word[37] := 'until     '; wsym[37] := untilsym;
  word[38] := 'var       '; wsym[38] := varsym;
  word[39] := 'while     '; wsym[39] := whilesym;
  word[40] := 'write     '; wsym[40] := writesym;
  word[41] := 'writeln   '; wsym[41] := writelnsym;

  ssym[ '+'] := plus;       ssym[ '-'] := minus;
  ssym[ '*'] := times;      ssym[ '/'] := slash;
  ssym[ '('] := lparen;     ssym[ ')'] := rparen;
  ssym[ '['] := lbracket;   ssym[ ']'] := rbracket;
  ssym[ '='] := eql;        ssym[ ','] := comma;
  ssym[ '.'] := period;     ssym[ '^'] := pointer;
  ssym[ '<'] := lss;        ssym[ '>'] := gtr;
  ssym[ ';'] := semicolon;  ssym[ ':'] := colon; 
  ssym[ ''''] := quote;

  mnemonic[ver]  := '  ver'; mnemonic[lit]  := '  lit';   
  mnemonic[lod]  := '  lod'; mnemonic[sto]  := '  sto';
  mnemonic[opr]  := '  opr'; mnemonic[bbnd] := ' bbnd';
  mnemonic[stk]  := '  stk'; mnemonic[int]  := '  int';
  mnemonic[pcal] := ' pcal'; mnemonic[fcal] := ' fcal';
  mnemonic[pret] := ' pret'; mnemonic[fret] := ' fret';
  mnemonic[jmp]  := '  jmp'; mnemonic[jpc]  := '  jpc';
  mnemonic[tot]  := ' txot'; mnemonic[tin]  := ' txin';
  mnemonic[xit]  := '  xit';

  omnemonic[ver]  := '  OPVER'; omnemonic[lit]  := '  OPLIT';   
  omnemonic[lod]  := '  OPLOD'; omnemonic[sto]  := '  OPSTO';
  omnemonic[opr]  := '  OPOPR'; omnemonic[bbnd] := '  OPBND';
  omnemonic[stk]  := '  OPSTK'; omnemonic[int]  := '  OPINT';
  omnemonic[pcal] := ' OPPCAL'; omnemonic[fcal] := ' OPFCAL';
  omnemonic[pret] := ' OPPRET'; omnemonic[fret] := ' OPFRET';
  omnemonic[jmp]  := '  OPJMP'; omnemonic[jpc]  := '  OPJPC';
  omnemonic[tot]  := '  TXOUT'; omnemonic[tin]  := '  TXTIN';
  omnemonic[xit]  := '  OPXIT';

  declbegsys := [typesym, constsym, varsym, procsym, funcsym];
  statbegsys := [beginsym, ifsym, whilesym, repeatsym, forsym,pokesym];
  facbegsys  := [ident, number, charstring, peeksym, lparen, notsym,
                chrsym,ordsym,predsym,succsym,lbracket];
  termbegsys := [times,slash,divsym,modsym,andsym];
  simpexsys  := [plus, minus, orsym];
  exprbegsys := [eql, neq, lss, leq, gtr, geq, insym];
  typebegsys := [packedsym, arraysym, filesym, setsym, recordsym,pointer];


  page(output); errcount := 0;
  cc := 0; cx := 0; ll := 0; ch := ' '; kk := al; getsym;

  {program (xx,yy); is just parsed; not required (yet)}
  if sym = programsym then parseProgram;

  
  { insert version here}
  {write out the version here for the interpreter to check}
  {gen is ascii '0' * 256 + ascii '1' for version 01}
  {writeln('should be genning for version ',48*256+49);}

  {Version "06" Apr 8 2025}
  gen(ver,0,48*256+54);


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
