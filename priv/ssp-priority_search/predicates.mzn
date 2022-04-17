include "circuit.mzn";
include "subcircuit.mzn";

include "pars.mzn";
include "vars.mzn";
include "functions.mzn";
var JOBS: sequence_start;
var int: sequence_end;

%constraint hpath(sequence, sequence_start, sequence_end);
array[1..6] of var 1..6: succ;
array[1..6] of var 1..6: s;

%constraint s = [3, 1, 5, 2, 4];
%constraint circuit(s);

var 1..6: start; 

constraint hpath([s[i] | i in 1..5], start);

predicate hpath(array[1..5] of var 1..5: succ, var int: start) = 
  circuit(succ ++ [start])
   %/\ (succ[end] = length(succ) + 1)
   %circuit(succ ++ [length(succ)])
   ;