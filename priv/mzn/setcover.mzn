% Find minimal (by cardinality and the number of shared tools) set cover for given set of jobs.
% Each job is a set of tools it requires for completion.
include "jstsp_types.mzn";
include "jstsp_pars.mzn";

array[JOBS] of var 0..1: cover;

array[TOOLS] of var JOBS: tool_count;

constraint forall(t in TOOLS) (
    tool_count[t] = sum(c in JOBS)(job_tools[c, t] * cover[c])
);

constraint forall(t in TOOLS) (
    tool_count[t] >= 1
);

var 1..T*J: obj;

constraint obj = sum(cover) * T  - sum(i in TOOLS)(tool_count[i] > 1);

solve minimize obj;