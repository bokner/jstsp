%% Base model for solving SSP (Job Sequencing and Tool Switching Problem)

include "solve_definition.mzn";
%include "solve_definition_warmup.mzn";

include "hpath.mzn";

%constraint sequence[1] < sequence[J];



%% Model Input
%%
%% Number of jobs
int: J; 
%% Number of tools 
int: T;
%% Magazine capacity (number of slots)
int: C;  

%% Job tools matrix.
%% One row per job.
%% Rows represent tools that are required for jobs.
%% job_tools[I, J] = 1  means job I needs tool J   
array[JOBS, TOOLS] of 0..1:  job_tools;

% Interval definitions
set of int: TOOLS = 1..T;
set of int: TOOLS0 = 0..T;
set of int: JOBS = 1..J;
set of int: JOBS0 = 0..J;


%% Decision variables.
%%
%% Job sequence.
%% 
array[JOBS] of var JOBS: sequence;

%% To solve TLP (Tool Loading Problem) for the given job sequence,
%% add it to the instance data.
%% I.e., in your .dzn file:
%% sequence = [4, 2, 5, 3, 6, 1];
%%   

%% Magazine states.
%% Rows represent the state of the magazine on each step.
%% magazine[S, T] = 1 means at step S the magazine has tool T loaded. 
array[JOBS, TOOLS] of var 0..1: magazine; 

%% Objective - total number of tool switches
var int: cost; 

include "globals.mzn";

%% Every job is processed once.
%%
%% 'all_different' global constraint enforces job sequence to be a permutation.

constraint all_different(sequence);

%% Magazine has all the tools
%% required by the job handled in the current step.
%%   
constraint forall(j in JOBS, t in TOOLS)(
    magazine[j, t] >= job_tools[sequence[j], t]
);

%% Do not change tools  that are needed for the next job
constraint forall(j in 1..J-1, t in TOOLS)(
  (job_tools[sequence[j + 1], t] =1 /\ job_tools[sequence[j], t] = 1) -> 
    (magazine[j, t] = 1 /\ magazine[j+1, t] = 1)
);

%% The number of tools loaded into the magazine does not exceed 
%% it's capacity
constraint forall(i in JOBS)(
 sum(row(magazine, i)) <= C
);

constraint max([sum(row(magazine, i)) | i in JOBS]) <= C;

%% For every tool, count the number of switches it requires.
%% Upper bound for individual tool switches
int: tool_switches_ub = ceil(J/2);

array[TOOLS] of var 0..tool_switches_ub: tool_switches;


%% Upper bound for job switches: max of symmetrical difference across all pairs of jobs
int: job_switches_ub = min(C, max([abs(tool_diff(i, j)) | i, j in JOBS where i < j])); 


constraint forall(t in TOOLS) (
  tool_switches[t] = sum(i in 1..J-1)(magazine[i+1, t] > magazine[i, t])
);

%% Total number of tool switches
constraint cost = sum(tool_switches); 

%% Alternative counting of tool switches.
%% For every job, count how many switches in the magazine
%% is required to prepare for the next job in the sequence.
% 
%% For every tool, count the number of switches it requires.
array[1..J-1] of var 0..job_switches_ub: job_switches;
include "predicates_functions.mzn";

constraint forall(j in 1..J-1)(
  job_switches[j] = job_switches(j, j+1)
);

constraint cost = sum(job_switches);

% Trivial lower bound.
%
constraint cost >= T - C;

%% Trivial upper bound
constraint cost <= min(job_switches_ub * (J - 1), tool_switches_ub * min(T, 2*C)

);

%% Output
output ["Job sequence: ", show(sequence), "\n", "Number of switches: ",  show(cost), "\n" 
  , "js_ub:", show(job_switches_ub)
  %,"Magazine states:", show(magazine)
]; 