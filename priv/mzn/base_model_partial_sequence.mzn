include "base_model.mzn";

int: PARTIAL_SEQ_SIZE;
array[1..PARTIAL_SEQ_SIZE] of JOBS: partial_sequence;

include "value_precede_chain.mzn";

constraint value_precede_chain(partial_sequence, sequence);