/* 'Explaining Circuit Propagation'. 
Authors: Kathryn Francis, Peter Stuckey
https://people.eng.unimelb.edu.au/pstuckey/circuit/
*/

include "circuit.mzn";
include "subcircuit.mzn";

predicate path(array[int] of var int: succ, var int: start, var int: end) =
	circuit(succ ++ [start]) /\ succ[end] = length(succ)+1;
	
predicate subcircuit(array[int] of var int: succ);

predicate subpath(array[int] of var int: succ, var int: start, var int: end) =
	subcircuit(succ ++ [start]) /\ start <= length(succ) /\ succ[end] = length(succ)+1;