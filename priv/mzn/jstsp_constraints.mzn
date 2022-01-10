include "globals.mzn";

constraint all_different(schedule);

constraint forall(i in JOBS, j in TOOLS)(
  magazine[i, j] >= job_tools[i, j]
);

constraint forall(i in JOBS)(
  sum(row(magazine, i)) = C
);

%% Symmetry
%constraint symmetry_breaking_constraint(schedule[1] < schedule[J]);
%constraint schedule[1] = arg_max(tool_count_by_job);
%constraint tool_count_by_job[schedule[1]] = max_tools;
%constraint (tool_count_by_job[schedule[J]] == max_tools) -> (schedule[1] < schedule[J]);

array[1..J-1] of var TOOLS0: magazine_switches;

constraint forall(i in 1..J-1) (
  magazine_switches[i] = switches(i, i+1) 
  /\ magazine_switches[i] <= tool_diff(schedule[i], schedule[i + 1])
);

constraint cost = sum(magazine_switches); 

% Trivial lower bound
constraint cost >= T - C;

%output [show([tool_count_by_job[schedule[i]] | i in JOBS])];