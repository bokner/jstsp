include "globals.mzn";

constraint all_different(sequence);

constraint forall(i in JOBS, j in TOOLS)(
  magazine[i, j] >= job_tools[sequence[i], j]
);

constraint forall(i in JOBS)(
  sum(row(magazine, i)) = C
);

array[TOOLS] of var JOBS0: tool_switches;

constraint forall(t in TOOLS) (
  tool_switches[t] = sum(i in 1..J-1)(magazine[i+1, t] > magazine[i, t])
);

constraint cost = sum(tool_switches); 

%constraint cost = sum(j in 1..J-1) (switches(j, j+1));

% Trivial lower bound
constraint cost >= T - C;

%output [show([tool_count_by_job[sequence[i]] | i in JOBS])];