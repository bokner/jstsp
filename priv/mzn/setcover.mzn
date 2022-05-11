% Find minimal (by cardinality and the number of shared tools) set cover for given set of jobs.
% Each job is a set of tools it requires for completion.
include "ssp_pars.mzn";
include "predicates_functions.mzn";
include "ssp_vars.mzn";

array[JOBS] of var 0..1: cover;

array[TOOLS] of var JOBS: tool_count;

constraint forall(t in TOOLS) (
    tool_count[t] = sum(c in JOBS)(job_tools[c, t] * cover[c])
);

constraint set_cover(cover, job_tools);

var 1..T*J: obj;

constraint obj = sum(cover);

%sum(cover) * T  - sum(i in TOOLS)(tool_count[i] > 1);

solve minimize obj;

predicate set_cover(array[JOBS] of var 0..1: cover, array[JOBS, TOOLS] of 0..1: sets) = let {
  array[TOOLS] of var JOBS: tool_count;} in 
  forall(t in TOOLS) (
    sum(c in JOBS)(sets[c, t] * cover[c]) >= 1
);