include "vars.mzn";
include "pars.mzn";
include "functions.mzn";
include "predicates.mzn";
include "symmetry_breaking.mzn";
include "bounds.mzn";
include "solve.mzn";
%include "solve_priority_search.mzn";

include "globals.mzn";
%include "link_set_to_booleans.mzn";

array[JOBS] of var 1..J+1: succ;

var JOBS: succ_start;
var JOBS: succ_end;

constraint hpath(succ, succ_start, succ_end);

constraint sequence[1] = succ_start;
constraint sequence[J] = succ_end;

constraint forall(s in 2..J-1)(
  sequence[s] = succ[sequence[s-1]]
); 

constraint all_different(sequence);

%% Count job switches using row sets
array[1..J-1] of var 0..job_switches_ub: job_switches; 

constraint forall(j in 1..J-1) (
  job_switches[j] =  job_switches(j, j + 1)
);


%% Count tool switches using column sets
array[TOOLS] of var 0..tool_switches_ub: tool_switches;

%% Count tool switches for every tool
constraint forall(t in TOOLS)(
  tool_switches[t] = tool_switches(t)
);

%% Two different ways to compute cost

constraint cost = sum(job_switches);
constraint cost = sum(tool_switches); 
  



constraint forall(j in JOBS) (
  job_tool_sets[sequence[j]] subset magazine_row_sets[j]
);


%constraint card(magazine_row_sets[1]) <= C;

constraint forall(i in 1..J)(
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
