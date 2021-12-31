%% Job sequencing with tool switching.
%% Given the set T of tools,
%% the set J of jobs, 
%% the required set of tools for each of the jobs,
%% and a capacity of magazine C 
%% find the schedule of jobs that minimizes the tool switches.


include "jstsp_types.mzn";
   
include "jstsp_pars.mzn";

include "jstsp_vars.mzn";

include "jstsp_constraints.mzn";

include "predicates_functions.mzn";

include "solve_definition.mzn";



