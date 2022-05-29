function var TOOLS0: job_switches(var JOBS: current_job, var JOBS: next_job) =
         sum(t in TOOLS)
         (magazine[next_job, t] < magazine[current_job, t]);

%include "yuck.mzn";

predicate count_switches(var JOBS: current_job, var JOBS: next_job) = let {
  var 0..job_switches_ub: switches = job_switches[current_job];
  %var 0..job_switches_ub: removals
} in

(
    global_cardinality([magazine[current_job, t] - magazine[next_job, t] | t in TOOLS], [-1, 1], [switches, switches])
    %/\ insertions = job_switches[current_job]
    %/\ job_switches[current_job] = removals
    %insertions = 
    %count(t in TOOLS)(magazine[next_job, t] != magazine[current_job, t]) = 2 *  job_switches[current_job]
    
    %job_switches[current_job] = sum(t in TOOLS)(magazine[next_job, t] < magazine[current_job, t]) 
%    /\
%    job_switches[current_job] =  insertions
);


% How many switches is required for sequence (job1, job2)? 
function TOOLS0: tool_diff(JOBS: job1, JOBS: job2) = 
    sum(t in TOOLS)(job_tools[job1, t] < job_tools[job2, t]);
    