

int: N = 5;
set of int: JOBS = 1..N;
array[JOBS] of var JOBS: sequence;

include "partial_sequence.mzn";
include "globals.mzn";

constraint all_different(sequence);

%% Data

PARTIAL_SEQ_SIZE = 4;
partial_sequence = [2, 4, 3, 1];

%output ["\(reversed_partial_sequence)"];