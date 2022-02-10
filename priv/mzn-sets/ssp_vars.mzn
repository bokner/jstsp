%% Decision vars
array[JOBS] of var JOBS: sequence;

%% Magazine content
array[JOBS, TOOLS] of var 0..1: magazine; 
array[JOBS] of var set of TOOLS: magazine_row_sets;
array[TOOLS] of var set of JOBS: magazine_col_sets;


array[JOBS] of var set of TOOLS: job_tool_sets;

/*
constraint forall(j in JOBS)(
  link_set_to_booleans(job_tool_sets[j],
        [job_tools[j, t] = 1 | t in TOOLS])
);
*/


var int: cost; 