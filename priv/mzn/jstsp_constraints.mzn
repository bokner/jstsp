include "globals.mzn";

constraint all_different(schedule);

constraint forall(i in JOBS, j in TOOLS)(
  magazine[i, j] >= job_tools[i, j]
);

constraint forall(i in JOBS)(
  sum(row(magazine, i)) = C
);

%% Symmetry breaks
constraint schedule[1] < schedule[J];

constraint cost = total_switches([i | i in 1..J]); 

% Trivial lower bound
constraint cost >= T - C;