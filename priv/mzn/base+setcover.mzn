include "base_ssp.mzn";

int: PARTIAL_SEQ_SIZE;
set of int: PARTIAL_SEQ = 1..PARTIAL_SEQ_SIZE; 
array[PARTIAL_SEQ] of JOBS: partial_sequence;

int: lower_bound;

%% Partial sequence is an optimal sequence for lesser SSP instance, 
%% which is a "set-cover" subset of the jobs in the original SSP instance.
%% Meaning the intersection of this subset of jobs includes all the tools that present in the original SSP.
%% The size of lesser SSP then is the same number of tools and the number of jobs equal to the size of the job subset.
%% 
%% Members of partial sequence are constrained 
%% to be in the same order relative to each other in the job sequence.
constraint value_precede_chain(partial_sequence, sequence);

constraint cost >= lower_bound;
