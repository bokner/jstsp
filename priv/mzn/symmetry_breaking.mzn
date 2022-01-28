%% Symmetry
%constraint sum(i in TOOLS)(job_tools[schedule[1], i]) == max_tools;

%constraint sum(i in TOOLS)(job_tools[schedule[1], i] - job_tools[schedule[J], i]) >= 0;
constraint symmetry_breaking_constraint(schedule[1] < schedule[J]);

%constraint symmetry_breaking_constraint(schedule[1] < schedule[J]);
%constraint schedule[1] = arg_max(tool_count_by_job);
%constraint tool_count_by_job[schedule[1]] = max_tools;
%constraint (tool_count_by_job[schedule[J]] == max_tools) -> (schedule[1] < schedule[J]);
