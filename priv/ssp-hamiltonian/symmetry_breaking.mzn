% Symmetry breaking
%
% The sequence and it's reverse have the same cost.

%constraint succ_start < succ_end;

% Next 2 below may cut the solutions!
constraint succ_start = arg_max(tool_count_by_job);

%constraint succ_end = arg_min(tool_count_by_job);

%% First job has at least the same number of tools as the last one.
%constraint card(job_tool_sets[succ_start]) >= card(job_tool_sets[succ_end]);

