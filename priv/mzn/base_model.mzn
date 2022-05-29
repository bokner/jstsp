int: N; %% Number of jobs 
int: T; %% Number of tools
int: C; %% Magazine capacity (number of slots)

% Interval definitions
set of int: TOOLS = 1..T;
set of int: JOBS = 1..N;

%% Job tools matrix.
%% One row per job.
%% Rows represent tools that are required for jobs.
%% job_tools[I, J] = 1  means job I needs tool J  
array[JOBS, TOOLS] of 0..1:  job_tools;

%% Decision variables.
%%
%% Job sequence.
array[JOBS] of var JOBS: sequence;

%% Magazine states.
%% Rows represent the state of the magazine on each step.
%% magazine[S, T] = 1 means at step S the magazine has tool T loaded.
array[JOBS, TOOLS] of var 0..1: magazine;

%% For every tool, count the number of switches it requires.
%% Upper bound for individual tool switches
int: tool_switches_ub = ceil(N/2);

array[TOOLS] of var 0..tool_switches_ub: tool_switches;

%% Objective - total number of tool switches
var int: cost;

%% 'all_different' global constraint enforces job sequence to be a permutation.
include "all_different.mzn";
constraint all_different(sequence);
%% Magazine has all the tools required by the job handled in the current step.
%%  
constraint forall(j in JOBS, t in TOOLS)(
   magazine[j, t] >= job_tools[sequence[j], t]
);

%% The number of tools in magazine does not exceed it's capacity
constraint forall(j in JOBS)(
  sum(row(magazine, j)) <= C
  );

constraint forall(t in TOOLS) (
 tool_switches[t] = sum(i in 1..N-1)(magazine[i+1, t]  < magazine[i, t])
);

constraint cost = sum(tool_switches);
%%  Objective
solve minimize cost;
