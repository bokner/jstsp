include "vars.mzn";
include "pars.mzn";
include "functions.mzn";
include "predicates.mzn";
include "solve.mzn";
%include "solve_priority_search.mzn";

include "globals.mzn";

%constraint all_different(sequence);

%% Path (through circuit with dummy node
constraint hpath(sequence, sequence_start, sequence_end);


% Symmetry break
%
constraint sequence[1] < sequence[J];

%array[JOBS0] of var JOBS0: sequence_dummy;
%constraint circuit(sequence_dummy);


array[1..J-1] of var JOBS0: job_switches;
constraint forall(j in 1..J-1) (
  job_switches[j] =  job_switches(j, j + 1)
) :: bounds;

constraint cost = sum(job_switches);
 
%% Count tool switches using column sets
array[TOOLS] of var JOBS0: tool_switches;

%% Count tool switches for every tool
constraint forall(t in TOOLS)(
  tool_switches[t] = tool_switches(t)
) :: bounds;

constraint cost = sum(tool_switches); 
  
%% Trivial lower bound
constraint cost >= T - C;

constraint forall(j in JOBS, t in TOOLS)(
   magazine[j, t] >= job_tools[sequence[j], t]
) :: bounds;

constraint forall(i in JOBS)(
  card(magazine_row_sets[i]) <= C
);

%% Magazine row sets (represent jobs in the magazine state)
constraint forall(j in JOBS)(
  link_set_to_booleans(magazine_row_sets[j],
        [magazine[j, t] = 1| t in TOOLS]
        )
);



%% Magazine column sets (represent tools in the magazine)

constraint forall(t in TOOLS)(
  link_set_to_booleans(magazine_col_sets[t],
        [j < J /\ (magazine[j + 1, t] > magazine[j, t]) | j in JOBS])
);



