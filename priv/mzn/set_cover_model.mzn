int: N; %% Number of jobs 
int: T; %% Number of tools
int: C; %% Magazine capacity (number of slots)

array[JOBS, TOOLS] of 0..1:  job_tools;

% Interval definitions
set of int: TOOLS = 1..T;
set of int: JOBS = 1..N;

array[JOBS] of var 0..1: cover;

constraint set_cover(cover, job_tools);

solve minimize sum(cover);

predicate set_cover(array[JOBS] of var 0..1: cover, array[JOBS, TOOLS] of 0..1: sets) = let {
  array[TOOLS] of var JOBS: tool_count;} in 
  forall(t in TOOLS) (
    sum(c in JOBS)(sets[c, t] * cover[c]) >= 1
);