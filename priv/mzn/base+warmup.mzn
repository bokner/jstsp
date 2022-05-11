%% Enable warm-ups in base_ssp.mzn!
%%
include "base_ssp.mzn";

%% Use the sequence to initialize solving
array[JOBS] of JOBS: warmup_sequence;
