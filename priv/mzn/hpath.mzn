array[JOBS] of var 1..J+1: succ;

var JOBS: succ_start;
var JOBS: succ_end;

constraint hpath(succ, succ_start, succ_end);

constraint sequence[1] = succ_start;
constraint sequence[J] = succ_end;

constraint forall(s in 2..J-1)(
  sequence[s] = succ[sequence[s-1]]
); 

include "circuit.mzn";

predicate hpath(array[int] of var int: succ, var int: start, var int: end) =
	circuit(succ ++ [start]) /\ succ[end] = length(succ)+1;
	