set of int: TOOLS = 1..T;
set of int: JOBS = 1..J;
%% Input
int: J;
int: T;

array[JOBS, TOOLS] of 0..1:  job_tools;

int: C;      

%% Auxillary
array[JOBS] of TOOLS: tool_count_by_job = [sum(row(job_tools, i)) | i in JOBS];
JOBS: max_tools = max(tool_count_by_job); 