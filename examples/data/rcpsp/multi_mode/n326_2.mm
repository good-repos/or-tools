************************************************************************
file with basedata            : cn326_.bas
initial value random generator: 1122464749
************************************************************************
projects                      :  1
jobs (incl. supersource/sink ):  18
horizon                       :  124
RESOURCES
  - renewable                 :  2   R
  - nonrenewable              :  3   N
  - doubly constrained        :  0   D
************************************************************************
PROJECT INFORMATION:
pronr.  #jobs rel.date duedate tardcost  MPM-Time
    1     16      0       19        5       19
************************************************************************
PRECEDENCE RELATIONS:
jobnr.    #modes  #successors   successors
   1        1          3           2   3   4
   2        3          1          12
   3        3          3           5   7   8
   4        3          3           6  10  11
   5        3          2           9  13
   6        3          2           7  12
   7        3          2           9  15
   8        3          3          13  14  17
   9        3          2          16  17
  10        3          2          12  13
  11        3          2          14  16
  12        3          2          14  17
  13        3          2          15  16
  14        3          1          15
  15        3          1          18
  16        3          1          18
  17        3          1          18
  18        1          0        
************************************************************************
REQUESTS/DURATIONS:
jobnr. mode duration  R 1  R 2  N 1  N 2  N 3
------------------------------------------------------------------------
  1      1     0       0    0    0    0    0
  2      1     1       0    6    0    3    7
         2     7      10    0    5    3    0
         3     9       9    0    3    0    0
  3      1     4       0    7    0    6    9
         2     7       0    6    0    5    6
         3     7       0    5    9    5    0
  4      1     6       2    0    8    7    0
         2     7       1    0    0    0    4
         3    10       1    0    3    0    2
  5      1     2       0    7    0    0    7
         2     4       8    0    0    0    5
         3     6       7    0    0    4    5
  6      1     1       0    8    0    6    0
         2     4       5    0    0    0    9
         3     6       0    7    3    0    0
  7      1     6       7    0    9   10    0
         2     7       0    7    0    0    8
         3     9       5    0    0    8    7
  8      1     4       0    8    0    0    2
         2     5       0    7    7    0    1
         3     7       0    5    4    3    0
  9      1     3       8    0    0    2    9
         2     3       0    7    0    2    0
         3     4       0    6    6    0    0
 10      1     4       0    5    6    7    0
         2     4       7    0    0    3    0
         3     8       0    5    5    0    5
 11      1     3       0    6    4    0    0
         2     4       0    4    0    3    0
         3     5       7    0    3    0    0
 12      1     1       0    4    0    3    0
         2     4       8    0    7    2    3
         3    10       8    0    7    0    0
 13      1     1       0    7    0    0    8
         2     5       0    5    0    0    7
         3     7       0    4    4    0    7
 14      1     3       5    0    1    7    6
         2     4       0    9    0    0    3
         3    10       0    5    0    0    2
 15      1     3       0    4    7    0    0
         2     5       4    0    0    0    7
         3     8       0    2    0    7    5
 16      1     3       0    8    7    9    7
         2     7       0    6    7    6    0
         3     8       0    6    0    5    6
 17      1     1       0    9    5    0    0
         2     2       8    0    0    7    0
         3    10       7    0    0    7    0
 18      1     0       0    0    0    0    0
************************************************************************
RESOURCEAVAILABILITIES:
  R 1  R 2  N 1  N 2  N 3
   19   17   88   84   91
************************************************************************
