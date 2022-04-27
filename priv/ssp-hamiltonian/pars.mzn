set of int: TOOLS = 1..T;
set of int: TOOLS0 = 0..T;
set of int: JOBS = 1..J;
set of int: JOBS0 = 0..J;

int: tool_switches_ub = ceil(J/2);

%% Upper bound for job switches: max of symmetrical difference across all pairs of jobs
int: job_switches_ub = max([abs(tool_diff(i, j)) | i, j in JOBS where i < j]); 

%% Input
int: J;
int: T;

array[JOBS, TOOLS] of 0..1:  job_tools;

int: C;      

%% Auxillary

array[JOBS] of TOOLS: tool_count_by_job = [sum(row(job_tools, i)) | i in JOBS];
JOBS: max_tools_job = arg_max(tool_count_by_job); 

array[JOBS]  of var set of TOOLS: job_tool_sets;

constraint forall(j in JOBS)(
  link_set_to_booleans(job_tool_sets[j],
        [job_tools[j, t] = 1| t in TOOLS]
        )
);

