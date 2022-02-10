function var TOOLS0: switches(var JOBS: current_job, var JOBS: next_job) =
         sum(t in TOOLS)
         (magazine[next_job, t] > magazine[current_job, t]);

% How many switches is required for sequence (job1, job2)? 
function var TOOLS0: tool_diff(var JOBS: job1, var JOBS: job2) = 
    sum(t in TOOLS)(job_tools[job1, t] < job_tools[job2, t]);
    

function var JOBS0: count_tool_switches(int: tool_idx ) = 
  let {
    array[JOBS] of var JOBS0: tool_column = col(magazine, tool_idx);
    array[1..J-1] of var opt JOBS0: diffs = [1 | i in 1..J - 1 where tool_column[i+1] > tool_column[i]]
  } in sum(diffs); 

% function var JOBS0: count_tool_switches(var set of JOBS: magazine_col_set) = 
%   let {
%   var set of JOBS0: s = {0} union magazine_col_set;
%   var set  of JOBS: diffs = {i+1 | i in 1..card(s) - 1 where s[i+1]  - s[i] > 1};
%   } in
%   card(diffs);

%let {set of JOBS: diffs = 
%  {i+1 | i in 1..card(magazine_col_sets) - 1 where magazine_col_set[i+1]  - magazine_col_set[i] > 1}
%;        