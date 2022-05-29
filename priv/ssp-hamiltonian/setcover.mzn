% Find minimal (by cardinality and the number of shared tools) set cover for given set of jobs.
% Each job is a set of tools it requires for completion.

%% Input
% int: J;
% int: T;
% int: C;
% set of int: TOOLS = 1..T;
% set of int: JOBS = 1..J;
% array[JOBS, TOOLS] of 0..1:  job_tools;
int: cover_size = 3;

%% Decision vars
array[JOBS] of var 0..1: cover;

array[TOOLS] of var JOBS: tool_count;

%% Constraints
constraint forall(t in TOOLS) (
    tool_count[t] = sum(c in JOBS)(job_tools[c, t] * cover[c])
);

constraint set_cover(cover, job_tools);

var 1..T*J: obj;

var JOBS: cover_obj;

constraint cover_obj = sum(cover);

constraint obj = cover_obj * T  - sum(i in TOOLS)(tool_count[i] > 1);

constraint cover_obj >= min(cover_size, J); 

%solve minimize obj;

predicate set_cover(array[JOBS] of var 0..1: cover, array[JOBS, TOOLS] of 0..1: sets) = let {
  array[TOOLS] of var JOBS: tool_count;} in 
  forall(t in TOOLS) (
    sum(c in JOBS)(sets[c, t] * cover[c]) >= 1
);