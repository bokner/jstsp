%% Job sequencing with tool switching.
%% Given the set T of tools,
%% the set J of jobs, 
%% the required set of tools for each of the jobs,
%% and a capacity of magazine C 
%% find the sequence of jobs that minimizes the tool switches.
   
include "ssp_pars.mzn";

include "ssp_vars.mzn";

include "ssp_constraints.mzn";

include "aux_constraints.mzn";

include "predicates_functions.mzn";

include "symmetry_breaking.mzn";

include "solve_definition.mzn";



