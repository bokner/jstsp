function var TOOLS0: switches(var JOBS: current_job, var JOBS: next_job) =
         sum(t in TOOLS)
         (magazine[next_job, t] > magazine[current_job, t]);

% How many switches is required for sequence (job1, job2)? 
function var TOOLS0: tool_diff(var JOBS: job1, var JOBS: job2) = 
    sum(t in TOOLS)(job_tools[job1, t] < job_tools[job2, t]);