include "globals.mzn";

constraint all_different(sequence);


constraint forall(i in JOBS, j in TOOLS)(
   magazine[i, j] >= job_tools[sequence[i], j]
);


/*
constraint forall(j in JOBS)(
  job_tool_sets[sequence[j]] subset magazine_row_sets[j]
);
*/


constraint forall(i in JOBS)(
  %sum(row(magazine, i)) = C
  card(magazine_row_sets[i]) <= C
);

%array[TOOLS] of var JOBS0: tool_switches;

% constraint forall(t in TOOLS) (
%   tool_switches[t] = sum(i in 1..J-1)(magazine[i+1, t] > magazine[i, t])
% );

%constraint cost = sum(tool_switches); 

% Trivial lower bound
constraint cost >= T - C;

%% Set formulation %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Magazine set constraints

%% Magazine row sets (represent jobs in the magazine)
constraint forall(j in JOBS)(
  link_set_to_booleans(magazine_row_sets[j],
        [magazine[j, t] = 1 | t in TOOLS])
);

constraint cost = sum(j in 1..J-1)(
  card(magazine_row_sets[j+1] diff magazine_row_sets[j])
);



%% Magazine column sets (represent tools in the magazine)


constraint forall(t in TOOLS)(
  link_set_to_booleans(magazine_col_sets[t],
        [magazine[j, t] = 1 | j in JOBS])
);

%% Count tool switches using column sets
array[TOOLS] of var JOBS0: tool_switches;

%% Count tool switches for every tool
constraint forall(t in TOOLS)(
  tool_switches[t] = count_tool_switches(t)
);

constraint cost = sum(tool_switches);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% 




%output [show([tool_count_by_job[sequence[i]] | i in JOBS])];