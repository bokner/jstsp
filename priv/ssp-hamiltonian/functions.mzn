function var TOOLS0: job_switches(var JOBS: current_job, var JOBS: next_job) = 
  card(magazine_row_sets[next_job] diff magazine_row_sets[current_job]);

% How many switches is required for sequence (job1, job2)? 
function var TOOLS0: tool_diff(var JOBS: job1, var JOBS: job2) = 
    sum(t in TOOLS)(job_tools[job1, t] < job_tools[job2, t]);
    

function var JOBS0: tool_switches(TOOLS: tool_idx ) =
  card(magazine_col_sets[tool_idx]);

