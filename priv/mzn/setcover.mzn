% Find minimal (by cardinality) set cover for given set of jobs.
% Each job is a set of tools it requires for completion.
include "definitions.mzn";

array[JOBS] of var 0..1: cover;

array[TOOLS] of var JOBS: intersection;

constraint forall(t in TOOLS) (
    intersection[t] = sum(c in JOBS)(job_tools[c, t] * cover[c])
);

constraint forall(t in TOOLS) (
    intersection[t] >= 1
);

var 1..T*J: obj;

constraint obj = sum(cover) * T  - sum(i in TOOLS)(intersection[i] > 1);

solve minimize obj;