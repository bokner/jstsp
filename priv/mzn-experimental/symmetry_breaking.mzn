%% Symmetry
constraint sum(i in TOOLS)(job_tools[sequence[1], i]) == max_tools;
%constraint sequence[1] < sequence[J];

%constraint sequence[1] < sequence[J];
%constraint sum(i in TOOLS)(job_tools[sequence[1], i]) == max_tools;
%constraint sum(i in TOOLS)(job_tools[sequence[1], i] - job_tools[sequence[J], i]) >= 0;
%constraint tool_count_by_job[sequence[1]] > tool_count_by_job[sequence[J]];
%constraint (tool_count_by_job[sequence[J]] == max_tools) -> (sequence[1] < sequence[J]);
