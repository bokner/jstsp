function var TOOLS0: switches(var JOBS: current_job, var JOBS: next_job) =
         sum(t in TOOLS)
         (bool2int(magazine[schedule[next_job], t] > magazine[schedule[current_job], t]));

function var int: total_switches(array[int] of var JOBS: jobs) = 
    sum(i in 1..length(jobs) - 1)(
        switches(jobs[i], jobs[i+1])
    );

% How many switches is required for sequence (job1, job2)? 
function TOOLS0: tool_diff(JOBS: job1, JOBS: job2) = 
    sum(t in TOOLS)(job_tools[job1, t] < job_tools[job2, t]);