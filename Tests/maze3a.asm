; created from PL0 compiler

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

PLPROG    EQU 08000H + 0800H
          ORG  PLPROG


;      0  ver  012340
          DB     OPVER
          DB     0
          DW 12340

;      1  jmp  0  470
          DB     OPJMP
          DB     0
          DW     PLPROG + (470 SHL 2)

;      2  jmp  0    3
          DB     OPJMP
          DB     0
          DW     PLPROG + (3 SHL 2)

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

;      8  lod  1    4
          DB     OPLOD
          DB     1
          DW     (4 SHL 1)

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
          DW     PLPROG + (18 SHL 2)

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

;     22  lod  1    3
          DB     OPLOD
          DB     1
          DW     (3 SHL 1)

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
          DW     PLPROG + (32 SHL 2)

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

;     32  lod  1   17
          DB     OPLOD
          DB     1
          DW     (17 SHL 1)

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

;     38  lod  1    3
          DB     OPLOD
          DB     1
          DW     (3 SHL 1)

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
          DW     PLPROG + (44 SHL 2)

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
          DW     PLPROG + (65 SHL 2)

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

;     57  cal  1    3
          DB     OPCAL
          DB     1
          DW     PLPROG + (3 SHL 2)

;     58  lod  1    6
          DB     OPLOD
          DB     1
          DW     (6 SHL 1)

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
          DW     PLPROG + (49 SHL 2)

;     65  ret  0    0
          DB     OPRET
          DB     0
          DW     0

;     66  jmp  0   67
          DB     OPJMP
          DB     0
          DW     PLPROG + (67 SHL 2)

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
          DW     PLPROG + (88 SHL 2)

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

;     80  cal  1    3
          DB     OPCAL
          DB     1
          DW     PLPROG + (3 SHL 2)

;     81  lod  1    6
          DB     OPLOD
          DB     1
          DW     (6 SHL 1)

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
          DW     PLPROG + (72 SHL 2)

;     88  ret  0    0
          DB     OPRET
          DB     0
          DW     0

;     89  jmp  0   90
          DB     OPJMP
          DB     0
          DW     PLPROG + (90 SHL 2)

;     90  int  0    5
          DB     OPINT
          DB     0
          DW     (5 SHL 1)

;     91  lit  0   11
          DB     OPLIT
          DB     0
          DW    11

;     92  sto  1    4
          DB     OPSTO
          DB     1
          DW     (4 SHL 1)

;     93  lit  0   11
          DB     OPLIT
          DB     0
          DW    11

;     94  sto  1    3
          DB     OPSTO
          DB     1
          DW     (3 SHL 1)

;     95  tot  1   41
          DB     TXOUT
          DB     1
          DW     CONSTCHARTXT+41

;     96  lod  1   16
          DB     OPLOD
          DB     1
          DW     (16 SHL 1)

;     97  tot  2    0
          DB     TXOUT
          DB     2
          DW     0 ; uint16, on stack

;     98  tot  1   55
          DB     TXOUT
          DB     1
          DW     CONSTCHARTXT+55

;     99  lod  1    4
          DB     OPLOD
          DB     1
          DW     (4 SHL 1)

;    100  lod  1    3
          DB     OPLOD
          DB     1
          DW     (3 SHL 1)

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

;    104  lod  1    4
          DB     OPLOD
          DB     1
          DW     (4 SHL 1)

;    105  lod  1    3
          DB     OPLOD
          DB     1
          DW     (3 SHL 1)

;    106  opr  0    4
          DB     OPOPR
          DB     0
          DW     4

;    107  lod  1   16
          DB     OPLOD
          DB     1
          DW     (16 SHL 1)

;    108  opr  0   12
          DB     OPOPR
          DB     0
          DW    12

;    109  jpc  0  113
          DB     OPJPC
          DB     0
          DW     PLPROG + (113 SHL 2)

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
          DW     PLPROG + (115 SHL 2)

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

;    118  lod  1    4
          DB     OPLOD
          DB     1
          DW     (4 SHL 1)

;    119  opr  0   13
          DB     OPOPR
          DB     0
          DW    13

;    120  jpc  0  144
          DB     OPJPC
          DB     0
          DW     PLPROG + (144 SHL 2)

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

;    124  lod  1    3
          DB     OPLOD
          DB     1
          DW     (3 SHL 1)

;    125  opr  0   13
          DB     OPOPR
          DB     0
          DW    13

;    126  jpc  0  139
          DB     OPJPC
          DB     0
          DW     PLPROG + (139 SHL 2)

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

;    131  cal  1    3
          DB     OPCAL
          DB     1
          DW     PLPROG + (3 SHL 2)

;    132  lod  1    5
          DB     OPLOD
          DB     1
          DW     (5 SHL 1)

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
          DW     PLPROG + (123 SHL 2)

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
          DW     PLPROG + (117 SHL 2)

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

;    150  cal  1   44
          DB     OPCAL
          DB     1
          DW     PLPROG + (44 SHL 2)

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

;    157  cal  1   44
          DB     OPCAL
          DB     1
          DW     PLPROG + (44 SHL 2)

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

;    164  cal  1   67
          DB     OPCAL
          DB     1
          DW     PLPROG + (67 SHL 2)

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

;    171  cal  1   67
          DB     OPCAL
          DB     1
          DW     PLPROG + (67 SHL 2)

;    172  lit  0    1
          DB     OPLIT
          DB     0
          DW     1

;    173  sto  1   12
          DB     OPSTO
          DB     1
          DW     (12 SHL 1)

;    174  lit  0    6
          DB     OPLIT
          DB     0
          DW     6

;    175  sto  1   13
          DB     OPSTO
          DB     1
          DW     (13 SHL 1)

;    176  stk  1    4
          DB     OPSTK
          DB     1
          DW     (4 SHL 1)

;    177  lod  1   12
          DB     OPLOD
          DB     1
          DW     (12 SHL 1)

;    178  lod  1   13
          DB     OPLOD
          DB     1
          DW     (13 SHL 1)

;    179  stk  0    6
          DB     OPSTK
          DB     0
          DW     (6 SHL 1)

;    180  cal  1    3
          DB     OPCAL
          DB     1
          DW     PLPROG + (3 SHL 2)

;    181  sto  1    9
          DB     OPSTO
          DB     1
          DW     (9 SHL 1)

;    182  lod  1    9
          DB     OPLOD
          DB     1
          DW     (9 SHL 1)

;    183  lod  1    5
          DB     OPLOD
          DB     1
          DW     (5 SHL 1)

;    184  opr  0   18
          DB     OPOPR
          DB     0
          DW    18

;    185  lit  0   11
          DB     OPLIT
          DB     0
          DW    11

;    186  sto  1   14
          DB     OPSTO
          DB     1
          DW     (14 SHL 1)

;    187  lit  0    6
          DB     OPLIT
          DB     0
          DW     6

;    188  sto  1   15
          DB     OPSTO
          DB     1
          DW     (15 SHL 1)

;    189  stk  1    4
          DB     OPSTK
          DB     1
          DW     (4 SHL 1)

;    190  lod  1   14
          DB     OPLOD
          DB     1
          DW     (14 SHL 1)

;    191  lod  1   15
          DB     OPLOD
          DB     1
          DW     (15 SHL 1)

;    192  stk  0    6
          DB     OPSTK
          DB     0
          DW     (6 SHL 1)

;    193  cal  1    3
          DB     OPCAL
          DB     1
          DW     PLPROG + (3 SHL 2)

;    194  sto  1   10
          DB     OPSTO
          DB     1
          DW     (10 SHL 1)

;    195  lod  1   10
          DB     OPLOD
          DB     1
          DW     (10 SHL 1)

;    196  lod  1    5
          DB     OPLOD
          DB     1
          DW     (5 SHL 1)

;    197  opr  0   18
          DB     OPOPR
          DB     0
          DW    18

;    198  stk  1    3
          DB     OPSTK
          DB     1
          DW     (3 SHL 1)

;    199  lit  0    3
          DB     OPLIT
          DB     0
          DW     3

;    200  lit  0    1
          DB     OPLIT
          DB     0
          DW     1

;    201  lit  0    3
          DB     OPLIT
          DB     0
          DW     3

;    202  lit  0    7
          DB     OPLIT
          DB     0
          DW     7

;    203  stk  0    7
          DB     OPSTK
          DB     0
          DW     (7 SHL 1)

;    204  cal  1   44
          DB     OPCAL
          DB     1
          DW     PLPROG + (44 SHL 2)

;    205  stk  1    3
          DB     OPSTK
          DB     1
          DW     (3 SHL 1)

;    206  lit  0    4
          DB     OPLIT
          DB     0
          DW     4

;    207  lit  0    7
          DB     OPLIT
          DB     0
          DW     7

;    208  lit  0    4
          DB     OPLIT
          DB     0
          DW     4

;    209  lit  0    9
          DB     OPLIT
          DB     0
          DW     9

;    210  stk  0    7
          DB     OPSTK
          DB     0
          DW     (7 SHL 1)

;    211  cal  1   44
          DB     OPCAL
          DB     1
          DW     PLPROG + (44 SHL 2)

;    212  stk  1    3
          DB     OPSTK
          DB     1
          DW     (3 SHL 1)

;    213  lit  0    5
          DB     OPLIT
          DB     0
          DW     5

;    214  lit  0    3
          DB     OPLIT
          DB     0
          DW     3

;    215  lit  0    5
          DB     OPLIT
          DB     0
          DW     5

;    216  lit  0    5
          DB     OPLIT
          DB     0
          DW     5

;    217  stk  0    7
          DB     OPSTK
          DB     0
          DW     (7 SHL 1)

;    218  cal  1   44
          DB     OPCAL
          DB     1
          DW     PLPROG + (44 SHL 2)

;    219  stk  1    3
          DB     OPSTK
          DB     1
          DW     (3 SHL 1)

;    220  lit  0    5
          DB     OPLIT
          DB     0
          DW     5

;    221  lit  0    7
          DB     OPLIT
          DB     0
          DW     7

;    222  lit  0    5
          DB     OPLIT
          DB     0
          DW     5

;    223  lit  0    9
          DB     OPLIT
          DB     0
          DW     9

;    224  stk  0    7
          DB     OPSTK
          DB     0
          DW     (7 SHL 1)

;    225  cal  1   44
          DB     OPCAL
          DB     1
          DW     PLPROG + (44 SHL 2)

;    226  stk  1    3
          DB     OPSTK
          DB     1
          DW     (3 SHL 1)

;    227  lit  0    6
          DB     OPLIT
          DB     0
          DW     6

;    228  lit  0    5
          DB     OPLIT
          DB     0
          DW     5

;    229  lit  0    6
          DB     OPLIT
          DB     0
          DW     6

;    230  lit  0    5
          DB     OPLIT
          DB     0
          DW     5

;    231  stk  0    7
          DB     OPSTK
          DB     0
          DW     (7 SHL 1)

;    232  cal  1   44
          DB     OPCAL
          DB     1
          DW     PLPROG + (44 SHL 2)

;    233  stk  1    3
          DB     OPSTK
          DB     1
          DW     (3 SHL 1)

;    234  lit  0    6
          DB     OPLIT
          DB     0
          DW     6

;    235  lit  0    9
          DB     OPLIT
          DB     0
          DW     9

;    236  lit  0    6
          DB     OPLIT
          DB     0
          DW     6

;    237  lit  0    9
          DB     OPLIT
          DB     0
          DW     9

;    238  stk  0    7
          DB     OPSTK
          DB     0
          DW     (7 SHL 1)

;    239  cal  1   44
          DB     OPCAL
          DB     1
          DW     PLPROG + (44 SHL 2)

;    240  stk  1    3
          DB     OPSTK
          DB     1
          DW     (3 SHL 1)

;    241  lit  0    7
          DB     OPLIT
          DB     0
          DW     7

;    242  lit  0    1
          DB     OPLIT
          DB     0
          DW     1

;    243  lit  0    7
          DB     OPLIT
          DB     0
          DW     7

;    244  lit  0    2
          DB     OPLIT
          DB     0
          DW     2

;    245  stk  0    7
          DB     OPSTK
          DB     0
          DW     (7 SHL 1)

;    246  cal  1   44
          DB     OPCAL
          DB     1
          DW     PLPROG + (44 SHL 2)

;    247  stk  1    3
          DB     OPSTK
          DB     1
          DW     (3 SHL 1)

;    248  lit  0    7
          DB     OPLIT
          DB     0
          DW     7

;    249  lit  0    5
          DB     OPLIT
          DB     0
          DW     5

;    250  lit  0    7
          DB     OPLIT
          DB     0
          DW     7

;    251  lit  0    7
          DB     OPLIT
          DB     0
          DW     7

;    252  stk  0    7
          DB     OPSTK
          DB     0
          DW     (7 SHL 1)

;    253  cal  1   44
          DB     OPCAL
          DB     1
          DW     PLPROG + (44 SHL 2)

;    254  stk  1    3
          DB     OPSTK
          DB     1
          DW     (3 SHL 1)

;    255  lit  0    7
          DB     OPLIT
          DB     0
          DW     7

;    256  lit  0    9
          DB     OPLIT
          DB     0
          DW     9

;    257  lit  0    7
          DB     OPLIT
          DB     0
          DW     7

;    258  lit  0    9
          DB     OPLIT
          DB     0
          DW     9

;    259  stk  0    7
          DB     OPSTK
          DB     0
          DW     (7 SHL 1)

;    260  cal  1   44
          DB     OPCAL
          DB     1
          DW     PLPROG + (44 SHL 2)

;    261  stk  1    3
          DB     OPSTK
          DB     1
          DW     (3 SHL 1)

;    262  lit  0    8
          DB     OPLIT
          DB     0
          DW     8

;    263  lit  0    5
          DB     OPLIT
          DB     0
          DW     5

;    264  lit  0    8
          DB     OPLIT
          DB     0
          DW     8

;    265  lit  0    5
          DB     OPLIT
          DB     0
          DW     5

;    266  stk  0    7
          DB     OPSTK
          DB     0
          DW     (7 SHL 1)

;    267  cal  1   44
          DB     OPCAL
          DB     1
          DW     PLPROG + (44 SHL 2)

;    268  stk  1    3
          DB     OPSTK
          DB     1
          DW     (3 SHL 1)

;    269  lit  0    8
          DB     OPLIT
          DB     0
          DW     8

;    270  lit  0    9
          DB     OPLIT
          DB     0
          DW     9

;    271  lit  0    8
          DB     OPLIT
          DB     0
          DW     8

;    272  lit  0    9
          DB     OPLIT
          DB     0
          DW     9

;    273  stk  0    7
          DB     OPSTK
          DB     0
          DW     (7 SHL 1)

;    274  cal  1   44
          DB     OPCAL
          DB     1
          DW     PLPROG + (44 SHL 2)

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

;    281  cal  1   44
          DB     OPCAL
          DB     1
          DW     PLPROG + (44 SHL 2)

;    282  stk  1    3
          DB     OPSTK
          DB     1
          DW     (3 SHL 1)

;    283  lit  0    9
          DB     OPLIT
          DB     0
          DW     9

;    284  lit  0    3
          DB     OPLIT
          DB     0
          DW     3

;    285  lit  0    9
          DB     OPLIT
          DB     0
          DW     9

;    286  lit  0    3
          DB     OPLIT
          DB     0
          DW     3

;    287  stk  0    7
          DB     OPSTK
          DB     0
          DW     (7 SHL 1)

;    288  cal  1   44
          DB     OPCAL
          DB     1
          DW     PLPROG + (44 SHL 2)

;    289  stk  1    3
          DB     OPSTK
          DB     1
          DW     (3 SHL 1)

;    290  lit  0    9
          DB     OPLIT
          DB     0
          DW     9

;    291  lit  0    5
          DB     OPLIT
          DB     0
          DW     5

;    292  lit  0    9
          DB     OPLIT
          DB     0
          DW     9

;    293  lit  0    7
          DB     OPLIT
          DB     0
          DW     7

;    294  stk  0    7
          DB     OPSTK
          DB     0
          DW     (7 SHL 1)

;    295  cal  1   44
          DB     OPCAL
          DB     1
          DW     PLPROG + (44 SHL 2)

;    296  stk  1    3
          DB     OPSTK
          DB     1
          DW     (3 SHL 1)

;    297  lit  0    9
          DB     OPLIT
          DB     0
          DW     9

;    298  lit  0    9
          DB     OPLIT
          DB     0
          DW     9

;    299  lit  0    9
          DB     OPLIT
          DB     0
          DW     9

;    300  lit  0    9
          DB     OPLIT
          DB     0
          DW     9

;    301  stk  0    7
          DB     OPSTK
          DB     0
          DW     (7 SHL 1)

;    302  cal  1   44
          DB     OPCAL
          DB     1
          DW     PLPROG + (44 SHL 2)

;    303  stk  1    3
          DB     OPSTK
          DB     1
          DW     (3 SHL 1)

;    304  lit  0   10
          DB     OPLIT
          DB     0
          DW    10

;    305  lit  0    3
          DB     OPLIT
          DB     0
          DW     3

;    306  lit  0   10
          DB     OPLIT
          DB     0
          DW    10

;    307  lit  0    3
          DB     OPLIT
          DB     0
          DW     3

;    308  stk  0    7
          DB     OPSTK
          DB     0
          DW     (7 SHL 1)

;    309  cal  1   44
          DB     OPCAL
          DB     1
          DW     PLPROG + (44 SHL 2)

;    310  stk  1    3
          DB     OPSTK
          DB     1
          DW     (3 SHL 1)

;    311  lit  0   10
          DB     OPLIT
          DB     0
          DW    10

;    312  lit  0    7
          DB     OPLIT
          DB     0
          DW     7

;    313  lit  0   10
          DB     OPLIT
          DB     0
          DW    10

;    314  lit  0    7
          DB     OPLIT
          DB     0
          DW     7

;    315  stk  0    7
          DB     OPSTK
          DB     0
          DW     (7 SHL 1)

;    316  cal  1   44
          DB     OPCAL
          DB     1
          DW     PLPROG + (44 SHL 2)

;    317  ret  0    0
          DB     OPRET
          DB     0
          DW     0

;    318  jmp  0  319
          DB     OPJMP
          DB     0
          DW     PLPROG + (319 SHL 2)

;    319  int  0    7
          DB     OPINT
          DB     0
          DW     (7 SHL 1)

;    320  lit  0    1
          DB     OPLIT
          DB     0
          DW     1

;    321  sto  0    3
          DB     OPSTO
          DB     0
          DW     (3 SHL 1)

;    322  lod  0    3
          DB     OPLOD
          DB     0
          DW     (3 SHL 1)

;    323  lod  1    4
          DB     OPLOD
          DB     1
          DW     (4 SHL 1)

;    324  opr  0   13
          DB     OPOPR
          DB     0
          DW    13

;    325  jpc  0  366
          DB     OPJPC
          DB     0
          DW     PLPROG + (366 SHL 2)

;    326  tot  1  111
          DB     TXOUT
          DB     1
          DW     CONSTCHARTXT+111

;    327  lod  0    3
          DB     OPLOD
          DB     0
          DW     (3 SHL 1)

;    328  tot  2    0
          DB     TXOUT
          DB     2
          DW     0 ; uint16, on stack

;    329  tot  1  116
          DB     TXOUT
          DB     1
          DW     CONSTCHARTXT+116

;    330  lit  0    1
          DB     OPLIT
          DB     0
          DW     1

;    331  sto  0    4
          DB     OPSTO
          DB     0
          DW     (4 SHL 1)

;    332  lod  0    4
          DB     OPLOD
          DB     0
          DW     (4 SHL 1)

;    333  lod  1    3
          DB     OPLOD
          DB     1
          DW     (3 SHL 1)

;    334  opr  0   13
          DB     OPOPR
          DB     0
          DW    13

;    335  jpc  0  360
          DB     OPJPC
          DB     0
          DW     PLPROG + (360 SHL 2)

;    336  stk  1    4
          DB     OPSTK
          DB     1
          DW     (4 SHL 1)

;    337  lod  0    3
          DB     OPLOD
          DB     0
          DW     (3 SHL 1)

;    338  lod  0    4
          DB     OPLOD
          DB     0
          DW     (4 SHL 1)

;    339  stk  0    6
          DB     OPSTK
          DB     0
          DW     (6 SHL 1)

;    340  cal  1    3
          DB     OPCAL
          DB     1
          DW     PLPROG + (3 SHL 2)

;    341  sto  0    5
          DB     OPSTO
          DB     0
          DW     (5 SHL 1)

;    342  lod  0    5
          DB     OPLOD
          DB     0
          DW     (5 SHL 1)

;    343  opr  0   17
          DB     OPOPR
          DB     0
          DW    17

;    344  sto  0    5
          DB     OPSTO
          DB     0
          DW     (5 SHL 1)

;    345  lod  0    5
          DB     OPLOD
          DB     0
          DW     (5 SHL 1)

;    346  lod  1    7
          DB     OPLOD
          DB     1
          DW     (7 SHL 1)

;    347  opr  0    8
          DB     OPOPR
          DB     0
          DW     8

;    348  jpc  0  351
          DB     OPJPC
          DB     0
          DW     PLPROG + (351 SHL 2)

;    349  lod  1    5
          DB     OPLOD
          DB     1
          DW     (5 SHL 1)

;    350  sto  0    5
          DB     OPSTO
          DB     0
          DW     (5 SHL 1)

;    351  lod  0    5
          DB     OPLOD
          DB     0
          DW     (5 SHL 1)

;    352  sto  0    6
          DB     OPSTO
          DB     0
          DW     (6 SHL 1)

;    353  lod  0    6
          DB     OPLOD
          DB     0
          DW     (6 SHL 1)

;    354  tot  3    0
          DB     TXOUT
          DB     3
          DW     0 ; uint16, on stack

;    355  lod  0    4
          DB     OPLOD
          DB     0
          DW     (4 SHL 1)

;    356  lit  0    1
          DB     OPLIT
          DB     0
          DW     1

;    357  opr  0    2
          DB     OPOPR
          DB     0
          DW     2

;    358  sto  0    4
          DB     OPSTO
          DB     0
          DW     (4 SHL 1)

;    359  jmp  0  332
          DB     OPJMP
          DB     0
          DW     PLPROG + (332 SHL 2)

;    360  tot  1    0
          DB     TXOUT
          DB     1
          DW     CONSTCHARTXT+0

;    361  lod  0    3
          DB     OPLOD
          DB     0
          DW     (3 SHL 1)

;    362  lit  0    1
          DB     OPLIT
          DB     0
          DW     1

;    363  opr  0    2
          DB     OPOPR
          DB     0
          DW     2

;    364  sto  0    3
          DB     OPSTO
          DB     0
          DW     (3 SHL 1)

;    365  jmp  0  322
          DB     OPJMP
          DB     0
          DW     PLPROG + (322 SHL 2)

;    366  ret  0    0
          DB     OPRET
          DB     0
          DW     0

;    367  jmp  0  368
          DB     OPJMP
          DB     0
          DW     PLPROG + (368 SHL 2)

;    368  int  0    8
          DB     OPINT
          DB     0
          DW     (8 SHL 1)

;    369  lit  0    0
          DB     OPLIT
          DB     0
          DW     0

;    370  sto  0    6
          DB     OPSTO
          DB     0
          DW     (6 SHL 1)

;    371  lod  0    4
          DB     OPLOD
          DB     0
          DW     (4 SHL 1)

;    372  lit  0    1
          DB     OPLIT
          DB     0
          DW     1

;    373  opr  0   11
          DB     OPOPR
          DB     0
          DW    11

;    374  lod  0    4
          DB     OPLOD
          DB     0
          DW     (4 SHL 1)

;    375  lod  1    4
          DB     OPLOD
          DB     1
          DW     (4 SHL 1)

;    376  opr  0   13
          DB     OPOPR
          DB     0
          DW    13

;    377  opr  0   14
          DB     OPOPR
          DB     0
          DW    14

;    378  lod  0    5
          DB     OPLOD
          DB     0
          DW     (5 SHL 1)

;    379  lit  0    1
          DB     OPLIT
          DB     0
          DW     1

;    380  opr  0   11
          DB     OPOPR
          DB     0
          DW    11

;    381  opr  0   14
          DB     OPOPR
          DB     0
          DW    14

;    382  lod  0    5
          DB     OPLOD
          DB     0
          DW     (5 SHL 1)

;    383  lod  1    3
          DB     OPLOD
          DB     1
          DW     (3 SHL 1)

;    384  opr  0   13
          DB     OPOPR
          DB     0
          DW    13

;    385  opr  0   14
          DB     OPOPR
          DB     0
          DW    14

;    386  jpc  0  467
          DB     OPJPC
          DB     0
          DW     PLPROG + (467 SHL 2)

;    387  stk  1    4
          DB     OPSTK
          DB     1
          DW     (4 SHL 1)

;    388  lod  0    4
          DB     OPLOD
          DB     0
          DW     (4 SHL 1)

;    389  lod  0    5
          DB     OPLOD
          DB     0
          DW     (5 SHL 1)

;    390  stk  0    6
          DB     OPSTK
          DB     0
          DW     (6 SHL 1)

;    391  cal  1    3
          DB     OPCAL
          DB     1
          DW     PLPROG + (3 SHL 2)

;    392  sto  0    7
          DB     OPSTO
          DB     0
          DW     (7 SHL 1)

;    393  lod  0    7
          DB     OPLOD
          DB     0
          DW     (7 SHL 1)

;    394  opr  0   17
          DB     OPOPR
          DB     0
          DW    17

;    395  lod  1    5
          DB     OPLOD
          DB     1
          DW     (5 SHL 1)

;    396  opr  0    8
          DB     OPOPR
          DB     0
          DW     8

;    397  jpc  0  467
          DB     OPJPC
          DB     0
          DW     PLPROG + (467 SHL 2)

;    398  lod  0    7
          DB     OPLOD
          DB     0
          DW     (7 SHL 1)

;    399  lod  1    7
          DB     OPLOD
          DB     1
          DW     (7 SHL 1)

;    400  opr  0   18
          DB     OPOPR
          DB     0
          DW    18

;    401  lod  0    4
          DB     OPLOD
          DB     0
          DW     (4 SHL 1)

;    402  lod  1   14
          DB     OPLOD
          DB     1
          DW     (14 SHL 1)

;    403  opr  0    8
          DB     OPOPR
          DB     0
          DW     8

;    404  lod  0    5
          DB     OPLOD
          DB     0
          DW     (5 SHL 1)

;    405  lod  1   15
          DB     OPLOD
          DB     1
          DW     (15 SHL 1)

;    406  opr  0    8
          DB     OPOPR
          DB     0
          DW     8

;    407  opr  0   14
          DB     OPOPR
          DB     0
          DW    14

;    408  jpc  0  412
          DB     OPJPC
          DB     0
          DW     PLPROG + (412 SHL 2)

;    409  lit  0    1
          DB     OPLIT
          DB     0
          DW     1

;    410  sto  0    6
          DB     OPSTO
          DB     0
          DW     (6 SHL 1)

;    411  jmp  0  460
          DB     OPJMP
          DB     0
          DW     PLPROG + (460 SHL 2)

;    412  lod  0    6
          DB     OPLOD
          DB     0
          DW     (6 SHL 1)

;    413  lit  0    0
          DB     OPLIT
          DB     0
          DW     0

;    414  opr  0    8
          DB     OPOPR
          DB     0
          DW     8

;    415  jpc  0  424
          DB     OPJPC
          DB     0
          DW     PLPROG + (424 SHL 2)

;    416  stk  1    4
          DB     OPSTK
          DB     1
          DW     (4 SHL 1)

;    417  lod  0    4
          DB     OPLOD
          DB     0
          DW     (4 SHL 1)

;    418  lit  0    1
          DB     OPLIT
          DB     0
          DW     1

;    419  opr  0    3
          DB     OPOPR
          DB     0
          DW     3

;    420  lod  0    5
          DB     OPLOD
          DB     0
          DW     (5 SHL 1)

;    421  stk  0    6
          DB     OPSTK
          DB     0
          DW     (6 SHL 1)

;    422  cal  1  368
          DB     OPCAL
          DB     1
          DW     PLPROG + (368 SHL 2)

;    423  sto  0    6
          DB     OPSTO
          DB     0
          DW     (6 SHL 1)

;    424  lod  0    6
          DB     OPLOD
          DB     0
          DW     (6 SHL 1)

;    425  lit  0    0
          DB     OPLIT
          DB     0
          DW     0

;    426  opr  0    8
          DB     OPOPR
          DB     0
          DW     8

;    427  jpc  0  436
          DB     OPJPC
          DB     0
          DW     PLPROG + (436 SHL 2)

;    428  stk  1    4
          DB     OPSTK
          DB     1
          DW     (4 SHL 1)

;    429  lod  0    4
          DB     OPLOD
          DB     0
          DW     (4 SHL 1)

;    430  lod  0    5
          DB     OPLOD
          DB     0
          DW     (5 SHL 1)

;    431  lit  0    1
          DB     OPLIT
          DB     0
          DW     1

;    432  opr  0    3
          DB     OPOPR
          DB     0
          DW     3

;    433  stk  0    6
          DB     OPSTK
          DB     0
          DW     (6 SHL 1)

;    434  cal  1  368
          DB     OPCAL
          DB     1
          DW     PLPROG + (368 SHL 2)

;    435  sto  0    6
          DB     OPSTO
          DB     0
          DW     (6 SHL 1)

;    436  lod  0    6
          DB     OPLOD
          DB     0
          DW     (6 SHL 1)

;    437  lit  0    0
          DB     OPLIT
          DB     0
          DW     0

;    438  opr  0    8
          DB     OPOPR
          DB     0
          DW     8

;    439  jpc  0  448
          DB     OPJPC
          DB     0
          DW     PLPROG + (448 SHL 2)

;    440  stk  1    4
          DB     OPSTK
          DB     1
          DW     (4 SHL 1)

;    441  lod  0    4
          DB     OPLOD
          DB     0
          DW     (4 SHL 1)

;    442  lit  0    1
          DB     OPLIT
          DB     0
          DW     1

;    443  opr  0    2
          DB     OPOPR
          DB     0
          DW     2

;    444  lod  0    5
          DB     OPLOD
          DB     0
          DW     (5 SHL 1)

;    445  stk  0    6
          DB     OPSTK
          DB     0
          DW     (6 SHL 1)

;    446  cal  1  368
          DB     OPCAL
          DB     1
          DW     PLPROG + (368 SHL 2)

;    447  sto  0    6
          DB     OPSTO
          DB     0
          DW     (6 SHL 1)

;    448  lod  0    6
          DB     OPLOD
          DB     0
          DW     (6 SHL 1)

;    449  lit  0    0
          DB     OPLIT
          DB     0
          DW     0

;    450  opr  0    8
          DB     OPOPR
          DB     0
          DW     8

;    451  jpc  0  460
          DB     OPJPC
          DB     0
          DW     PLPROG + (460 SHL 2)

;    452  stk  1    4
          DB     OPSTK
          DB     1
          DW     (4 SHL 1)

;    453  lod  0    4
          DB     OPLOD
          DB     0
          DW     (4 SHL 1)

;    454  lod  0    5
          DB     OPLOD
          DB     0
          DW     (5 SHL 1)

;    455  lit  0    1
          DB     OPLIT
          DB     0
          DW     1

;    456  opr  0    2
          DB     OPOPR
          DB     0
          DW     2

;    457  stk  0    6
          DB     OPSTK
          DB     0
          DW     (6 SHL 1)

;    458  cal  1  368
          DB     OPCAL
          DB     1
          DW     PLPROG + (368 SHL 2)

;    459  sto  0    6
          DB     OPSTO
          DB     0
          DW     (6 SHL 1)

;    460  lod  0    6
          DB     OPLOD
          DB     0
          DW     (6 SHL 1)

;    461  lit  0    1
          DB     OPLIT
          DB     0
          DW     1

;    462  opr  0    8
          DB     OPOPR
          DB     0
          DW     8

;    463  jpc  0  467
          DB     OPJPC
          DB     0
          DW     PLPROG + (467 SHL 2)

;    464  lod  0    7
          DB     OPLOD
          DB     0
          DW     (7 SHL 1)

;    465  lod  1    8
          DB     OPLOD
          DB     1
          DW     (8 SHL 1)

;    466  opr  0   18
          DB     OPOPR
          DB     0
          DW    18

;    467  lod  0    6
          DB     OPLOD
          DB     0
          DW     (6 SHL 1)

;    468  sto  0    3
          DB     OPSTO
          DB     0
          DW     (3 SHL 1)

;    469  ret  1    0
          DB     OPRET
          DB     1
          DW     0

;    470  int  0   18
          DB     OPINT
          DB     0
          DW     (18 SHL 1)

;    471  lit  0  800
          DB     OPLIT
          DB     0
          DW   800

;    472  sto  0   16
          DB     OPSTO
          DB     0
          DW     (16 SHL 1)

;    473  lit  0   32
          DB     OPLIT
          DB     0
          DW    32

;    474  sto  0    5
          DB     OPSTO
          DB     0
          DW     (5 SHL 1)

;    475  lit  0   35
          DB     OPLIT
          DB     0
          DW    35

;    476  sto  0    6
          DB     OPSTO
          DB     0
          DW     (6 SHL 1)

;    477  lit  0   46
          DB     OPLIT
          DB     0
          DW    46

;    478  sto  0    7
          DB     OPSTO
          DB     0
          DW     (7 SHL 1)

;    479  lit  0  111
          DB     OPLIT
          DB     0
          DW   111

;    480  sto  0    8
          DB     OPSTO
          DB     0
          DW     (8 SHL 1)

;    481  lit  040960
          DB     OPLIT
          DB     0
          DW 40960

;    482  sto  0   17
          DB     OPSTO
          DB     0
          DW     (17 SHL 1)

;    483  tot  1  126
          DB     TXOUT
          DB     1
          DW     CONSTCHARTXT+126

;    484  tot  1    0
          DB     TXOUT
          DB     1
          DW     CONSTCHARTXT+0

;    485  cal  0   90
          DB     OPCAL
          DB     0
          DW     PLPROG + (90 SHL 2)

;    486  tot  1  140
          DB     TXOUT
          DB     1
          DW     CONSTCHARTXT+140

;    487  tot  1    0
          DB     TXOUT
          DB     1
          DW     CONSTCHARTXT+0

;    488  cal  0  319
          DB     OPCAL
          DB     0
          DW     PLPROG + (319 SHL 2)

;    489  tot  1  155
          DB     TXOUT
          DB     1
          DW     CONSTCHARTXT+155

;    490  tot  1    0
          DB     TXOUT
          DB     1
          DW     CONSTCHARTXT+0

;    491  stk  1    4
          DB     OPSTK
          DB     1
          DW     (4 SHL 1)

;    492  lod  0   12
          DB     OPLOD
          DB     0
          DW     (12 SHL 1)

;    493  lod  0   13
          DB     OPLOD
          DB     0
          DW     (13 SHL 1)

;    494  stk  0    6
          DB     OPSTK
          DB     0
          DW     (6 SHL 1)

;    495  cal  0  368
          DB     OPCAL
          DB     0
          DW     PLPROG + (368 SHL 2)

;    496  sto  0   11
          DB     OPSTO
          DB     0
          DW     (11 SHL 1)

;    497  lod  0   11
          DB     OPLOD
          DB     0
          DW     (11 SHL 1)

;    498  lit  0    1
          DB     OPLIT
          DB     0
          DW     1

;    499  opr  0    8
          DB     OPOPR
          DB     0
          DW     8

;    500  jpc  0  504
          DB     OPJPC
          DB     0
          DW     PLPROG + (504 SHL 2)

;    501  tot  1  166
          DB     TXOUT
          DB     1
          DW     CONSTCHARTXT+166

;    502  tot  1    0
          DB     TXOUT
          DB     1
          DW     CONSTCHARTXT+0

;    503  jmp  0  506
          DB     OPJMP
          DB     0
          DW     PLPROG + (506 SHL 2)

;    504  tot  1  173
          DB     TXOUT
          DB     1
          DW     CONSTCHARTXT+173

;    505  tot  1    0
          DB     TXOUT
          DB     1
          DW     CONSTCHARTXT+0

;    506  cal  0  319
          DB     OPCAL
          DB     0
          DW     PLPROG + (319 SHL 2)

;    507  xit  0    0
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
          DB          32    ;   
          DB           0    ;   
          DB          35    ;  #
          DB           0    ;   
          DB          46    ;  .
          DB           0    ;   
          DB         111    ;  o
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
