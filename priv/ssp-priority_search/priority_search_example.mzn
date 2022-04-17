set of int: X = 1..3;

%include "chuffed.mzn";
include "jacop.mzn";

array[X] of var 1..50: single;
array[X] of var 1..50: double;

constraint forall (x in X) (single[x] * 2 = double[x]);

%annotation priority_search(array[int] of var int, array[int] of ann, ann);

solve 
  :: priority_search(single, [ int_search([ double[x] ], smallest, indomain_min) | x in X], first_fail, complete)
  maximize sum(single) + sum(double);
  
