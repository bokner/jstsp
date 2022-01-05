include "globals.mzn";

constraint all_different(schedule);

constraint forall(i in JOBS, j in TOOLS)(
  magazine[i, j] >= job_tools[i, j]
);

constraint forall(i in JOBS)(
  sum(row(magazine, i)) = C
);

%% Symmetry
constraint symmetry_breaking_constraint(schedule[1] < schedule[J]);
%constraint schedule[1] = arg_max(tool_count_by_job);
%constraint tool_count_by_job[schedule[1]] = max_tools;
%constraint (tool_count_by_job[schedule[J]] == max_tools) -> (schedule[1] < schedule[J]);

constraint forall(i in 1..J-1) (
  switches(i, i+1) <= tool_diff(i, i + 1)
);

constraint cost = total_switches([i | i in 1..J]); 

% Trivial lower bound
constraint cost >= T - C;

%output [show([tool_count_by_job[schedule[i]] | i in JOBS])];