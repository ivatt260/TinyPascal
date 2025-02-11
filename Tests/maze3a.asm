; created from TinyPascal 1802 compiler

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Do we fit this into 0x0000 -> 0x7FFF or 0x8000 -> 0xFFFF?
; Lee Harts MemberCHIP card ROM is 0x0000, the SHIP card is at 0x8000
; Choose one of these to set the RAM block for us to go into
; MEMBERCHIP rom is at 0x0000, ram starts at 0x8000
; MEMBERSHIP rom is at 0x0000, ram starts at 0x0000

MEMBERSHIP EQU     0 ; 1 == memberSHIP card - must set MC20ANSA as well.
MEMBERCHIP EQU     1 ; 1 == memberCHIP card - must set MC20ANSA as well.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; 
; MC20ANSA - default EPROM for Lee Harts MemberCHIP card, but use for
; both MemberSHIP and MemberCHIP cards; tested with MCSMP20J.bin for
; MemberSHIP cards (Shows Ver. 2.0J on start) and MC20ANSA shows
; v2.0AR 14 Feb 2022. Other versions likely ok, but need to ensure serial
; function addresses are correct.

	IF MEMBERCHIP
; MemberCHIP card: ROM at 0000H
; MemberCHIP card: RAM at 8000H
ORGINIT    EQU     08000H
ROMISAT    EQU     0
STACKST	EQU	0FEFFH	; note: FFxx last lines used by MemberCHIP monitor
	ENDI ; memberCHIP card

	IF MEMBERSHIP
; MemberSHIP card: ROM at 8000H
; MemberSHIP card: RAM at 0000H
ORGINIT     EQU    0
ROMISAT     EQU     08000H
STACKST	EQU	07EFFH	; note: 7Fxx last lines used by MemberSHIP monitor
	ENDI ; memberSHIP card

OPLIT      EQU 000H
OPOPR      EQU 001H
OPLOD      EQU 002H
OPSTO      EQU 003H
OPCAL      EQU 004H
OPINT      EQU 005H
OPJMP      EQU 006H
OPJPC      EQU 007H
OPXIT      EQU 008H
OPRET      EQU 009H
TXOUT      EQU 00AH
TXTIN      EQU 00BH
OPSTK      EQU 00CH
OPVER      EQU 00DH

PASPROG    EQU ORGINIT + 0800H
          ORG  PASPROG


;      0  ver  012340
          DB     OPVER
          DB     0
          DW 12340

;      1  jmp  0  487
          DB     OPJMP
          DB     0
          DW     PASPROG + (487 SHL 2)

;      2  jmp  0    3
          DB     OPJMP
          DB     0
          DW     PASPROG + (3 SHL 2)

;      3  int  0    6
          DB     OPINT
          DB     0
          DW     (6 SHL 1)

;      4  lod  0    4
          DB     OPLOD
          DB     0
          DW     (4 SHL 1)

;      5  lit  0    1
          DB     OPLIT
          DB     0
          DW     1

;      6  opr  0   10
          DB     OPOPR
          DB     0
          DW    10

;      7  lod  0    4
          DB     OPLOD
          DB     0
          DW     (4 SHL 1)

;      8  lod  1    1
          DB     OPLOD
          DB     1
          DW     (1 SHL 1)

;      9  opr  0   12
          DB     OPOPR
          DB     0
          DW    12

;     10  opr  0   15
          DB     OPOPR
          DB     0
          DW    15

;     11  jpc  0   18
          DB     OPJPC
          DB     0
          DW     PASPROG + (18 SHL 2)

;     12  tot  1    3
          DB     TXOUT
          DB     1
          DW     CONSTCHARTXT+3

;     13  lod  0    4
          DB     OPLOD
          DB     0
          DW     (4 SHL 1)

;     14  tot  2    0
          DB     TXOUT
          DB     2
          DW     0 ; uint16, on stack

;     15  tot  1    0
          DB     TXOUT
          DB     1
          DW     CONSTCHARTXT+0

;     16  lit  0    1
          DB     OPLIT
          DB     0
          DW     1

;     17  sto  0    4
          DB     OPSTO
          DB     0
          DW     (4 SHL 1)

;     18  lod  0    5
          DB     OPLOD
          DB     0
          DW     (5 SHL 1)

;     19  lit  0    1
          DB     OPLIT
          DB     0
          DW     1

;     20  opr  0   10
          DB     OPOPR
          DB     0
          DW    10

;     21  lod  0    5
          DB     OPLOD
          DB     0
          DW     (5 SHL 1)

;     22  lod  1    0
          DB     OPLOD
          DB     1
          DW     (0 SHL 1)

;     23  opr  0   12
          DB     OPOPR
          DB     0
          DW    12

;     24  opr  0   15
          DB     OPOPR
          DB     0
          DW    15

;     25  jpc  0   32
          DB     OPJPC
          DB     0
          DW     PASPROG + (32 SHL 2)

;     26  tot  1   22
          DB     TXOUT
          DB     1
          DW     CONSTCHARTXT+22

;     27  lod  0    5
          DB     OPLOD
          DB     0
          DW     (5 SHL 1)

;     28  tot  2    0
          DB     TXOUT
          DB     2
          DW     0 ; uint16, on stack

;     29  tot  1    0
          DB     TXOUT
          DB     1
          DW     CONSTCHARTXT+0

;     30  lit  0    1
          DB     OPLIT
          DB     0
          DW     1

;     31  sto  0    5
          DB     OPSTO
          DB     0
          DW     (5 SHL 1)

;     32  lod  1   14
          DB     OPLOD
          DB     1
          DW     (14 SHL 1)

;     33  lod  0    5
          DB     OPLOD
          DB     0
          DW     (5 SHL 1)

;     34  opr  0    2
          DB     OPOPR
          DB     0
          DW     2

;     35  lod  0    4
          DB     OPLOD
          DB     0
          DW     (4 SHL 1)

;     36  lit  0    1
          DB     OPLIT
          DB     0
          DW     1

;     37  opr  0    3
          DB     OPOPR
          DB     0
          DW     3

;     38  lod  1    0
          DB     OPLOD
          DB     1
          DW     (0 SHL 1)

;     39  opr  0    4
          DB     OPOPR
          DB     0
          DW     4

;     40  opr  0    2
          DB     OPOPR
          DB     0
          DW     2

;     41  sto  0    3
          DB     OPSTO
          DB     0
          DW     (3 SHL 1)

;     42  ret  1    0
          DB     OPRET
          DB     1
          DW     0

;     43  jmp  0   44
          DB     OPJMP
          DB     0
          DW     PASPROG + (44 SHL 2)

;     44  int  0    9
          DB     OPINT
          DB     0
          DW     (9 SHL 1)

;     45  lod  0    3
          DB     OPLOD
          DB     0
          DW     (3 SHL 1)

;     46  sto  0    7
          DB     OPSTO
          DB     0
          DW     (7 SHL 1)

;     47  lod  0    4
          DB     OPLOD
          DB     0
          DW     (4 SHL 1)

;     48  sto  0    8
          DB     OPSTO
          DB     0
          DW     (8 SHL 1)

;     49  lod  0    8
          DB     OPLOD
          DB     0
          DW     (8 SHL 1)

;     50  lod  0    6
          DB     OPLOD
          DB     0
          DW     (6 SHL 1)

;     51  opr  0   13
          DB     OPOPR
          DB     0
          DW    13

;     52  jpc  0   65
          DB     OPJPC
          DB     0
          DW     PASPROG + (65 SHL 2)

;     53  stk  1    4
          DB     OPSTK
          DB     1
          DW     (4 SHL 1)

;     54  lod  0    7
          DB     OPLOD
          DB     0
          DW     (7 SHL 1)

;     55  lod  0    8
          DB     OPLOD
          DB     0
          DW     (8 SHL 1)

;     56  stk  0    6
          DB     OPSTK
          DB     0
          DW     (6 SHL 1)

;     57  cal  1    2
          DB     OPCAL
          DB     1
          DW     PASPROG + (2 SHL 2)

;     58  lod  1    3
          DB     OPLOD
          DB     1
          DW     (3 SHL 1)

;     59  opr  0   18
          DB     OPOPR
          DB     0
          DW    18

;     60  lod  0    8
          DB     OPLOD
          DB     0
          DW     (8 SHL 1)

;     61  lit  0    1
          DB     OPLIT
          DB     0
          DW     1

;     62  opr  0    2
          DB     OPOPR
          DB     0
          DW     2

;     63  sto  0    8
          DB     OPSTO
          DB     0
          DW     (8 SHL 1)

;     64  jmp  0   49
          DB     OPJMP
          DB     0
          DW     PASPROG + (49 SHL 2)

;     65  ret  0    0
          DB     OPRET
          DB     0
          DW     0

;     66  jmp  0   67
          DB     OPJMP
          DB     0
          DW     PASPROG + (67 SHL 2)

;     67  int  0    9
          DB     OPINT
          DB     0
          DW     (9 SHL 1)

;     68  lod  0    4
          DB     OPLOD
          DB     0
          DW     (4 SHL 1)

;     69  sto  0    8
          DB     OPSTO
          DB     0
          DW     (8 SHL 1)

;     70  lod  0    3
          DB     OPLOD
          DB     0
          DW     (3 SHL 1)

;     71  sto  0    7
          DB     OPSTO
          DB     0
          DW     (7 SHL 1)

;     72  lod  0    7
          DB     OPLOD
          DB     0
          DW     (7 SHL 1)

;     73  lod  0    5
          DB     OPLOD
          DB     0
          DW     (5 SHL 1)

;     74  opr  0   13
          DB     OPOPR
          DB     0
          DW    13

;     75  jpc  0   88
          DB     OPJPC
          DB     0
          DW     PASPROG + (88 SHL 2)

;     76  stk  1    4
          DB     OPSTK
          DB     1
          DW     (4 SHL 1)

;     77  lod  0    7
          DB     OPLOD
          DB     0
          DW     (7 SHL 1)

;     78  lod  0    8
          DB     OPLOD
          DB     0
          DW     (8 SHL 1)

;     79  stk  0    6
          DB     OPSTK
          DB     0
          DW     (6 SHL 1)

;     80  cal  1    2
          DB     OPCAL
          DB     1
          DW     PASPROG + (2 SHL 2)

;     81  lod  1    3
          DB     OPLOD
          DB     1
          DW     (3 SHL 1)

;     82  opr  0   18
          DB     OPOPR
          DB     0
          DW    18

;     83  lod  0    7
          DB     OPLOD
          DB     0
          DW     (7 SHL 1)

;     84  lit  0    1
          DB     OPLIT
          DB     0
          DW     1

;     85  opr  0    2
          DB     OPOPR
          DB     0
          DW     2

;     86  sto  0    7
          DB     OPSTO
          DB     0
          DW     (7 SHL 1)

;     87  jmp  0   72
          DB     OPJMP
          DB     0
          DW     PASPROG + (72 SHL 2)

;     88  ret  0    0
          DB     OPRET
          DB     0
          DW     0

;     89  jmp  0   90
          DB     OPJMP
          DB     0
          DW     PASPROG + (90 SHL 2)

;     90  int  0    5
          DB     OPINT
          DB     0
          DW     (5 SHL 1)

;     91  lit  0   11
          DB     OPLIT
          DB     0
          DW    11

;     92  sto  1    1
          DB     OPSTO
          DB     1
          DW     (1 SHL 1)

;     93  lit  0   11
          DB     OPLIT
          DB     0
          DW    11

;     94  sto  1    0
          DB     OPSTO
          DB     1
          DW     (0 SHL 1)

;     95  tot  1   41
          DB     TXOUT
          DB     1
          DW     CONSTCHARTXT+41

;     96  lod  1   13
          DB     OPLOD
          DB     1
          DW     (13 SHL 1)

;     97  tot  2    0
          DB     TXOUT
          DB     2
          DW     0 ; uint16, on stack

;     98  tot  1   55
          DB     TXOUT
          DB     1
          DW     CONSTCHARTXT+55

;     99  lod  1    1
          DB     OPLOD
          DB     1
          DW     (1 SHL 1)

;    100  lod  1    0
          DB     OPLOD
          DB     1
          DW     (0 SHL 1)

;    101  opr  0    4
          DB     OPOPR
          DB     0
          DW     4

;    102  tot  2    0
          DB     TXOUT
          DB     2
          DW     0 ; uint16, on stack

;    103  tot  1    0
          DB     TXOUT
          DB     1
          DW     CONSTCHARTXT+0

;    104  lod  1    1
          DB     OPLOD
          DB     1
          DW     (1 SHL 1)

;    105  lod  1    0
          DB     OPLOD
          DB     1
          DW     (0 SHL 1)

;    106  opr  0    4
          DB     OPOPR
          DB     0
          DW     4

;    107  lod  1   13
          DB     OPLOD
          DB     1
          DW     (13 SHL 1)

;    108  opr  0   12
          DB     OPOPR
          DB     0
          DW    12

;    109  jpc  0  113
          DB     OPJPC
          DB     0
          DW     PASPROG + (113 SHL 2)

;    110  tot  1   69
          DB     TXOUT
          DB     1
          DW     CONSTCHARTXT+69

;    111  tot  1    0
          DB     TXOUT
          DB     1
          DW     CONSTCHARTXT+0

;    112  jmp  0  115
          DB     OPJMP
          DB     0
          DW     PASPROG + (115 SHL 2)

;    113  tot  1   88
          DB     TXOUT
          DB     1
          DW     CONSTCHARTXT+88

;    114  tot  1    0
          DB     TXOUT
          DB     1
          DW     CONSTCHARTXT+0

;    115  lit  0    1
          DB     OPLIT
          DB     0
          DW     1

;    116  sto  0    3
          DB     OPSTO
          DB     0
          DW     (3 SHL 1)

;    117  lod  0    3
          DB     OPLOD
          DB     0
          DW     (3 SHL 1)

;    118  lod  1    1
          DB     OPLOD
          DB     1
          DW     (1 SHL 1)

;    119  opr  0   13
          DB     OPOPR
          DB     0
          DW    13

;    120  jpc  0  144
          DB     OPJPC
          DB     0
          DW     PASPROG + (144 SHL 2)

;    121  lit  0    1
          DB     OPLIT
          DB     0
          DW     1

;    122  sto  0    4
          DB     OPSTO
          DB     0
          DW     (4 SHL 1)

;    123  lod  0    4
          DB     OPLOD
          DB     0
          DW     (4 SHL 1)

;    124  lod  1    0
          DB     OPLOD
          DB     1
          DW     (0 SHL 1)

;    125  opr  0   13
          DB     OPOPR
          DB     0
          DW    13

;    126  jpc  0  139
          DB     OPJPC
          DB     0
          DW     PASPROG + (139 SHL 2)

;    127  stk  1    4
          DB     OPSTK
          DB     1
          DW     (4 SHL 1)

;    128  lod  0    3
          DB     OPLOD
          DB     0
          DW     (3 SHL 1)

;    129  lod  0    4
          DB     OPLOD
          DB     0
          DW     (4 SHL 1)

;    130  stk  0    6
          DB     OPSTK
          DB     0
          DW     (6 SHL 1)

;    131  cal  1    2
          DB     OPCAL
          DB     1
          DW     PASPROG + (2 SHL 2)

;    132  lod  1    2
          DB     OPLOD
          DB     1
          DW     (2 SHL 1)

;    133  opr  0   18
          DB     OPOPR
          DB     0
          DW    18

;    134  lod  0    4
          DB     OPLOD
          DB     0
          DW     (4 SHL 1)

;    135  lit  0    1
          DB     OPLIT
          DB     0
          DW     1

;    136  opr  0    2
          DB     OPOPR
          DB     0
          DW     2

;    137  sto  0    4
          DB     OPSTO
          DB     0
          DW     (4 SHL 1)

;    138  jmp  0  123
          DB     OPJMP
          DB     0
          DW     PASPROG + (123 SHL 2)

;    139  lod  0    3
          DB     OPLOD
          DB     0
          DW     (3 SHL 1)

;    140  lit  0    1
          DB     OPLIT
          DB     0
          DW     1

;    141  opr  0    2
          DB     OPOPR
          DB     0
          DW     2

;    142  sto  0    3
          DB     OPSTO
          DB     0
          DW     (3 SHL 1)

;    143  jmp  0  117
          DB     OPJMP
          DB     0
          DW     PASPROG + (117 SHL 2)

;    144  stk  1    3
          DB     OPSTK
          DB     1
          DW     (3 SHL 1)

;    145  lit  0    1
          DB     OPLIT
          DB     0
          DW     1

;    146  lit  0    1
          DB     OPLIT
          DB     0
          DW     1

;    147  lit  0    1
          DB     OPLIT
          DB     0
          DW     1

;    148  lit  0   11
          DB     OPLIT
          DB     0
          DW    11

;    149  stk  0    7
          DB     OPSTK
          DB     0
          DW     (7 SHL 1)

;    150  cal  1   43
          DB     OPCAL
          DB     1
          DW     PASPROG + (43 SHL 2)

;    151  stk  1    3
          DB     OPSTK
          DB     1
          DW     (3 SHL 1)

;    152  lit  0   11
          DB     OPLIT
          DB     0
          DW    11

;    153  lit  0    1
          DB     OPLIT
          DB     0
          DW     1

;    154  lit  0   11
          DB     OPLIT
          DB     0
          DW    11

;    155  lit  0   11
          DB     OPLIT
          DB     0
          DW    11

;    156  stk  0    7
          DB     OPSTK
          DB     0
          DW     (7 SHL 1)

;    157  cal  1   43
          DB     OPCAL
          DB     1
          DW     PASPROG + (43 SHL 2)

;    158  stk  1    3
          DB     OPSTK
          DB     1
          DW     (3 SHL 1)

;    159  lit  0    1
          DB     OPLIT
          DB     0
          DW     1

;    160  lit  0    1
          DB     OPLIT
          DB     0
          DW     1

;    161  lit  0   11
          DB     OPLIT
          DB     0
          DW    11

;    162  lit  0    1
          DB     OPLIT
          DB     0
          DW     1

;    163  stk  0    7
          DB     OPSTK
          DB     0
          DW     (7 SHL 1)

;    164  cal  1   66
          DB     OPCAL
          DB     1
          DW     PASPROG + (66 SHL 2)

;    165  stk  1    3
          DB     OPSTK
          DB     1
          DW     (3 SHL 1)

;    166  lit  0    1
          DB     OPLIT
          DB     0
          DW     1

;    167  lit  0   11
          DB     OPLIT
          DB     0
          DW    11

;    168  lit  0   11
          DB     OPLIT
          DB     0
          DW    11

;    169  lit  0   11
          DB     OPLIT
          DB     0
          DW    11

;    170  stk  0    7
          DB     OPSTK
          DB     0
          DW     (7 SHL 1)

;    171  cal  1   66
          DB     OPCAL
          DB     1
          DW     PASPROG + (66 SHL 2)

;    172  lit  0    1
          DB     OPLIT
          DB     0
          DW     1

;    173  sto  1    9
          DB     OPSTO
          DB     1
          DW     (9 SHL 1)

;    174  lit  0    6
          DB     OPLIT
          DB     0
          DW     6

;    175  sto  1   10
          DB     OPSTO
          DB     1
          DW     (10 SHL 1)

;    176  stk  1    4
          DB     OPSTK
          DB     1
          DW     (4 SHL 1)

;    177  lod  1    9
          DB     OPLOD
          DB     1
          DW     (9 SHL 1)

;    178  lod  1   10
          DB     OPLOD
          DB     1
          DW     (10 SHL 1)

;    179  stk  0    6
          DB     OPSTK
          DB     0
          DW     (6 SHL 1)

;    180  cal  1    2
          DB     OPCAL
          DB     1
          DW     PASPROG + (2 SHL 2)

;    181  sto  1    6
          DB     OPSTO
          DB     1
          DW     (6 SHL 1)

;    182  lod  1    6
          DB     OPLOD
          DB     1
          DW     (6 SHL 1)

;    183  lod  1    2
          DB     OPLOD
          DB     1
          DW     (2 SHL 1)

;    184  opr  0   18
          DB     OPOPR
          DB     0
          DW    18

;    185  lit  0   11
          DB     OPLIT
          DB     0
          DW    11

;    186  sto  1   11
          DB     OPSTO
          DB     1
          DW     (11 SHL 1)

;    187  lit  0    6
          DB     OPLIT
          DB     0
          DW     6

;    188  sto  1   12
          DB     OPSTO
          DB     1
          DW     (12 SHL 1)

;    189  stk  1    4
          DB     OPSTK
          DB     1
          DW     (4 SHL 1)

;    190  lod  1   11
          DB     OPLOD
          DB     1
          DW     (11 SHL 1)

;    191  lod  1   12
          DB     OPLOD
          DB     1
          DW     (12 SHL 1)

;    192  stk  0    6
          DB     OPSTK
          DB     0
          DW     (6 SHL 1)

;    193  cal  1    2
          DB     OPCAL
          DB     1
          DW     PASPROG + (2 SHL 2)

;    194  sto  1    7
          DB     OPSTO
          DB     1
          DW     (7 SHL 1)

;    195  lod  1    7
          DB     OPLOD
          DB     1
          DW     (7 SHL 1)

;    196  lod  1    2
          DB     OPLOD
          DB     1
          DW     (2 SHL 1)

;    197  opr  0   18
          DB     OPOPR
          DB     0
          DW    18

;    198  stk  1    3
          DB     OPSTK
          DB     1
          DW     (3 SHL 1)

;    199  lit  0    2
          DB     OPLIT
          DB     0
          DW     2

;    200  lit  0    9
          DB     OPLIT
          DB     0
          DW     9

;    201  lit  0    2
          DB     OPLIT
          DB     0
          DW     2

;    202  lit  0    9
          DB     OPLIT
          DB     0
          DW     9

;    203  stk  0    7
          DB     OPSTK
          DB     0
          DW     (7 SHL 1)

;    204  cal  1   43
          DB     OPCAL
          DB     1
          DW     PASPROG + (43 SHL 2)

;    205  stk  1    3
          DB     OPSTK
          DB     1
          DW     (3 SHL 1)

;    206  lit  0    3
          DB     OPLIT
          DB     0
          DW     3

;    207  lit  0    1
          DB     OPLIT
          DB     0
          DW     1

;    208  lit  0    3
          DB     OPLIT
          DB     0
          DW     3

;    209  lit  0    7
          DB     OPLIT
          DB     0
          DW     7

;    210  stk  0    7
          DB     OPSTK
          DB     0
          DW     (7 SHL 1)

;    211  cal  1   43
          DB     OPCAL
          DB     1
          DW     PASPROG + (43 SHL 2)

;    212  stk  1    3
          DB     OPSTK
          DB     1
          DW     (3 SHL 1)

;    213  lit  0    4
          DB     OPLIT
          DB     0
          DW     4

;    214  lit  0    7
          DB     OPLIT
          DB     0
          DW     7

;    215  lit  0    4
          DB     OPLIT
          DB     0
          DW     4

;    216  lit  0    9
          DB     OPLIT
          DB     0
          DW     9

;    217  stk  0    7
          DB     OPSTK
          DB     0
          DW     (7 SHL 1)

;    218  cal  1   43
          DB     OPCAL
          DB     1
          DW     PASPROG + (43 SHL 2)

;    219  stk  1    3
          DB     OPSTK
          DB     1
          DW     (3 SHL 1)

;    220  lit  0    5
          DB     OPLIT
          DB     0
          DW     5

;    221  lit  0    3
          DB     OPLIT
          DB     0
          DW     3

;    222  lit  0    5
          DB     OPLIT
          DB     0
          DW     5

;    223  lit  0    5
          DB     OPLIT
          DB     0
          DW     5

;    224  stk  0    7
          DB     OPSTK
          DB     0
          DW     (7 SHL 1)

;    225  cal  1   43
          DB     OPCAL
          DB     1
          DW     PASPROG + (43 SHL 2)

;    226  stk  1    3
          DB     OPSTK
          DB     1
          DW     (3 SHL 1)

;    227  lit  0    5
          DB     OPLIT
          DB     0
          DW     5

;    228  lit  0    7
          DB     OPLIT
          DB     0
          DW     7

;    229  lit  0    5
          DB     OPLIT
          DB     0
          DW     5

;    230  lit  0    9
          DB     OPLIT
          DB     0
          DW     9

;    231  stk  0    7
          DB     OPSTK
          DB     0
          DW     (7 SHL 1)

;    232  cal  1   43
          DB     OPCAL
          DB     1
          DW     PASPROG + (43 SHL 2)

;    233  stk  1    3
          DB     OPSTK
          DB     1
          DW     (3 SHL 1)

;    234  lit  0    6
          DB     OPLIT
          DB     0
          DW     6

;    235  lit  0    5
          DB     OPLIT
          DB     0
          DW     5

;    236  lit  0    6
          DB     OPLIT
          DB     0
          DW     6

;    237  lit  0    5
          DB     OPLIT
          DB     0
          DW     5

;    238  stk  0    7
          DB     OPSTK
          DB     0
          DW     (7 SHL 1)

;    239  cal  1   43
          DB     OPCAL
          DB     1
          DW     PASPROG + (43 SHL 2)

;    240  stk  1    3
          DB     OPSTK
          DB     1
          DW     (3 SHL 1)

;    241  lit  0    6
          DB     OPLIT
          DB     0
          DW     6

;    242  lit  0    9
          DB     OPLIT
          DB     0
          DW     9

;    243  lit  0    6
          DB     OPLIT
          DB     0
          DW     6

;    244  lit  0    9
          DB     OPLIT
          DB     0
          DW     9

;    245  stk  0    7
          DB     OPSTK
          DB     0
          DW     (7 SHL 1)

;    246  cal  1   43
          DB     OPCAL
          DB     1
          DW     PASPROG + (43 SHL 2)

;    247  stk  1    3
          DB     OPSTK
          DB     1
          DW     (3 SHL 1)

;    248  lit  0    7
          DB     OPLIT
          DB     0
          DW     7

;    249  lit  0    1
          DB     OPLIT
          DB     0
          DW     1

;    250  lit  0    7
          DB     OPLIT
          DB     0
          DW     7

;    251  lit  0    2
          DB     OPLIT
          DB     0
          DW     2

;    252  stk  0    7
          DB     OPSTK
          DB     0
          DW     (7 SHL 1)

;    253  cal  1   43
          DB     OPCAL
          DB     1
          DW     PASPROG + (43 SHL 2)

;    254  stk  1    3
          DB     OPSTK
          DB     1
          DW     (3 SHL 1)

;    255  lit  0    7
          DB     OPLIT
          DB     0
          DW     7

;    256  lit  0    5
          DB     OPLIT
          DB     0
          DW     5

;    257  lit  0    7
          DB     OPLIT
          DB     0
          DW     7

;    258  lit  0    7
          DB     OPLIT
          DB     0
          DW     7

;    259  stk  0    7
          DB     OPSTK
          DB     0
          DW     (7 SHL 1)

;    260  cal  1   43
          DB     OPCAL
          DB     1
          DW     PASPROG + (43 SHL 2)

;    261  stk  1    3
          DB     OPSTK
          DB     1
          DW     (3 SHL 1)

;    262  lit  0    7
          DB     OPLIT
          DB     0
          DW     7

;    263  lit  0    9
          DB     OPLIT
          DB     0
          DW     9

;    264  lit  0    7
          DB     OPLIT
          DB     0
          DW     7

;    265  lit  0    9
          DB     OPLIT
          DB     0
          DW     9

;    266  stk  0    7
          DB     OPSTK
          DB     0
          DW     (7 SHL 1)

;    267  cal  1   43
          DB     OPCAL
          DB     1
          DW     PASPROG + (43 SHL 2)

;    268  stk  1    3
          DB     OPSTK
          DB     1
          DW     (3 SHL 1)

;    269  lit  0    8
          DB     OPLIT
          DB     0
          DW     8

;    270  lit  0    5
          DB     OPLIT
          DB     0
          DW     5

;    271  lit  0    8
          DB     OPLIT
          DB     0
          DW     8

;    272  lit  0    5
          DB     OPLIT
          DB     0
          DW     5

;    273  stk  0    7
          DB     OPSTK
          DB     0
          DW     (7 SHL 1)

;    274  cal  1   43
          DB     OPCAL
          DB     1
          DW     PASPROG + (43 SHL 2)

;    275  stk  1    3
          DB     OPSTK
          DB     1
          DW     (3 SHL 1)

;    276  lit  0    8
          DB     OPLIT
          DB     0
          DW     8

;    277  lit  0    9
          DB     OPLIT
          DB     0
          DW     9

;    278  lit  0    8
          DB     OPLIT
          DB     0
          DW     8

;    279  lit  0    9
          DB     OPLIT
          DB     0
          DW     9

;    280  stk  0    7
          DB     OPSTK
          DB     0
          DW     (7 SHL 1)

;    281  cal  1   43
          DB     OPCAL
          DB     1
          DW     PASPROG + (43 SHL 2)

;    282  stk  1    3
          DB     OPSTK
          DB     1
          DW     (3 SHL 1)

;    283  lit  0    8
          DB     OPLIT
          DB     0
          DW     8

;    284  lit  0    9
          DB     OPLIT
          DB     0
          DW     9

;    285  lit  0    8
          DB     OPLIT
          DB     0
          DW     8

;    286  lit  0    9
          DB     OPLIT
          DB     0
          DW     9

;    287  stk  0    7
          DB     OPSTK
          DB     0
          DW     (7 SHL 1)

;    288  cal  1   43
          DB     OPCAL
          DB     1
          DW     PASPROG + (43 SHL 2)

;    289  stk  1    3
          DB     OPSTK
          DB     1
          DW     (3 SHL 1)

;    290  lit  0    9
          DB     OPLIT
          DB     0
          DW     9

;    291  lit  0    3
          DB     OPLIT
          DB     0
          DW     3

;    292  lit  0    9
          DB     OPLIT
          DB     0
          DW     9

;    293  lit  0    3
          DB     OPLIT
          DB     0
          DW     3

;    294  stk  0    7
          DB     OPSTK
          DB     0
          DW     (7 SHL 1)

;    295  cal  1   43
          DB     OPCAL
          DB     1
          DW     PASPROG + (43 SHL 2)

;    296  stk  1    3
          DB     OPSTK
          DB     1
          DW     (3 SHL 1)

;    297  lit  0    9
          DB     OPLIT
          DB     0
          DW     9

;    298  lit  0    5
          DB     OPLIT
          DB     0
          DW     5

;    299  lit  0    9
          DB     OPLIT
          DB     0
          DW     9

;    300  lit  0    7
          DB     OPLIT
          DB     0
          DW     7

;    301  stk  0    7
          DB     OPSTK
          DB     0
          DW     (7 SHL 1)

;    302  cal  1   43
          DB     OPCAL
          DB     1
          DW     PASPROG + (43 SHL 2)

;    303  stk  1    3
          DB     OPSTK
          DB     1
          DW     (3 SHL 1)

;    304  lit  0    9
          DB     OPLIT
          DB     0
          DW     9

;    305  lit  0    9
          DB     OPLIT
          DB     0
          DW     9

;    306  lit  0    9
          DB     OPLIT
          DB     0
          DW     9

;    307  lit  0    9
          DB     OPLIT
          DB     0
          DW     9

;    308  stk  0    7
          DB     OPSTK
          DB     0
          DW     (7 SHL 1)

;    309  cal  1   43
          DB     OPCAL
          DB     1
          DW     PASPROG + (43 SHL 2)

;    310  stk  1    3
          DB     OPSTK
          DB     1
          DW     (3 SHL 1)

;    311  lit  0   10
          DB     OPLIT
          DB     0
          DW    10

;    312  lit  0    3
          DB     OPLIT
          DB     0
          DW     3

;    313  lit  0   10
          DB     OPLIT
          DB     0
          DW    10

;    314  lit  0    3
          DB     OPLIT
          DB     0
          DW     3

;    315  stk  0    7
          DB     OPSTK
          DB     0
          DW     (7 SHL 1)

;    316  cal  1   43
          DB     OPCAL
          DB     1
          DW     PASPROG + (43 SHL 2)

;    317  stk  1    3
          DB     OPSTK
          DB     1
          DW     (3 SHL 1)

;    318  lit  0   10
          DB     OPLIT
          DB     0
          DW    10

;    319  lit  0    7
          DB     OPLIT
          DB     0
          DW     7

;    320  lit  0   10
          DB     OPLIT
          DB     0
          DW    10

;    321  lit  0    7
          DB     OPLIT
          DB     0
          DW     7

;    322  stk  0    7
          DB     OPSTK
          DB     0
          DW     (7 SHL 1)

;    323  cal  1   43
          DB     OPCAL
          DB     1
          DW     PASPROG + (43 SHL 2)

;    324  ret  0    0
          DB     OPRET
          DB     0
          DW     0

;    325  jmp  0  326
          DB     OPJMP
          DB     0
          DW     PASPROG + (326 SHL 2)

;    326  int  0    7
          DB     OPINT
          DB     0
          DW     (7 SHL 1)

;    327  lit  0    1
          DB     OPLIT
          DB     0
          DW     1

;    328  sto  0    3
          DB     OPSTO
          DB     0
          DW     (3 SHL 1)

;    329  lod  0    3
          DB     OPLOD
          DB     0
          DW     (3 SHL 1)

;    330  lod  1    1
          DB     OPLOD
          DB     1
          DW     (1 SHL 1)

;    331  opr  0   13
          DB     OPOPR
          DB     0
          DW    13

;    332  jpc  0  383
          DB     OPJPC
          DB     0
          DW     PASPROG + (383 SHL 2)

;    333  tot  1  111
          DB     TXOUT
          DB     1
          DW     CONSTCHARTXT+111

;    334  lod  0    3
          DB     OPLOD
          DB     0
          DW     (3 SHL 1)

;    335  tot  2    0
          DB     TXOUT
          DB     2
          DW     0 ; uint16, on stack

;    336  tot  1  116
          DB     TXOUT
          DB     1
          DW     CONSTCHARTXT+116

;    337  lit  0    1
          DB     OPLIT
          DB     0
          DW     1

;    338  sto  0    4
          DB     OPSTO
          DB     0
          DW     (4 SHL 1)

;    339  lod  0    4
          DB     OPLOD
          DB     0
          DW     (4 SHL 1)

;    340  lod  1    0
          DB     OPLOD
          DB     1
          DW     (0 SHL 1)

;    341  opr  0   13
          DB     OPOPR
          DB     0
          DW    13

;    342  jpc  0  377
          DB     OPJPC
          DB     0
          DW     PASPROG + (377 SHL 2)

;    343  stk  1    4
          DB     OPSTK
          DB     1
          DW     (4 SHL 1)

;    344  lod  0    3
          DB     OPLOD
          DB     0
          DW     (3 SHL 1)

;    345  lod  0    4
          DB     OPLOD
          DB     0
          DW     (4 SHL 1)

;    346  stk  0    6
          DB     OPSTK
          DB     0
          DW     (6 SHL 1)

;    347  cal  1    2
          DB     OPCAL
          DB     1
          DW     PASPROG + (2 SHL 2)

;    348  sto  0    5
          DB     OPSTO
          DB     0
          DW     (5 SHL 1)

;    349  lod  0    5
          DB     OPLOD
          DB     0
          DW     (5 SHL 1)

;    350  opr  0   17
          DB     OPOPR
          DB     0
          DW    17

;    351  sto  0    6
          DB     OPSTO
          DB     0
          DW     (6 SHL 1)

;    352  lod  0    6
          DB     OPLOD
          DB     0
          DW     (6 SHL 1)

;    353  lod  1    4
          DB     OPLOD
          DB     1
          DW     (4 SHL 1)

;    354  opr  0    8
          DB     OPOPR
          DB     0
          DW     8

;    355  jpc  0  358
          DB     OPJPC
          DB     0
          DW     PASPROG + (358 SHL 2)

;    356  lod  1    2
          DB     OPLOD
          DB     1
          DW     (2 SHL 1)

;    357  sto  0    6
          DB     OPSTO
          DB     0
          DW     (6 SHL 1)

;    358  lod  0    6
          DB     OPLOD
          DB     0
          DW     (6 SHL 1)

;    359  lit  0  127
          DB     OPLIT
          DB     0
          DW   127

;    360  opr  0   12
          DB     OPOPR
          DB     0
          DW    12

;    361  jpc  0  364
          DB     OPJPC
          DB     0
          DW     PASPROG + (364 SHL 2)

;    362  lit  0   88
          DB     OPLIT
          DB     0
          DW    88

;    363  sto  0    6
          DB     OPSTO
          DB     0
          DW     (6 SHL 1)

;    364  lod  0    6
          DB     OPLOD
          DB     0
          DW     (6 SHL 1)

;    365  lit  0   32
          DB     OPLIT
          DB     0
          DW    32

;    366  opr  0   10
          DB     OPOPR
          DB     0
          DW    10

;    367  jpc  0  370
          DB     OPJPC
          DB     0
          DW     PASPROG + (370 SHL 2)

;    368  lit  0  120
          DB     OPLIT
          DB     0
          DW   120

;    369  sto  0    6
          DB     OPSTO
          DB     0
          DW     (6 SHL 1)

;    370  lod  0    6
          DB     OPLOD
          DB     0
          DW     (6 SHL 1)

;    371  tot  3    0
          DB     TXOUT
          DB     3
          DW     0 ; uint16, on stack

;    372  lod  0    4
          DB     OPLOD
          DB     0
          DW     (4 SHL 1)

;    373  lit  0    1
          DB     OPLIT
          DB     0
          DW     1

;    374  opr  0    2
          DB     OPOPR
          DB     0
          DW     2

;    375  sto  0    4
          DB     OPSTO
          DB     0
          DW     (4 SHL 1)

;    376  jmp  0  339
          DB     OPJMP
          DB     0
          DW     PASPROG + (339 SHL 2)

;    377  tot  1    0
          DB     TXOUT
          DB     1
          DW     CONSTCHARTXT+0

;    378  lod  0    3
          DB     OPLOD
          DB     0
          DW     (3 SHL 1)

;    379  lit  0    1
          DB     OPLIT
          DB     0
          DW     1

;    380  opr  0    2
          DB     OPOPR
          DB     0
          DW     2

;    381  sto  0    3
          DB     OPSTO
          DB     0
          DW     (3 SHL 1)

;    382  jmp  0  329
          DB     OPJMP
          DB     0
          DW     PASPROG + (329 SHL 2)

;    383  ret  0    0
          DB     OPRET
          DB     0
          DW     0

;    384  jmp  0  385
          DB     OPJMP
          DB     0
          DW     PASPROG + (385 SHL 2)

;    385  int  0    8
          DB     OPINT
          DB     0
          DW     (8 SHL 1)

;    386  lit  0    0
          DB     OPLIT
          DB     0
          DW     0

;    387  sto  0    6
          DB     OPSTO
          DB     0
          DW     (6 SHL 1)

;    388  lod  0    4
          DB     OPLOD
          DB     0
          DW     (4 SHL 1)

;    389  lit  0    1
          DB     OPLIT
          DB     0
          DW     1

;    390  opr  0   11
          DB     OPOPR
          DB     0
          DW    11

;    391  lod  0    4
          DB     OPLOD
          DB     0
          DW     (4 SHL 1)

;    392  lod  1    1
          DB     OPLOD
          DB     1
          DW     (1 SHL 1)

;    393  opr  0   13
          DB     OPOPR
          DB     0
          DW    13

;    394  opr  0   14
          DB     OPOPR
          DB     0
          DW    14

;    395  lod  0    5
          DB     OPLOD
          DB     0
          DW     (5 SHL 1)

;    396  lit  0    1
          DB     OPLIT
          DB     0
          DW     1

;    397  opr  0   11
          DB     OPOPR
          DB     0
          DW    11

;    398  opr  0   14
          DB     OPOPR
          DB     0
          DW    14

;    399  lod  0    5
          DB     OPLOD
          DB     0
          DW     (5 SHL 1)

;    400  lod  1    0
          DB     OPLOD
          DB     1
          DW     (0 SHL 1)

;    401  opr  0   13
          DB     OPOPR
          DB     0
          DW    13

;    402  opr  0   14
          DB     OPOPR
          DB     0
          DW    14

;    403  jpc  0  484
          DB     OPJPC
          DB     0
          DW     PASPROG + (484 SHL 2)

;    404  stk  1    4
          DB     OPSTK
          DB     1
          DW     (4 SHL 1)

;    405  lod  0    4
          DB     OPLOD
          DB     0
          DW     (4 SHL 1)

;    406  lod  0    5
          DB     OPLOD
          DB     0
          DW     (5 SHL 1)

;    407  stk  0    6
          DB     OPSTK
          DB     0
          DW     (6 SHL 1)

;    408  cal  1    2
          DB     OPCAL
          DB     1
          DW     PASPROG + (2 SHL 2)

;    409  sto  0    7
          DB     OPSTO
          DB     0
          DW     (7 SHL 1)

;    410  lod  0    7
          DB     OPLOD
          DB     0
          DW     (7 SHL 1)

;    411  opr  0   17
          DB     OPOPR
          DB     0
          DW    17

;    412  lod  1    2
          DB     OPLOD
          DB     1
          DW     (2 SHL 1)

;    413  opr  0    8
          DB     OPOPR
          DB     0
          DW     8

;    414  jpc  0  484
          DB     OPJPC
          DB     0
          DW     PASPROG + (484 SHL 2)

;    415  lod  0    7
          DB     OPLOD
          DB     0
          DW     (7 SHL 1)

;    416  lod  1    4
          DB     OPLOD
          DB     1
          DW     (4 SHL 1)

;    417  opr  0   18
          DB     OPOPR
          DB     0
          DW    18

;    418  lod  0    4
          DB     OPLOD
          DB     0
          DW     (4 SHL 1)

;    419  lod  1   11
          DB     OPLOD
          DB     1
          DW     (11 SHL 1)

;    420  opr  0    8
          DB     OPOPR
          DB     0
          DW     8

;    421  lod  0    5
          DB     OPLOD
          DB     0
          DW     (5 SHL 1)

;    422  lod  1   12
          DB     OPLOD
          DB     1
          DW     (12 SHL 1)

;    423  opr  0    8
          DB     OPOPR
          DB     0
          DW     8

;    424  opr  0   14
          DB     OPOPR
          DB     0
          DW    14

;    425  jpc  0  429
          DB     OPJPC
          DB     0
          DW     PASPROG + (429 SHL 2)

;    426  lit  0    1
          DB     OPLIT
          DB     0
          DW     1

;    427  sto  0    6
          DB     OPSTO
          DB     0
          DW     (6 SHL 1)

;    428  jmp  0  477
          DB     OPJMP
          DB     0
          DW     PASPROG + (477 SHL 2)

;    429  lod  0    6
          DB     OPLOD
          DB     0
          DW     (6 SHL 1)

;    430  lit  0    0
          DB     OPLIT
          DB     0
          DW     0

;    431  opr  0    8
          DB     OPOPR
          DB     0
          DW     8

;    432  jpc  0  441
          DB     OPJPC
          DB     0
          DW     PASPROG + (441 SHL 2)

;    433  stk  1    4
          DB     OPSTK
          DB     1
          DW     (4 SHL 1)

;    434  lod  0    4
          DB     OPLOD
          DB     0
          DW     (4 SHL 1)

;    435  lit  0    1
          DB     OPLIT
          DB     0
          DW     1

;    436  opr  0    3
          DB     OPOPR
          DB     0
          DW     3

;    437  lod  0    5
          DB     OPLOD
          DB     0
          DW     (5 SHL 1)

;    438  stk  0    6
          DB     OPSTK
          DB     0
          DW     (6 SHL 1)

;    439  cal  1  384
          DB     OPCAL
          DB     1
          DW     PASPROG + (384 SHL 2)

;    440  sto  0    6
          DB     OPSTO
          DB     0
          DW     (6 SHL 1)

;    441  lod  0    6
          DB     OPLOD
          DB     0
          DW     (6 SHL 1)

;    442  lit  0    0
          DB     OPLIT
          DB     0
          DW     0

;    443  opr  0    8
          DB     OPOPR
          DB     0
          DW     8

;    444  jpc  0  453
          DB     OPJPC
          DB     0
          DW     PASPROG + (453 SHL 2)

;    445  stk  1    4
          DB     OPSTK
          DB     1
          DW     (4 SHL 1)

;    446  lod  0    4
          DB     OPLOD
          DB     0
          DW     (4 SHL 1)

;    447  lod  0    5
          DB     OPLOD
          DB     0
          DW     (5 SHL 1)

;    448  lit  0    1
          DB     OPLIT
          DB     0
          DW     1

;    449  opr  0    3
          DB     OPOPR
          DB     0
          DW     3

;    450  stk  0    6
          DB     OPSTK
          DB     0
          DW     (6 SHL 1)

;    451  cal  1  384
          DB     OPCAL
          DB     1
          DW     PASPROG + (384 SHL 2)

;    452  sto  0    6
          DB     OPSTO
          DB     0
          DW     (6 SHL 1)

;    453  lod  0    6
          DB     OPLOD
          DB     0
          DW     (6 SHL 1)

;    454  lit  0    0
          DB     OPLIT
          DB     0
          DW     0

;    455  opr  0    8
          DB     OPOPR
          DB     0
          DW     8

;    456  jpc  0  465
          DB     OPJPC
          DB     0
          DW     PASPROG + (465 SHL 2)

;    457  stk  1    4
          DB     OPSTK
          DB     1
          DW     (4 SHL 1)

;    458  lod  0    4
          DB     OPLOD
          DB     0
          DW     (4 SHL 1)

;    459  lit  0    1
          DB     OPLIT
          DB     0
          DW     1

;    460  opr  0    2
          DB     OPOPR
          DB     0
          DW     2

;    461  lod  0    5
          DB     OPLOD
          DB     0
          DW     (5 SHL 1)

;    462  stk  0    6
          DB     OPSTK
          DB     0
          DW     (6 SHL 1)

;    463  cal  1  384
          DB     OPCAL
          DB     1
          DW     PASPROG + (384 SHL 2)

;    464  sto  0    6
          DB     OPSTO
          DB     0
          DW     (6 SHL 1)

;    465  lod  0    6
          DB     OPLOD
          DB     0
          DW     (6 SHL 1)

;    466  lit  0    0
          DB     OPLIT
          DB     0
          DW     0

;    467  opr  0    8
          DB     OPOPR
          DB     0
          DW     8

;    468  jpc  0  477
          DB     OPJPC
          DB     0
          DW     PASPROG + (477 SHL 2)

;    469  stk  1    4
          DB     OPSTK
          DB     1
          DW     (4 SHL 1)

;    470  lod  0    4
          DB     OPLOD
          DB     0
          DW     (4 SHL 1)

;    471  lod  0    5
          DB     OPLOD
          DB     0
          DW     (5 SHL 1)

;    472  lit  0    1
          DB     OPLIT
          DB     0
          DW     1

;    473  opr  0    2
          DB     OPOPR
          DB     0
          DW     2

;    474  stk  0    6
          DB     OPSTK
          DB     0
          DW     (6 SHL 1)

;    475  cal  1  384
          DB     OPCAL
          DB     1
          DW     PASPROG + (384 SHL 2)

;    476  sto  0    6
          DB     OPSTO
          DB     0
          DW     (6 SHL 1)

;    477  lod  0    6
          DB     OPLOD
          DB     0
          DW     (6 SHL 1)

;    478  lit  0    1
          DB     OPLIT
          DB     0
          DW     1

;    479  opr  0    8
          DB     OPOPR
          DB     0
          DW     8

;    480  jpc  0  484
          DB     OPJPC
          DB     0
          DW     PASPROG + (484 SHL 2)

;    481  lod  0    7
          DB     OPLOD
          DB     0
          DW     (7 SHL 1)

;    482  lod  1    5
          DB     OPLOD
          DB     1
          DW     (5 SHL 1)

;    483  opr  0   18
          DB     OPOPR
          DB     0
          DW    18

;    484  lod  0    6
          DB     OPLOD
          DB     0
          DW     (6 SHL 1)

;    485  sto  0    3
          DB     OPSTO
          DB     0
          DW     (3 SHL 1)

;    486  ret  1    0
          DB     OPRET
          DB     1
          DW     0

;    487  int  0   15
          DB     OPINT
          DB     0
          DW     (15 SHL 1)

;    488  lit  0  800
          DB     OPLIT
          DB     0
          DW   800

;    489  sto  0   13
          DB     OPSTO
          DB     0
          DW     (13 SHL 1)

;    490  lit  0   32
          DB     OPLIT
          DB     0
          DW    32

;    491  sto  0    2
          DB     OPSTO
          DB     0
          DW     (2 SHL 1)

;    492  lit  0   35
          DB     OPLIT
          DB     0
          DW    35

;    493  sto  0    3
          DB     OPSTO
          DB     0
          DW     (3 SHL 1)

;    494  lit  0   46
          DB     OPLIT
          DB     0
          DW    46

;    495  sto  0    4
          DB     OPSTO
          DB     0
          DW     (4 SHL 1)

;    496  lit  0  111
          DB     OPLIT
          DB     0
          DW   111

;    497  sto  0    5
          DB     OPSTO
          DB     0
          DW     (5 SHL 1)

;    498  tot  1  130
          DB     TXOUT
          DB     1
          DW     CONSTCHARTXT+130

;    499  tot  1    0
          DB     TXOUT
          DB     1
          DW     CONSTCHARTXT+0

;    500  lit  040960
          DB     OPLIT
          DB     0
          DW 40960

;    501  lit  0  113
          DB     OPLIT
          DB     0
          DW   113

;    502  opr  0   18
          DB     OPOPR
          DB     0
          DW    18

;    503  lit  040960
          DB     OPLIT
          DB     0
          DW 40960

;    504  opr  0   17
          DB     OPOPR
          DB     0
          DW    17

;    505  lit  0  113
          DB     OPLIT
          DB     0
          DW   113

;    506  opr  0    8
          DB     OPOPR
          DB     0
          DW     8

;    507  jpc  0  511
          DB     OPJPC
          DB     0
          DW     PASPROG + (511 SHL 2)

;    508  lit  040960
          DB     OPLIT
          DB     0
          DW 40960

;    509  sto  0   14
          DB     OPSTO
          DB     0
          DW     (14 SHL 1)

;    510  jmp  0  524
          DB     OPJMP
          DB     0
          DW     PASPROG + (524 SHL 2)

;    511  lit  0 8192
          DB     OPLIT
          DB     0
          DW  8192

;    512  lit  0  113
          DB     OPLIT
          DB     0
          DW   113

;    513  opr  0   18
          DB     OPOPR
          DB     0
          DW    18

;    514  lit  0 8192
          DB     OPLIT
          DB     0
          DW  8192

;    515  opr  0   17
          DB     OPOPR
          DB     0
          DW    17

;    516  lit  0  113
          DB     OPLIT
          DB     0
          DW   113

;    517  opr  0    8
          DB     OPOPR
          DB     0
          DW     8

;    518  jpc  0  522
          DB     OPJPC
          DB     0
          DW     PASPROG + (522 SHL 2)

;    519  lit  0 8192
          DB     OPLIT
          DB     0
          DW  8192

;    520  sto  0   14
          DB     OPSTO
          DB     0
          DW     (14 SHL 1)

;    521  jmp  0  524
          DB     OPJMP
          DB     0
          DW     PASPROG + (524 SHL 2)

;    522  tot  1  166
          DB     TXOUT
          DB     1
          DW     CONSTCHARTXT+166

;    523  tot  1    0
          DB     TXOUT
          DB     1
          DW     CONSTCHARTXT+0

;    524  tot  1  199
          DB     TXOUT
          DB     1
          DW     CONSTCHARTXT+199

;    525  lod  0   14
          DB     OPLOD
          DB     0
          DW     (14 SHL 1)

;    526  tot  2    0
          DB     TXOUT
          DB     2
          DW     0 ; uint16, on stack

;    527  tot  1    0
          DB     TXOUT
          DB     1
          DW     CONSTCHARTXT+0

;    528  tot  1  213
          DB     TXOUT
          DB     1
          DW     CONSTCHARTXT+213

;    529  tot  1    0
          DB     TXOUT
          DB     1
          DW     CONSTCHARTXT+0

;    530  cal  0   89
          DB     OPCAL
          DB     0
          DW     PASPROG + (89 SHL 2)

;    531  tot  1  227
          DB     TXOUT
          DB     1
          DW     CONSTCHARTXT+227

;    532  tot  1    0
          DB     TXOUT
          DB     1
          DW     CONSTCHARTXT+0

;    533  cal  0  325
          DB     OPCAL
          DB     0
          DW     PASPROG + (325 SHL 2)

;    534  tot  1  242
          DB     TXOUT
          DB     1
          DW     CONSTCHARTXT+242

;    535  tot  1    0
          DB     TXOUT
          DB     1
          DW     CONSTCHARTXT+0

;    536  stk  1    4
          DB     OPSTK
          DB     1
          DW     (4 SHL 1)

;    537  lod  0    9
          DB     OPLOD
          DB     0
          DW     (9 SHL 1)

;    538  lod  0   10
          DB     OPLOD
          DB     0
          DW     (10 SHL 1)

;    539  stk  0    6
          DB     OPSTK
          DB     0
          DW     (6 SHL 1)

;    540  cal  0  384
          DB     OPCAL
          DB     0
          DW     PASPROG + (384 SHL 2)

;    541  sto  0    8
          DB     OPSTO
          DB     0
          DW     (8 SHL 1)

;    542  lod  0    8
          DB     OPLOD
          DB     0
          DW     (8 SHL 1)

;    543  lit  0    1
          DB     OPLIT
          DB     0
          DW     1

;    544  opr  0    8
          DB     OPOPR
          DB     0
          DW     8

;    545  jpc  0  549
          DB     OPJPC
          DB     0
          DW     PASPROG + (549 SHL 2)

;    546  tot  1  253
          DB     TXOUT
          DB     1
          DW     CONSTCHARTXT+253

;    547  tot  1    0
          DB     TXOUT
          DB     1
          DW     CONSTCHARTXT+0

;    548  jmp  0  551
          DB     OPJMP
          DB     0
          DW     PASPROG + (551 SHL 2)

;    549  tot  1  260
          DB     TXOUT
          DB     1
          DW     CONSTCHARTXT+260

;    550  tot  1    0
          DB     TXOUT
          DB     1
          DW     CONSTCHARTXT+0

;    551  cal  0  325
          DB     OPCAL
          DB     0
          DW     PASPROG + (325 SHL 2)

;    552  xit  0    0
          DB     OPXIT
          DB     0
          DW     0

CONSTCHARTXT
          DB          13    ;  
          DB          10    ;  

          DB           0    ;   
          DB         114    ;  r
          DB         111    ;  o
          DB         119    ;  w
          DB          32    ;   
          DB         111    ;  o
          DB         117    ;  u
          DB         116    ;  t
          DB          32    ;   
          DB         111    ;  o
          DB         102    ;  f
          DB          32    ;   
          DB          98    ;  b
          DB         111    ;  o
          DB         117    ;  u
          DB         110    ;  n
          DB         100    ;  d
          DB         115    ;  s
          DB          32    ;   
          DB           0    ;   
          DB          99    ;  c
          DB         111    ;  o
          DB         108    ;  l
          DB          32    ;   
          DB         111    ;  o
          DB         117    ;  u
          DB         116    ;  t
          DB          32    ;   
          DB         111    ;  o
          DB         102    ;  f
          DB          32    ;   
          DB          98    ;  b
          DB         111    ;  o
          DB         117    ;  u
          DB         110    ;  n
          DB         100    ;  d
          DB         115    ;  s
          DB          32    ;   
          DB           0    ;   
          DB         109    ;  m
          DB          97    ;  a
          DB         120    ;  x
          DB          99    ;  c
          DB         101    ;  e
          DB         108    ;  l
          DB         108    ;  l
          DB          99    ;  c
          DB         111    ;  o
          DB         117    ;  u
          DB         110    ;  n
          DB         116    ;  t
          DB          32    ;   
          DB           0    ;   
          DB          32    ;   
          DB          97    ;  a
          DB         110    ;  n
          DB         100    ;  d
          DB          32    ;   
          DB         119    ;  w
          DB         101    ;  e
          DB          32    ;   
          DB         104    ;  h
          DB          97    ;  a
          DB         118    ;  v
          DB         101    ;  e
          DB          32    ;   
          DB           0    ;   
          DB          77    ;  M
          DB          65    ;  A
          DB          75    ;  K
          DB          69    ;  E
          DB          32    ;   
          DB          77    ;  M
          DB          65    ;  A
          DB          84    ;  T
          DB          82    ;  R
          DB          73    ;  I
          DB          88    ;  X
          DB          32    ;   
          DB          76    ;  L
          DB          65    ;  A
          DB          82    ;  R
          DB          71    ;  G
          DB          69    ;  E
          DB          82    ;  R
          DB           0    ;   
          DB         119    ;  w
          DB         105    ;  i
          DB         116    ;  t
          DB         104    ;  h
          DB         105    ;  i
          DB         110    ;  n
          DB          32    ;   
          DB         115    ;  s
          DB         105    ;  i
          DB         122    ;  z
          DB         101    ;  e
          DB          44    ;  ,
          DB          32    ;   
          DB         108    ;  l
          DB         101    ;  e
          DB         116    ;  t
          DB         115    ;  s
          DB          32    ;   
          DB         114    ;  r
          DB         117    ;  u
          DB         110    ;  n
          DB          33    ;  !
          DB           0    ;   
          DB         114    ;  r
          DB         111    ;  o
          DB         119    ;  w
          DB          58    ;  :
          DB           0    ;   
          DB          32    ;   
          DB           0    ;   
          DB          88    ;  X
          DB           0    ;   
          DB         120    ;  x
          DB           0    ;   
          DB          32    ;   
          DB           0    ;   
          DB          35    ;  #
          DB           0    ;   
          DB          46    ;  .
          DB           0    ;   
          DB         111    ;  o
          DB           0    ;   
          DB         108    ;  l
          DB         111    ;  o
          DB         111    ;  o
          DB         107    ;  k
          DB         105    ;  i
          DB         110    ;  n
          DB         103    ;  g
          DB          32    ;   
          DB         116    ;  t
          DB         111    ;  o
          DB          32    ;   
          DB         115    ;  s
          DB         101    ;  e
          DB         101    ;  e
          DB          32    ;   
          DB         119    ;  w
          DB         104    ;  h
          DB         101    ;  e
          DB         114    ;  r
          DB         101    ;  e
          DB          32    ;   
          DB          82    ;  R
          DB          65    ;  A
          DB          77    ;  M
          DB          32    ;   
          DB         105    ;  i
          DB         115    ;  s
          DB           0    ;   
          DB         113    ;  q
          DB           0    ;   
          DB         113    ;  q
          DB           0    ;   
          DB         113    ;  q
          DB           0    ;   
          DB         113    ;  q
          DB           0    ;   
          DB          87    ;  W
          DB          65    ;  A
          DB          82    ;  R
          DB          78    ;  N
          DB          73    ;  I
          DB          78    ;  N
          DB          71    ;  G
          DB          44    ;  ,
          DB          32    ;   
          DB          99    ;  c
          DB         111    ;  o
          DB         117    ;  u
          DB         108    ;  l
          DB         100    ;  d
          DB          32    ;   
          DB         110    ;  n
          DB         111    ;  o
          DB         116    ;  t
          DB          32    ;   
          DB         102    ;  f
          DB         105    ;  i
          DB         110    ;  n
          DB         100    ;  d
          DB          32    ;   
          DB         102    ;  f
          DB         114    ;  r
          DB         101    ;  e
          DB         101    ;  e
          DB          32    ;   
          DB          82    ;  R
          DB          65    ;  A
          DB          77    ;  M
          DB           0    ;   
          DB         117    ;  u
          DB         115    ;  s
          DB         105    ;  i
          DB         110    ;  n
          DB         103    ;  g
          DB          32    ;   
          DB          82    ;  R
          DB          65    ;  A
          DB          77    ;  M
          DB          32    ;   
          DB          97    ;  a
          DB         116    ;  t
          DB          58    ;  :
          DB           0    ;   
          DB         109    ;  m
          DB          97    ;  a
          DB         107    ;  k
          DB         101    ;  e
          DB          77    ;  M
          DB          97    ;  a
          DB         116    ;  t
          DB         114    ;  r
          DB         105    ;  i
          DB         120    ;  x
          DB          46    ;  .
          DB          46    ;  .
          DB          46    ;  .
          DB           0    ;   
          DB         112    ;  p
          DB         114    ;  r
          DB         105    ;  i
          DB         110    ;  n
          DB         116    ;  t
          DB          77    ;  M
          DB          97    ;  a
          DB         116    ;  t
          DB         114    ;  r
          DB         105    ;  i
          DB         120    ;  x
          DB          46    ;  .
          DB          46    ;  .
          DB          46    ;  .
          DB           0    ;   
          DB         115    ;  s
          DB         111    ;  o
          DB         108    ;  l
          DB         118    ;  v
          DB         105    ;  i
          DB         110    ;  n
          DB         103    ;  g
          DB          46    ;  .
          DB          46    ;  .
          DB          46    ;  .
          DB           0    ;   
          DB         115    ;  s
          DB         111    ;  o
          DB         108    ;  l
          DB         118    ;  v
          DB         101    ;  e
          DB         100    ;  d
          DB           0    ;   
          DB         110    ;  n
          DB         111    ;  o
          DB         116    ;  t
          DB          32    ;   
          DB         115    ;  s
          DB         111    ;  o
          DB         108    ;  l
          DB         118    ;  v
          DB          97    ;  a
          DB          98    ;  b
          DB         108    ;  l
          DB         101    ;  e
          DB           0    ;   
          DB           0    ;   
        END
