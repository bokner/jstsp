%% Base model for solving SSP (Job Sequencing and Tool Loading Problem)

% Interval definitions
set of int: TOOLS = 1..T;
set of int: TOOLS0 = 0..T;
set of int: JOBS = 1..J;

set of int: JOBS0 = 0..J;

%% Model Input
%%
%% Number of jobs
int: J; 
%% Number of tools 
int: T;
%% Magazine capacity (number of slots)
int: C;  

%% Job tools matrix.
%%
%% Rows represent job tools.
%% job_tools[I, J] = 1  means job I needs tool J   
array[JOBS, TOOLS] of 0..1:  job_tools;

%% Decision variables.
%%
%% Job sequence.
%% 

%% To solve TLP (Tool Loading Problem) for the given job sequence,
%% add it to the instance data.
%% I.e., in your .dzn file:
%% sequence = [4, 2, 5, 3, 6, 1];
%%   
array[JOBS] of var JOBS: sequence;

%% Magazine states.
%% Rows represent the state of the magazine on each step.
%% magazine[I, J] = 1 means the magazine in step I has tool J loaded. 
array[JOBS, TOOLS] of var 0..1: magazine; 

%% Objective - total number of tool switches
var int: cost; 

include "globals.mzn";

%% Jobs are present in the sequence once.
%% 'all_different' global constraint generates permutations.
constraint all_different(sequence);

%% Magazine has all the tools
%% required by the job handled in the current step.
%%   
constraint forall(i in JOBS, j in TOOLS)(
  magazine[i, j] >= job_tools[sequence[i], j]
);

%% The number of tools loaded into the magazine does not exceed 
%% it's capacity
constraint forall(i in JOBS)(
  sum(row(magazine, i)) <= C
);

%% For every tool, count the number of switches it requires.
array[TOOLS] of var JOBS0: tool_switches;

constraint forall(t in TOOLS) (
  tool_switches[t] = sum(i in 1..J-1)(magazine[i+1, t] > magazine[i, t])
);

%% Total number of tool switches
constraint cost = sum(tool_switches); 

%% Alternative switch count.
%% For every job, count how many switches in the magazine
%% is required to prepare for the next job in the sequence.
% 
%% For every tool, count the number of switches it requires.
array[1..J-1] of var TOOLS0: job_switches;
include "predicates_functions.mzn";

constraint forall(j in 1..J-1)(
  job_switches[j] = job_switches(j, j+1)
);

constraint cost = sum(job_switches);

% Trivial lower bound.

constraint cost >= T - C;

%% Solve for minimum cost
solve minimize cost;