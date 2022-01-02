function var int: switches(var int: current_job, var int: next_job) =
         sum(t in TOOLS)
         (bool2int(magazine[schedule[next_job], t] > magazine[schedule[current_job], t]));

function var int: total_switches(array[int] of var JOBS: jobs) = 
    sum(i in 1..length(jobs) - 1)(
        switches(jobs[i], jobs[i+1])
    );