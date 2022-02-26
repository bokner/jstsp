%% Symmetry

%constraint sum(i in TOOLS)(job_tools[sequence[1], i]) == max_tools;
%constraint sum(i in TOOLS)(job_tools[sequence[1], i] - job_tools[sequence[J], i]) >= 0;

constraint sequence[1] < sequence[J];

%constraint symmetry_breaking_constraint(sequence[1] < sequence[J]);
%constraint sequence[1] = arg_max(tool_count_by_job);
%constraint tool_count_by_job[sequence[1]] = max_tools;
%constraint (tool_count_by_job[sequence[J]] == max_tools) -> (sequence[1] < sequence[J]);
