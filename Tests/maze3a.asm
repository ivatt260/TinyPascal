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

OPVER      EQU (000H SHL 1)
OPLIT      EQU (001H SHL 1)
OPLOD      EQU (002H SHL 1)
OPSTO      EQU (003H SHL 1)
OPOPR      EQU (004H SHL 1)
BBOUND     EQU (005H SHL 1)
OPSTK      EQU (006H SHL 1)
OPINT      EQU (007H SHL 1)
OPPCAL     EQU (008H SHL 1)
OPFCAL     EQU (009H SHL 1)
OPPRET     EQU (00AH SHL 1)
OPFRET     EQU (00BH SHL 1)
OPJMP      EQU (00CH SHL 1)
OPJPC      EQU (00DH SHL 1)
TXOUT      EQU (00EH SHL 1)
TXTIN      EQU (00FH SHL 1)
OPXIT      EQU (010H SHL 1)

PASPROG    EQU ORGINIT + 0800H
          ORG  PASPROG


;      0  ver  012341
          DB        OPVER
          DW     12341

;      1  jmp  0  487
          DB        OPJMP
          DW     LINE487

;      2  jmp  0    3
LINE2
          DB        OPJMP
          DW     LINE3

;      3  int  0    6
LINE3
          DB        OPINT
          DW     (6 SHL 1)

;      4  lod  0    4
          DB        OPLOD
          DB      0
          DW     (4 SHL 1)

;      5  lit  0    1
          DB        OPLIT
          DW     1

;      6  opr  0   10
          DB        OPOPR
          DB     (10 SHL 2)
; no ax field

;      7  lod  0    4
          DB        OPLOD
          DB      0
          DW     (4 SHL 1)

;      8  lod  1    4
          DB        OPLOD
          DB      1
          DW     (4 SHL 1)

;      9  opr  0   12
          DB        OPOPR
          DB     (12 SHL 2)
; no ax field

;     10  opr  0   15
          DB        OPOPR
          DB     (15 SHL 2)
; no ax field

;     11  jpc  0   18
          DB        OPJPC
          DW     LINE18

;     12 txot  1    3
          DB        TXOUT
          DB      1
          DW       CONSTCHARTXT+3

;     13  lod  0    4
          DB        OPLOD
          DB      0
          DW     (4 SHL 1)

;     14 txot  2    0
          DB        TXOUT
          DB      2
          DW     0 ; uint16, on stack

;     15 txot  1    0
          DB        TXOUT
          DB      1
          DW       CONSTCHARTXT+0

;     16  lit  0    1
          DB        OPLIT
          DW     1

;     17  sto  0    4
          DB        OPSTO
          DB      0
          DW     (4 SHL 1)

;     18  lod  0    5
LINE18
          DB        OPLOD
          DB      0
          DW     (5 SHL 1)

;     19  lit  0    1
          DB        OPLIT
          DW     1

;     20  opr  0   10
          DB        OPOPR
          DB     (10 SHL 2)
; no ax field

;     21  lod  0    5
          DB        OPLOD
          DB      0
          DW     (5 SHL 1)

;     22  lod  1    3
          DB        OPLOD
          DB      1
          DW     (3 SHL 1)

;     23  opr  0   12
          DB        OPOPR
          DB     (12 SHL 2)
; no ax field

;     24  opr  0   15
          DB        OPOPR
          DB     (15 SHL 2)
; no ax field

;     25  jpc  0   32
          DB        OPJPC
          DW     LINE32

;     26 txot  1   22
          DB        TXOUT
          DB      1
          DW       CONSTCHARTXT+22

;     27  lod  0    5
          DB        OPLOD
          DB      0
          DW     (5 SHL 1)

;     28 txot  2    0
          DB        TXOUT
          DB      2
          DW     0 ; uint16, on stack

;     29 txot  1    0
          DB        TXOUT
          DB      1
          DW       CONSTCHARTXT+0

;     30  lit  0    1
          DB        OPLIT
          DW     1

;     31  sto  0    5
          DB        OPSTO
          DB      0
          DW     (5 SHL 1)

;     32  lod  1   17
LINE32
          DB        OPLOD
          DB      1
          DW     (17 SHL 1)

;     33  lod  0    5
          DB        OPLOD
          DB      0
          DW     (5 SHL 1)

;     34  opr  0    2
          DB        OPOPR
          DB     (2 SHL 2)
; no ax field

;     35  lod  0    4
          DB        OPLOD
          DB      0
          DW     (4 SHL 1)

;     36  lit  0    1
          DB        OPLIT
          DW     1

;     37  opr  0    3
          DB        OPOPR
          DB     (3 SHL 2)
; no ax field

;     38  lod  1    3
          DB        OPLOD
          DB      1
          DW     (3 SHL 1)

;     39  opr  0    4
          DB        OPOPR
          DB     (4 SHL 2)
; no ax field

;     40  opr  0    2
          DB        OPOPR
          DB     (2 SHL 2)
; no ax field

;     41  sto  0    3
          DB        OPSTO
          DB      0
          DW     (3 SHL 1)

;     42 fret  1    0
          DB       OPFRET
; no ax field

;     43  jmp  0   44
LINE43
          DB        OPJMP
          DW     LINE44

;     44  int  0    9
LINE44
          DB        OPINT
          DW     (9 SHL 1)

;     45  lod  0    3
          DB        OPLOD
          DB      0
          DW     (3 SHL 1)

;     46  sto  0    7
          DB        OPSTO
          DB      0
          DW     (7 SHL 1)

;     47  lod  0    4
          DB        OPLOD
          DB      0
          DW     (4 SHL 1)

;     48  sto  0    8
          DB        OPSTO
          DB      0
          DW     (8 SHL 1)

;     49  lod  0    8
LINE49
          DB        OPLOD
          DB      0
          DW     (8 SHL 1)

;     50  lod  0    6
          DB        OPLOD
          DB      0
          DW     (6 SHL 1)

;     51  opr  0   13
          DB        OPOPR
          DB     (13 SHL 2)
; no ax field

;     52  jpc  0   65
          DB        OPJPC
          DW     LINE65

;     53  stk  1    4
          DB        OPSTK
          DB      1
          DW     (4 SHL 1)

;     54  lod  0    7
          DB        OPLOD
          DB      0
          DW     (7 SHL 1)

;     55  lod  0    8
          DB        OPLOD
          DB      0
          DW     (8 SHL 1)

;     56  stk  0    6
          DB        OPSTK
          DB      0
          DW     (6 SHL 1)

;     57 fcal  1    2
          DB       OPFCAL
          DW     LINE2

;     58  lod  1    6
          DB        OPLOD
          DB      1
          DW     (6 SHL 1)

;     59  opr  0   18
          DB        OPOPR
          DB     (18 SHL 2)
; no ax field

;     60  lod  0    8
          DB        OPLOD
          DB      0
          DW     (8 SHL 1)

;     61  lit  0    1
          DB        OPLIT
          DW     1

;     62  opr  0    2
          DB        OPOPR
          DB     (2 SHL 2)
; no ax field

;     63  sto  0    8
          DB        OPSTO
          DB      0
          DW     (8 SHL 1)

;     64  jmp  0   49
          DB        OPJMP
          DW     LINE49

;     65 pret  0    0
LINE65
          DB       OPPRET
; no ax field

;     66  jmp  0   67
LINE66
          DB        OPJMP
          DW     LINE67

;     67  int  0    9
LINE67
          DB        OPINT
          DW     (9 SHL 1)

;     68  lod  0    4
          DB        OPLOD
          DB      0
          DW     (4 SHL 1)

;     69  sto  0    8
          DB        OPSTO
          DB      0
          DW     (8 SHL 1)

;     70  lod  0    3
          DB        OPLOD
          DB      0
          DW     (3 SHL 1)

;     71  sto  0    7
          DB        OPSTO
          DB      0
          DW     (7 SHL 1)

;     72  lod  0    7
LINE72
          DB        OPLOD
          DB      0
          DW     (7 SHL 1)

;     73  lod  0    5
          DB        OPLOD
          DB      0
          DW     (5 SHL 1)

;     74  opr  0   13
          DB        OPOPR
          DB     (13 SHL 2)
; no ax field

;     75  jpc  0   88
          DB        OPJPC
          DW     LINE88

;     76  stk  1    4
          DB        OPSTK
          DB      1
          DW     (4 SHL 1)

;     77  lod  0    7
          DB        OPLOD
          DB      0
          DW     (7 SHL 1)

;     78  lod  0    8
          DB        OPLOD
          DB      0
          DW     (8 SHL 1)

;     79  stk  0    6
          DB        OPSTK
          DB      0
          DW     (6 SHL 1)

;     80 fcal  1    2
          DB       OPFCAL
          DW     LINE2

;     81  lod  1    6
          DB        OPLOD
          DB      1
          DW     (6 SHL 1)

;     82  opr  0   18
          DB        OPOPR
          DB     (18 SHL 2)
; no ax field

;     83  lod  0    7
          DB        OPLOD
          DB      0
          DW     (7 SHL 1)

;     84  lit  0    1
          DB        OPLIT
          DW     1

;     85  opr  0    2
          DB        OPOPR
          DB     (2 SHL 2)
; no ax field

;     86  sto  0    7
          DB        OPSTO
          DB      0
          DW     (7 SHL 1)

;     87  jmp  0   72
          DB        OPJMP
          DW     LINE72

;     88 pret  0    0
LINE88
          DB       OPPRET
; no ax field

;     89  jmp  0   90
LINE89
          DB        OPJMP
          DW     LINE90

;     90  int  0    5
LINE90
          DB        OPINT
          DW     (5 SHL 1)

;     91  lit  0   11
          DB        OPLIT
          DW     11

;     92  sto  1    4
          DB        OPSTO
          DB      1
          DW     (4 SHL 1)

;     93  lit  0   11
          DB        OPLIT
          DW     11

;     94  sto  1    3
          DB        OPSTO
          DB      1
          DW     (3 SHL 1)

;     95 txot  1   41
          DB        TXOUT
          DB      1
          DW       CONSTCHARTXT+41

;     96  lod  1   16
          DB        OPLOD
          DB      1
          DW     (16 SHL 1)

;     97 txot  2    0
          DB        TXOUT
          DB      2
          DW     0 ; uint16, on stack

;     98 txot  1   55
          DB        TXOUT
          DB      1
          DW       CONSTCHARTXT+55

;     99  lod  1    4
          DB        OPLOD
          DB      1
          DW     (4 SHL 1)

;    100  lod  1    3
          DB        OPLOD
          DB      1
          DW     (3 SHL 1)

;    101  opr  0    4
          DB        OPOPR
          DB     (4 SHL 2)
; no ax field

;    102 txot  2    0
          DB        TXOUT
          DB      2
          DW     0 ; uint16, on stack

;    103 txot  1    0
          DB        TXOUT
          DB      1
          DW       CONSTCHARTXT+0

;    104  lod  1    4
          DB        OPLOD
          DB      1
          DW     (4 SHL 1)

;    105  lod  1    3
          DB        OPLOD
          DB      1
          DW     (3 SHL 1)

;    106  opr  0    4
          DB        OPOPR
          DB     (4 SHL 2)
; no ax field

;    107  lod  1   16
          DB        OPLOD
          DB      1
          DW     (16 SHL 1)

;    108  opr  0   12
          DB        OPOPR
          DB     (12 SHL 2)
; no ax field

;    109  jpc  0  113
          DB        OPJPC
          DW     LINE113

;    110 txot  1   69
          DB        TXOUT
          DB      1
          DW       CONSTCHARTXT+69

;    111 txot  1    0
          DB        TXOUT
          DB      1
          DW       CONSTCHARTXT+0

;    112  jmp  0  115
          DB        OPJMP
          DW     LINE115

;    113 txot  1   88
LINE113
          DB        TXOUT
          DB      1
          DW       CONSTCHARTXT+88

;    114 txot  1    0
          DB        TXOUT
          DB      1
          DW       CONSTCHARTXT+0

;    115  lit  0    1
LINE115
          DB        OPLIT
          DW     1

;    116  sto  0    3
          DB        OPSTO
          DB      0
          DW     (3 SHL 1)

;    117  lod  0    3
LINE117
          DB        OPLOD
          DB      0
          DW     (3 SHL 1)

;    118  lod  1    4
          DB        OPLOD
          DB      1
          DW     (4 SHL 1)

;    119  opr  0   13
          DB        OPOPR
          DB     (13 SHL 2)
; no ax field

;    120  jpc  0  144
          DB        OPJPC
          DW     LINE144

;    121  lit  0    1
          DB        OPLIT
          DW     1

;    122  sto  0    4
          DB        OPSTO
          DB      0
          DW     (4 SHL 1)

;    123  lod  0    4
LINE123
          DB        OPLOD
          DB      0
          DW     (4 SHL 1)

;    124  lod  1    3
          DB        OPLOD
          DB      1
          DW     (3 SHL 1)

;    125  opr  0   13
          DB        OPOPR
          DB     (13 SHL 2)
; no ax field

;    126  jpc  0  139
          DB        OPJPC
          DW     LINE139

;    127  stk  1    4
          DB        OPSTK
          DB      1
          DW     (4 SHL 1)

;    128  lod  0    3
          DB        OPLOD
          DB      0
          DW     (3 SHL 1)

;    129  lod  0    4
          DB        OPLOD
          DB      0
          DW     (4 SHL 1)

;    130  stk  0    6
          DB        OPSTK
          DB      0
          DW     (6 SHL 1)

;    131 fcal  1    2
          DB       OPFCAL
          DW     LINE2

;    132  lod  1    5
          DB        OPLOD
          DB      1
          DW     (5 SHL 1)

;    133  opr  0   18
          DB        OPOPR
          DB     (18 SHL 2)
; no ax field

;    134  lod  0    4
          DB        OPLOD
          DB      0
          DW     (4 SHL 1)

;    135  lit  0    1
          DB        OPLIT
          DW     1

;    136  opr  0    2
          DB        OPOPR
          DB     (2 SHL 2)
; no ax field

;    137  sto  0    4
          DB        OPSTO
          DB      0
          DW     (4 SHL 1)

;    138  jmp  0  123
          DB        OPJMP
          DW     LINE123

;    139  lod  0    3
LINE139
          DB        OPLOD
          DB      0
          DW     (3 SHL 1)

;    140  lit  0    1
          DB        OPLIT
          DW     1

;    141  opr  0    2
          DB        OPOPR
          DB     (2 SHL 2)
; no ax field

;    142  sto  0    3
          DB        OPSTO
          DB      0
          DW     (3 SHL 1)

;    143  jmp  0  117
          DB        OPJMP
          DW     LINE117

;    144  stk  1    3
LINE144
          DB        OPSTK
          DB      1
          DW     (3 SHL 1)

;    145  lit  0    1
          DB        OPLIT
          DW     1

;    146  lit  0    1
          DB        OPLIT
          DW     1

;    147  lit  0    1
          DB        OPLIT
          DW     1

;    148  lit  0   11
          DB        OPLIT
          DW     11

;    149  stk  0    7
          DB        OPSTK
          DB      0
          DW     (7 SHL 1)

;    150 pcal  1   43
          DB       OPPCAL
          DW     LINE43

;    151  stk  1    3
          DB        OPSTK
          DB      1
          DW     (3 SHL 1)

;    152  lit  0   11
          DB        OPLIT
          DW     11

;    153  lit  0    1
          DB        OPLIT
          DW     1

;    154  lit  0   11
          DB        OPLIT
          DW     11

;    155  lit  0   11
          DB        OPLIT
          DW     11

;    156  stk  0    7
          DB        OPSTK
          DB      0
          DW     (7 SHL 1)

;    157 pcal  1   43
          DB       OPPCAL
          DW     LINE43

;    158  stk  1    3
          DB        OPSTK
          DB      1
          DW     (3 SHL 1)

;    159  lit  0    1
          DB        OPLIT
          DW     1

;    160  lit  0    1
          DB        OPLIT
          DW     1

;    161  lit  0   11
          DB        OPLIT
          DW     11

;    162  lit  0    1
          DB        OPLIT
          DW     1

;    163  stk  0    7
          DB        OPSTK
          DB      0
          DW     (7 SHL 1)

;    164 pcal  1   66
          DB       OPPCAL
          DW     LINE66

;    165  stk  1    3
          DB        OPSTK
          DB      1
          DW     (3 SHL 1)

;    166  lit  0    1
          DB        OPLIT
          DW     1

;    167  lit  0   11
          DB        OPLIT
          DW     11

;    168  lit  0   11
          DB        OPLIT
          DW     11

;    169  lit  0   11
          DB        OPLIT
          DW     11

;    170  stk  0    7
          DB        OPSTK
          DB      0
          DW     (7 SHL 1)

;    171 pcal  1   66
          DB       OPPCAL
          DW     LINE66

;    172  lit  0    1
          DB        OPLIT
          DW     1

;    173  sto  1   12
          DB        OPSTO
          DB      1
          DW     (12 SHL 1)

;    174  lit  0    6
          DB        OPLIT
          DW     6

;    175  sto  1   13
          DB        OPSTO
          DB      1
          DW     (13 SHL 1)

;    176  stk  1    4
          DB        OPSTK
          DB      1
          DW     (4 SHL 1)

;    177  lod  1   12
          DB        OPLOD
          DB      1
          DW     (12 SHL 1)

;    178  lod  1   13
          DB        OPLOD
          DB      1
          DW     (13 SHL 1)

;    179  stk  0    6
          DB        OPSTK
          DB      0
          DW     (6 SHL 1)

;    180 fcal  1    2
          DB       OPFCAL
          DW     LINE2

;    181  sto  1    9
          DB        OPSTO
          DB      1
          DW     (9 SHL 1)

;    182  lod  1    9
          DB        OPLOD
          DB      1
          DW     (9 SHL 1)

;    183  lod  1    5
          DB        OPLOD
          DB      1
          DW     (5 SHL 1)

;    184  opr  0   18
          DB        OPOPR
          DB     (18 SHL 2)
; no ax field

;    185  lit  0   11
          DB        OPLIT
          DW     11

;    186  sto  1   14
          DB        OPSTO
          DB      1
          DW     (14 SHL 1)

;    187  lit  0    6
          DB        OPLIT
          DW     6

;    188  sto  1   15
          DB        OPSTO
          DB      1
          DW     (15 SHL 1)

;    189  stk  1    4
          DB        OPSTK
          DB      1
          DW     (4 SHL 1)

;    190  lod  1   14
          DB        OPLOD
          DB      1
          DW     (14 SHL 1)

;    191  lod  1   15
          DB        OPLOD
          DB      1
          DW     (15 SHL 1)

;    192  stk  0    6
          DB        OPSTK
          DB      0
          DW     (6 SHL 1)

;    193 fcal  1    2
          DB       OPFCAL
          DW     LINE2

;    194  sto  1   10
          DB        OPSTO
          DB      1
          DW     (10 SHL 1)

;    195  lod  1   10
          DB        OPLOD
          DB      1
          DW     (10 SHL 1)

;    196  lod  1    5
          DB        OPLOD
          DB      1
          DW     (5 SHL 1)

;    197  opr  0   18
          DB        OPOPR
          DB     (18 SHL 2)
; no ax field

;    198  stk  1    3
          DB        OPSTK
          DB      1
          DW     (3 SHL 1)

;    199  lit  0    2
          DB        OPLIT
          DW     2

;    200  lit  0    9
          DB        OPLIT
          DW     9

;    201  lit  0    2
          DB        OPLIT
          DW     2

;    202  lit  0    9
          DB        OPLIT
          DW     9

;    203  stk  0    7
          DB        OPSTK
          DB      0
          DW     (7 SHL 1)

;    204 pcal  1   43
          DB       OPPCAL
          DW     LINE43

;    205  stk  1    3
          DB        OPSTK
          DB      1
          DW     (3 SHL 1)

;    206  lit  0    3
          DB        OPLIT
          DW     3

;    207  lit  0    1
          DB        OPLIT
          DW     1

;    208  lit  0    3
          DB        OPLIT
          DW     3

;    209  lit  0    7
          DB        OPLIT
          DW     7

;    210  stk  0    7
          DB        OPSTK
          DB      0
          DW     (7 SHL 1)

;    211 pcal  1   43
          DB       OPPCAL
          DW     LINE43

;    212  stk  1    3
          DB        OPSTK
          DB      1
          DW     (3 SHL 1)

;    213  lit  0    4
          DB        OPLIT
          DW     4

;    214  lit  0    7
          DB        OPLIT
          DW     7

;    215  lit  0    4
          DB        OPLIT
          DW     4

;    216  lit  0    9
          DB        OPLIT
          DW     9

;    217  stk  0    7
          DB        OPSTK
          DB      0
          DW     (7 SHL 1)

;    218 pcal  1   43
          DB       OPPCAL
          DW     LINE43

;    219  stk  1    3
          DB        OPSTK
          DB      1
          DW     (3 SHL 1)

;    220  lit  0    5
          DB        OPLIT
          DW     5

;    221  lit  0    3
          DB        OPLIT
          DW     3

;    222  lit  0    5
          DB        OPLIT
          DW     5

;    223  lit  0    5
          DB        OPLIT
          DW     5

;    224  stk  0    7
          DB        OPSTK
          DB      0
          DW     (7 SHL 1)

;    225 pcal  1   43
          DB       OPPCAL
          DW     LINE43

;    226  stk  1    3
          DB        OPSTK
          DB      1
          DW     (3 SHL 1)

;    227  lit  0    5
          DB        OPLIT
          DW     5

;    228  lit  0    7
          DB        OPLIT
          DW     7

;    229  lit  0    5
          DB        OPLIT
          DW     5

;    230  lit  0    9
          DB        OPLIT
          DW     9

;    231  stk  0    7
          DB        OPSTK
          DB      0
          DW     (7 SHL 1)

;    232 pcal  1   43
          DB       OPPCAL
          DW     LINE43

;    233  stk  1    3
          DB        OPSTK
          DB      1
          DW     (3 SHL 1)

;    234  lit  0    6
          DB        OPLIT
          DW     6

;    235  lit  0    5
          DB        OPLIT
          DW     5

;    236  lit  0    6
          DB        OPLIT
          DW     6

;    237  lit  0    5
          DB        OPLIT
          DW     5

;    238  stk  0    7
          DB        OPSTK
          DB      0
          DW     (7 SHL 1)

;    239 pcal  1   43
          DB       OPPCAL
          DW     LINE43

;    240  stk  1    3
          DB        OPSTK
          DB      1
          DW     (3 SHL 1)

;    241  lit  0    6
          DB        OPLIT
          DW     6

;    242  lit  0    9
          DB        OPLIT
          DW     9

;    243  lit  0    6
          DB        OPLIT
          DW     6

;    244  lit  0    9
          DB        OPLIT
          DW     9

;    245  stk  0    7
          DB        OPSTK
          DB      0
          DW     (7 SHL 1)

;    246 pcal  1   43
          DB       OPPCAL
          DW     LINE43

;    247  stk  1    3
          DB        OPSTK
          DB      1
          DW     (3 SHL 1)

;    248  lit  0    7
          DB        OPLIT
          DW     7

;    249  lit  0    1
          DB        OPLIT
          DW     1

;    250  lit  0    7
          DB        OPLIT
          DW     7

;    251  lit  0    2
          DB        OPLIT
          DW     2

;    252  stk  0    7
          DB        OPSTK
          DB      0
          DW     (7 SHL 1)

;    253 pcal  1   43
          DB       OPPCAL
          DW     LINE43

;    254  stk  1    3
          DB        OPSTK
          DB      1
          DW     (3 SHL 1)

;    255  lit  0    7
          DB        OPLIT
          DW     7

;    256  lit  0    5
          DB        OPLIT
          DW     5

;    257  lit  0    7
          DB        OPLIT
          DW     7

;    258  lit  0    7
          DB        OPLIT
          DW     7

;    259  stk  0    7
          DB        OPSTK
          DB      0
          DW     (7 SHL 1)

;    260 pcal  1   43
          DB       OPPCAL
          DW     LINE43

;    261  stk  1    3
          DB        OPSTK
          DB      1
          DW     (3 SHL 1)

;    262  lit  0    7
          DB        OPLIT
          DW     7

;    263  lit  0    9
          DB        OPLIT
          DW     9

;    264  lit  0    7
          DB        OPLIT
          DW     7

;    265  lit  0    9
          DB        OPLIT
          DW     9

;    266  stk  0    7
          DB        OPSTK
          DB      0
          DW     (7 SHL 1)

;    267 pcal  1   43
          DB       OPPCAL
          DW     LINE43

;    268  stk  1    3
          DB        OPSTK
          DB      1
          DW     (3 SHL 1)

;    269  lit  0    8
          DB        OPLIT
          DW     8

;    270  lit  0    5
          DB        OPLIT
          DW     5

;    271  lit  0    8
          DB        OPLIT
          DW     8

;    272  lit  0    5
          DB        OPLIT
          DW     5

;    273  stk  0    7
          DB        OPSTK
          DB      0
          DW     (7 SHL 1)

;    274 pcal  1   43
          DB       OPPCAL
          DW     LINE43

;    275  stk  1    3
          DB        OPSTK
          DB      1
          DW     (3 SHL 1)

;    276  lit  0    8
          DB        OPLIT
          DW     8

;    277  lit  0    9
          DB        OPLIT
          DW     9

;    278  lit  0    8
          DB        OPLIT
          DW     8

;    279  lit  0    9
          DB        OPLIT
          DW     9

;    280  stk  0    7
          DB        OPSTK
          DB      0
          DW     (7 SHL 1)

;    281 pcal  1   43
          DB       OPPCAL
          DW     LINE43

;    282  stk  1    3
          DB        OPSTK
          DB      1
          DW     (3 SHL 1)

;    283  lit  0    8
          DB        OPLIT
          DW     8

;    284  lit  0    9
          DB        OPLIT
          DW     9

;    285  lit  0    8
          DB        OPLIT
          DW     8

;    286  lit  0    9
          DB        OPLIT
          DW     9

;    287  stk  0    7
          DB        OPSTK
          DB      0
          DW     (7 SHL 1)

;    288 pcal  1   43
          DB       OPPCAL
          DW     LINE43

;    289  stk  1    3
          DB        OPSTK
          DB      1
          DW     (3 SHL 1)

;    290  lit  0    9
          DB        OPLIT
          DW     9

;    291  lit  0    3
          DB        OPLIT
          DW     3

;    292  lit  0    9
          DB        OPLIT
          DW     9

;    293  lit  0    3
          DB        OPLIT
          DW     3

;    294  stk  0    7
          DB        OPSTK
          DB      0
          DW     (7 SHL 1)

;    295 pcal  1   43
          DB       OPPCAL
          DW     LINE43

;    296  stk  1    3
          DB        OPSTK
          DB      1
          DW     (3 SHL 1)

;    297  lit  0    9
          DB        OPLIT
          DW     9

;    298  lit  0    5
          DB        OPLIT
          DW     5

;    299  lit  0    9
          DB        OPLIT
          DW     9

;    300  lit  0    7
          DB        OPLIT
          DW     7

;    301  stk  0    7
          DB        OPSTK
          DB      0
          DW     (7 SHL 1)

;    302 pcal  1   43
          DB       OPPCAL
          DW     LINE43

;    303  stk  1    3
          DB        OPSTK
          DB      1
          DW     (3 SHL 1)

;    304  lit  0    9
          DB        OPLIT
          DW     9

;    305  lit  0    9
          DB        OPLIT
          DW     9

;    306  lit  0    9
          DB        OPLIT
          DW     9

;    307  lit  0    9
          DB        OPLIT
          DW     9

;    308  stk  0    7
          DB        OPSTK
          DB      0
          DW     (7 SHL 1)

;    309 pcal  1   43
          DB       OPPCAL
          DW     LINE43

;    310  stk  1    3
          DB        OPSTK
          DB      1
          DW     (3 SHL 1)

;    311  lit  0   10
          DB        OPLIT
          DW     10

;    312  lit  0    3
          DB        OPLIT
          DW     3

;    313  lit  0   10
          DB        OPLIT
          DW     10

;    314  lit  0    3
          DB        OPLIT
          DW     3

;    315  stk  0    7
          DB        OPSTK
          DB      0
          DW     (7 SHL 1)

;    316 pcal  1   43
          DB       OPPCAL
          DW     LINE43

;    317  stk  1    3
          DB        OPSTK
          DB      1
          DW     (3 SHL 1)

;    318  lit  0   10
          DB        OPLIT
          DW     10

;    319  lit  0    7
          DB        OPLIT
          DW     7

;    320  lit  0   10
          DB        OPLIT
          DW     10

;    321  lit  0    7
          DB        OPLIT
          DW     7

;    322  stk  0    7
          DB        OPSTK
          DB      0
          DW     (7 SHL 1)

;    323 pcal  1   43
          DB       OPPCAL
          DW     LINE43

;    324 pret  0    0
          DB       OPPRET
; no ax field

;    325  jmp  0  326
LINE325
          DB        OPJMP
          DW     LINE326

;    326  int  0    7
LINE326
          DB        OPINT
          DW     (7 SHL 1)

;    327  lit  0    1
          DB        OPLIT
          DW     1

;    328  sto  0    3
          DB        OPSTO
          DB      0
          DW     (3 SHL 1)

;    329  lod  0    3
LINE329
          DB        OPLOD
          DB      0
          DW     (3 SHL 1)

;    330  lod  1    4
          DB        OPLOD
          DB      1
          DW     (4 SHL 1)

;    331  opr  0   13
          DB        OPOPR
          DB     (13 SHL 2)
; no ax field

;    332  jpc  0  383
          DB        OPJPC
          DW     LINE383

;    333 txot  1  111
          DB        TXOUT
          DB      1
          DW       CONSTCHARTXT+111

;    334  lod  0    3
          DB        OPLOD
          DB      0
          DW     (3 SHL 1)

;    335 txot  2    0
          DB        TXOUT
          DB      2
          DW     0 ; uint16, on stack

;    336 txot  1  116
          DB        TXOUT
          DB      1
          DW       CONSTCHARTXT+116

;    337  lit  0    1
          DB        OPLIT
          DW     1

;    338  sto  0    4
          DB        OPSTO
          DB      0
          DW     (4 SHL 1)

;    339  lod  0    4
LINE339
          DB        OPLOD
          DB      0
          DW     (4 SHL 1)

;    340  lod  1    3
          DB        OPLOD
          DB      1
          DW     (3 SHL 1)

;    341  opr  0   13
          DB        OPOPR
          DB     (13 SHL 2)
; no ax field

;    342  jpc  0  377
          DB        OPJPC
          DW     LINE377

;    343  stk  1    4
          DB        OPSTK
          DB      1
          DW     (4 SHL 1)

;    344  lod  0    3
          DB        OPLOD
          DB      0
          DW     (3 SHL 1)

;    345  lod  0    4
          DB        OPLOD
          DB      0
          DW     (4 SHL 1)

;    346  stk  0    6
          DB        OPSTK
          DB      0
          DW     (6 SHL 1)

;    347 fcal  1    2
          DB       OPFCAL
          DW     LINE2

;    348  sto  0    5
          DB        OPSTO
          DB      0
          DW     (5 SHL 1)

;    349  lod  0    5
          DB        OPLOD
          DB      0
          DW     (5 SHL 1)

;    350  opr  0   17
          DB        OPOPR
          DB     (17 SHL 2)
; no ax field

;    351  sto  0    6
          DB        OPSTO
          DB      0
          DW     (6 SHL 1)

;    352  lod  0    6
          DB        OPLOD
          DB      0
          DW     (6 SHL 1)

;    353  lod  1    7
          DB        OPLOD
          DB      1
          DW     (7 SHL 1)

;    354  opr  0    8
          DB        OPOPR
          DB     (8 SHL 2)
; no ax field

;    355  jpc  0  358
          DB        OPJPC
          DW     LINE358

;    356  lod  1    5
          DB        OPLOD
          DB      1
          DW     (5 SHL 1)

;    357  sto  0    6
          DB        OPSTO
          DB      0
          DW     (6 SHL 1)

;    358  lod  0    6
LINE358
          DB        OPLOD
          DB      0
          DW     (6 SHL 1)

;    359  lit  0  127
          DB        OPLIT
          DW     127

;    360  opr  0   12
          DB        OPOPR
          DB     (12 SHL 2)
; no ax field

;    361  jpc  0  364
          DB        OPJPC
          DW     LINE364

;    362  lit  0   88
          DB        OPLIT
          DW     88

;    363  sto  0    6
          DB        OPSTO
          DB      0
          DW     (6 SHL 1)

;    364  lod  0    6
LINE364
          DB        OPLOD
          DB      0
          DW     (6 SHL 1)

;    365  lit  0   32
          DB        OPLIT
          DW     32

;    366  opr  0   10
          DB        OPOPR
          DB     (10 SHL 2)
; no ax field

;    367  jpc  0  370
          DB        OPJPC
          DW     LINE370

;    368  lit  0  120
          DB        OPLIT
          DW     120

;    369  sto  0    6
          DB        OPSTO
          DB      0
          DW     (6 SHL 1)

;    370  lod  0    6
LINE370
          DB        OPLOD
          DB      0
          DW     (6 SHL 1)

;    371 txot  3    0
          DB        TXOUT
          DB      3
          DW     0 ; uint16, on stack

;    372  lod  0    4
          DB        OPLOD
          DB      0
          DW     (4 SHL 1)

;    373  lit  0    1
          DB        OPLIT
          DW     1

;    374  opr  0    2
          DB        OPOPR
          DB     (2 SHL 2)
; no ax field

;    375  sto  0    4
          DB        OPSTO
          DB      0
          DW     (4 SHL 1)

;    376  jmp  0  339
          DB        OPJMP
          DW     LINE339

;    377 txot  1    0
LINE377
          DB        TXOUT
          DB      1
          DW       CONSTCHARTXT+0

;    378  lod  0    3
          DB        OPLOD
          DB      0
          DW     (3 SHL 1)

;    379  lit  0    1
          DB        OPLIT
          DW     1

;    380  opr  0    2
          DB        OPOPR
          DB     (2 SHL 2)
; no ax field

;    381  sto  0    3
          DB        OPSTO
          DB      0
          DW     (3 SHL 1)

;    382  jmp  0  329
          DB        OPJMP
          DW     LINE329

;    383 pret  0    0
LINE383
          DB       OPPRET
; no ax field

;    384  jmp  0  385
LINE384
          DB        OPJMP
          DW     LINE385

;    385  int  0    8
LINE385
          DB        OPINT
          DW     (8 SHL 1)

;    386  lit  0    0
          DB        OPLIT
          DW     0

;    387  sto  0    6
          DB        OPSTO
          DB      0
          DW     (6 SHL 1)

;    388  lod  0    4
          DB        OPLOD
          DB      0
          DW     (4 SHL 1)

;    389  lit  0    1
          DB        OPLIT
          DW     1

;    390  opr  0   11
          DB        OPOPR
          DB     (11 SHL 2)
; no ax field

;    391  lod  0    4
          DB        OPLOD
          DB      0
          DW     (4 SHL 1)

;    392  lod  1    4
          DB        OPLOD
          DB      1
          DW     (4 SHL 1)

;    393  opr  0   13
          DB        OPOPR
          DB     (13 SHL 2)
; no ax field

;    394  opr  0   14
          DB        OPOPR
          DB     (14 SHL 2)
; no ax field

;    395  lod  0    5
          DB        OPLOD
          DB      0
          DW     (5 SHL 1)

;    396  lit  0    1
          DB        OPLIT
          DW     1

;    397  opr  0   11
          DB        OPOPR
          DB     (11 SHL 2)
; no ax field

;    398  opr  0   14
          DB        OPOPR
          DB     (14 SHL 2)
; no ax field

;    399  lod  0    5
          DB        OPLOD
          DB      0
          DW     (5 SHL 1)

;    400  lod  1    3
          DB        OPLOD
          DB      1
          DW     (3 SHL 1)

;    401  opr  0   13
          DB        OPOPR
          DB     (13 SHL 2)
; no ax field

;    402  opr  0   14
          DB        OPOPR
          DB     (14 SHL 2)
; no ax field

;    403  jpc  0  484
          DB        OPJPC
          DW     LINE484

;    404  stk  1    4
          DB        OPSTK
          DB      1
          DW     (4 SHL 1)

;    405  lod  0    4
          DB        OPLOD
          DB      0
          DW     (4 SHL 1)

;    406  lod  0    5
          DB        OPLOD
          DB      0
          DW     (5 SHL 1)

;    407  stk  0    6
          DB        OPSTK
          DB      0
          DW     (6 SHL 1)

;    408 fcal  1    2
          DB       OPFCAL
          DW     LINE2

;    409  sto  0    7
          DB        OPSTO
          DB      0
          DW     (7 SHL 1)

;    410  lod  0    7
          DB        OPLOD
          DB      0
          DW     (7 SHL 1)

;    411  opr  0   17
          DB        OPOPR
          DB     (17 SHL 2)
; no ax field

;    412  lod  1    5
          DB        OPLOD
          DB      1
          DW     (5 SHL 1)

;    413  opr  0    8
          DB        OPOPR
          DB     (8 SHL 2)
; no ax field

;    414  jpc  0  484
          DB        OPJPC
          DW     LINE484

;    415  lod  0    7
          DB        OPLOD
          DB      0
          DW     (7 SHL 1)

;    416  lod  1    7
          DB        OPLOD
          DB      1
          DW     (7 SHL 1)

;    417  opr  0   18
          DB        OPOPR
          DB     (18 SHL 2)
; no ax field

;    418  lod  0    4
          DB        OPLOD
          DB      0
          DW     (4 SHL 1)

;    419  lod  1   14
          DB        OPLOD
          DB      1
          DW     (14 SHL 1)

;    420  opr  0    8
          DB        OPOPR
          DB     (8 SHL 2)
; no ax field

;    421  lod  0    5
          DB        OPLOD
          DB      0
          DW     (5 SHL 1)

;    422  lod  1   15
          DB        OPLOD
          DB      1
          DW     (15 SHL 1)

;    423  opr  0    8
          DB        OPOPR
          DB     (8 SHL 2)
; no ax field

;    424  opr  0   14
          DB        OPOPR
          DB     (14 SHL 2)
; no ax field

;    425  jpc  0  429
          DB        OPJPC
          DW     LINE429

;    426  lit  0    1
          DB        OPLIT
          DW     1

;    427  sto  0    6
          DB        OPSTO
          DB      0
          DW     (6 SHL 1)

;    428  jmp  0  477
          DB        OPJMP
          DW     LINE477

;    429  lod  0    6
LINE429
          DB        OPLOD
          DB      0
          DW     (6 SHL 1)

;    430  lit  0    0
          DB        OPLIT
          DW     0

;    431  opr  0    8
          DB        OPOPR
          DB     (8 SHL 2)
; no ax field

;    432  jpc  0  441
          DB        OPJPC
          DW     LINE441

;    433  stk  1    4
          DB        OPSTK
          DB      1
          DW     (4 SHL 1)

;    434  lod  0    4
          DB        OPLOD
          DB      0
          DW     (4 SHL 1)

;    435  lit  0    1
          DB        OPLIT
          DW     1

;    436  opr  0    3
          DB        OPOPR
          DB     (3 SHL 2)
; no ax field

;    437  lod  0    5
          DB        OPLOD
          DB      0
          DW     (5 SHL 1)

;    438  stk  0    6
          DB        OPSTK
          DB      0
          DW     (6 SHL 1)

;    439 fcal  1  384
          DB       OPFCAL
          DW     LINE384

;    440  sto  0    6
          DB        OPSTO
          DB      0
          DW     (6 SHL 1)

;    441  lod  0    6
LINE441
          DB        OPLOD
          DB      0
          DW     (6 SHL 1)

;    442  lit  0    0
          DB        OPLIT
          DW     0

;    443  opr  0    8
          DB        OPOPR
          DB     (8 SHL 2)
; no ax field

;    444  jpc  0  453
          DB        OPJPC
          DW     LINE453

;    445  stk  1    4
          DB        OPSTK
          DB      1
          DW     (4 SHL 1)

;    446  lod  0    4
          DB        OPLOD
          DB      0
          DW     (4 SHL 1)

;    447  lod  0    5
          DB        OPLOD
          DB      0
          DW     (5 SHL 1)

;    448  lit  0    1
          DB        OPLIT
          DW     1

;    449  opr  0    3
          DB        OPOPR
          DB     (3 SHL 2)
; no ax field

;    450  stk  0    6
          DB        OPSTK
          DB      0
          DW     (6 SHL 1)

;    451 fcal  1  384
          DB       OPFCAL
          DW     LINE384

;    452  sto  0    6
          DB        OPSTO
          DB      0
          DW     (6 SHL 1)

;    453  lod  0    6
LINE453
          DB        OPLOD
          DB      0
          DW     (6 SHL 1)

;    454  lit  0    0
          DB        OPLIT
          DW     0

;    455  opr  0    8
          DB        OPOPR
          DB     (8 SHL 2)
; no ax field

;    456  jpc  0  465
          DB        OPJPC
          DW     LINE465

;    457  stk  1    4
          DB        OPSTK
          DB      1
          DW     (4 SHL 1)

;    458  lod  0    4
          DB        OPLOD
          DB      0
          DW     (4 SHL 1)

;    459  lit  0    1
          DB        OPLIT
          DW     1

;    460  opr  0    2
          DB        OPOPR
          DB     (2 SHL 2)
; no ax field

;    461  lod  0    5
          DB        OPLOD
          DB      0
          DW     (5 SHL 1)

;    462  stk  0    6
          DB        OPSTK
          DB      0
          DW     (6 SHL 1)

;    463 fcal  1  384
          DB       OPFCAL
          DW     LINE384

;    464  sto  0    6
          DB        OPSTO
          DB      0
          DW     (6 SHL 1)

;    465  lod  0    6
LINE465
          DB        OPLOD
          DB      0
          DW     (6 SHL 1)

;    466  lit  0    0
          DB        OPLIT
          DW     0

;    467  opr  0    8
          DB        OPOPR
          DB     (8 SHL 2)
; no ax field

;    468  jpc  0  477
          DB        OPJPC
          DW     LINE477

;    469  stk  1    4
          DB        OPSTK
          DB      1
          DW     (4 SHL 1)

;    470  lod  0    4
          DB        OPLOD
          DB      0
          DW     (4 SHL 1)

;    471  lod  0    5
          DB        OPLOD
          DB      0
          DW     (5 SHL 1)

;    472  lit  0    1
          DB        OPLIT
          DW     1

;    473  opr  0    2
          DB        OPOPR
          DB     (2 SHL 2)
; no ax field

;    474  stk  0    6
          DB        OPSTK
          DB      0
          DW     (6 SHL 1)

;    475 fcal  1  384
          DB       OPFCAL
          DW     LINE384

;    476  sto  0    6
          DB        OPSTO
          DB      0
          DW     (6 SHL 1)

;    477  lod  0    6
LINE477
          DB        OPLOD
          DB      0
          DW     (6 SHL 1)

;    478  lit  0    1
          DB        OPLIT
          DW     1

;    479  opr  0    8
          DB        OPOPR
          DB     (8 SHL 2)
; no ax field

;    480  jpc  0  484
          DB        OPJPC
          DW     LINE484

;    481  lod  0    7
          DB        OPLOD
          DB      0
          DW     (7 SHL 1)

;    482  lod  1    8
          DB        OPLOD
          DB      1
          DW     (8 SHL 1)

;    483  opr  0   18
          DB        OPOPR
          DB     (18 SHL 2)
; no ax field

;    484  lod  0    6
LINE484
          DB        OPLOD
          DB      0
          DW     (6 SHL 1)

;    485  sto  0    3
          DB        OPSTO
          DB      0
          DW     (3 SHL 1)

;    486 fret  1    0
          DB       OPFRET
; no ax field

;    487  int  0   18
LINE487
          DB        OPINT
          DW     (18 SHL 1)

;    488  lit  0  800
          DB        OPLIT
          DW     800

;    489  sto  0   16
          DB        OPSTO
          DB      0
          DW     (16 SHL 1)

;    490  lit  0   32
          DB        OPLIT
          DW     32

;    491  sto  0    5
          DB        OPSTO
          DB      0
          DW     (5 SHL 1)

;    492  lit  0   35
          DB        OPLIT
          DW     35

;    493  sto  0    6
          DB        OPSTO
          DB      0
          DW     (6 SHL 1)

;    494  lit  0   46
          DB        OPLIT
          DW     46

;    495  sto  0    7
          DB        OPSTO
          DB      0
          DW     (7 SHL 1)

;    496  lit  0  111
          DB        OPLIT
          DW     111

;    497  sto  0    8
          DB        OPSTO
          DB      0
          DW     (8 SHL 1)

;    498 txot  1  130
          DB        TXOUT
          DB      1
          DW       CONSTCHARTXT+130

;    499 txot  1    0
          DB        TXOUT
          DB      1
          DW       CONSTCHARTXT+0

;    500  lit  040960
          DB        OPLIT
          DW     40960

;    501  lit  0  113
          DB        OPLIT
          DW     113

;    502  opr  0   18
          DB        OPOPR
          DB     (18 SHL 2)
; no ax field

;    503  lit  040960
          DB        OPLIT
          DW     40960

;    504  opr  0   17
          DB        OPOPR
          DB     (17 SHL 2)
; no ax field

;    505  lit  0  113
          DB        OPLIT
          DW     113

;    506  opr  0    8
          DB        OPOPR
          DB     (8 SHL 2)
; no ax field

;    507  jpc  0  511
          DB        OPJPC
          DW     LINE511

;    508  lit  040960
          DB        OPLIT
          DW     40960

;    509  sto  0   17
          DB        OPSTO
          DB      0
          DW     (17 SHL 1)

;    510  jmp  0  524
          DB        OPJMP
          DW     LINE524

;    511  lit  0 8192
LINE511
          DB        OPLIT
          DW     8192

;    512  lit  0  113
          DB        OPLIT
          DW     113

;    513  opr  0   18
          DB        OPOPR
          DB     (18 SHL 2)
; no ax field

;    514  lit  0 8192
          DB        OPLIT
          DW     8192

;    515  opr  0   17
          DB        OPOPR
          DB     (17 SHL 2)
; no ax field

;    516  lit  0  113
          DB        OPLIT
          DW     113

;    517  opr  0    8
          DB        OPOPR
          DB     (8 SHL 2)
; no ax field

;    518  jpc  0  522
          DB        OPJPC
          DW     LINE522

;    519  lit  0 8192
          DB        OPLIT
          DW     8192

;    520  sto  0   17
          DB        OPSTO
          DB      0
          DW     (17 SHL 1)

;    521  jmp  0  524
          DB        OPJMP
          DW     LINE524

;    522 txot  1  166
LINE522
          DB        TXOUT
          DB      1
          DW       CONSTCHARTXT+166

;    523 txot  1    0
          DB        TXOUT
          DB      1
          DW       CONSTCHARTXT+0

;    524 txot  1  199
LINE524
          DB        TXOUT
          DB      1
          DW       CONSTCHARTXT+199

;    525  lod  0   17
          DB        OPLOD
          DB      0
          DW     (17 SHL 1)

;    526 txot  2    0
          DB        TXOUT
          DB      2
          DW     0 ; uint16, on stack

;    527 txot  1    0
          DB        TXOUT
          DB      1
          DW       CONSTCHARTXT+0

;    528 txot  1  213
          DB        TXOUT
          DB      1
          DW       CONSTCHARTXT+213

;    529 txot  1    0
          DB        TXOUT
          DB      1
          DW       CONSTCHARTXT+0

;    530 pcal  0   89
          DB       OPPCAL
          DW     LINE89

;    531 txot  1  227
          DB        TXOUT
          DB      1
          DW       CONSTCHARTXT+227

;    532 txot  1    0
          DB        TXOUT
          DB      1
          DW       CONSTCHARTXT+0

;    533 pcal  0  325
          DB       OPPCAL
          DW     LINE325

;    534 txot  1  242
          DB        TXOUT
          DB      1
          DW       CONSTCHARTXT+242

;    535 txot  1    0
          DB        TXOUT
          DB      1
          DW       CONSTCHARTXT+0

;    536  stk  1    4
          DB        OPSTK
          DB      1
          DW     (4 SHL 1)

;    537  lod  0   12
          DB        OPLOD
          DB      0
          DW     (12 SHL 1)

;    538  lod  0   13
          DB        OPLOD
          DB      0
          DW     (13 SHL 1)

;    539  stk  0    6
          DB        OPSTK
          DB      0
          DW     (6 SHL 1)

;    540 fcal  0  384
          DB       OPFCAL
          DW     LINE384

;    541  sto  0   11
          DB        OPSTO
          DB      0
          DW     (11 SHL 1)

;    542  lod  0   11
          DB        OPLOD
          DB      0
          DW     (11 SHL 1)

;    543  lit  0    1
          DB        OPLIT
          DW     1

;    544  opr  0    8
          DB        OPOPR
          DB     (8 SHL 2)
; no ax field

;    545  jpc  0  549
          DB        OPJPC
          DW     LINE549

;    546 txot  1  253
          DB        TXOUT
          DB      1
          DW       CONSTCHARTXT+253

;    547 txot  1    0
          DB        TXOUT
          DB      1
          DW       CONSTCHARTXT+0

;    548  jmp  0  551
          DB        OPJMP
          DW     LINE551

;    549 txot  1  260
LINE549
          DB        TXOUT
          DB      1
          DW       CONSTCHARTXT+260

;    550 txot  1    0
          DB        TXOUT
          DB      1
          DW       CONSTCHARTXT+0

;    551 pcal  0  325
LINE551
          DB       OPPCAL
          DW     LINE325

;    552  xit  0    0
          DB        OPXIT
; no ax field

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
