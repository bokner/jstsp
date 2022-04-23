include "circuit.mzn";

predicate hpath(array[int] of var int: succ, var int: start, var int: end) =
	circuit(succ ++ [start]) /\ succ[end] = length(succ)+1;
	