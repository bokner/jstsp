%% Symmetry
constraint symmetry_breaking_constraint(schedule[1] < schedule[J]);
%constraint schedule[1] = arg_max(tool_count_by_job);
%constraint tool_count_by_job[schedule[1]] = max_tools;
%constraint (tool_count_by_job[schedule[J]] == max_tools) -> (schedule[1] < schedule[J]);
