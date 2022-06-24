%% Decision vars
array[JOBS] of var JOBS: sequence;

%% Magazine content
array[JOBS, TOOLS] of var 0..1: magazine; 
array[JOBS] of var set of TOOLS: magazine_row_sets;
array[TOOLS] of var set of JOBS: magazine_col_sets;

var (T-C)..C*(J-1): cost;