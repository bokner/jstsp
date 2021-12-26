% Find minimal (by cardinality) set cover for given set of jobs.
% Each job is a set of tools it requires for completion.
include "definitions.mzn";

array[JOBS] of var 0..1: cover;

constraint forall(t in TOOLS) (
    sum(c in JOBS)(job_tools[c, t] * cover[c]) >= 1
);

solve minimize sum(cover);