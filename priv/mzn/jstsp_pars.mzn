set of int: TOOLS = 1..T;
set of int: TOOLS0 = 0..T;
set of int: JOBS = 1..J;
set of int: JOBS0 = 0..J;
%% Input
int: J;
int: T;

array[JOBS, TOOLS] of 0..1:  job_tools;

int: C;      

%% Auxillary
%% tool_switches[i, j] is the number of tool switches between jobs i and j.
array[JOBS, JOBS] of int: tool_diffs = array2d(JOBS, JOBS, [tool_diff(i, j) | i,j in JOBS]);
%array[JOBS] of TOOLS: tool_count_by_job = [sum(row(job_tools, i)) | i in JOBS];
%JOBS: max_tools = max(tool_count_by_job); 

%output [show(tool_diffs)];