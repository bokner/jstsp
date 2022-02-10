%% Tool Loading Problem

set of int: TOOLS = 1..T;
set of int: TOOLS0 = 0..T;
set of int: JOBS = 1..J;
set of int: JOBS0 = 0..J;
%% Input
int: J;
int: T;

array[JOBS, TOOLS] of 0..1:  job_tools;

int: C;  

%% Job sequence as an input 
array[JOBS] of JOBS: sequence;

%% Decision variables.
%%
%% Magazine content
array[JOBS, TOOLS] of var 0..1: magazine; 

%% Objective
var int: cost; 

include "globals.mzn";

constraint all_different(sequence);

constraint forall(i in JOBS, j in TOOLS)(
  magazine[i, j] >= job_tools[sequence[i], j]
);

constraint forall(i in JOBS)(
  sum(row(magazine, i)) = C
);

array[TOOLS] of var JOBS0: tool_switches;

constraint forall(t in TOOLS) (
  tool_switches[t] = sum(i in 1..J-1)(magazine[i+1, t] > magazine[i, t])
);

constraint cost = sum(tool_switches); 

%% Alternative switch count
include "predicates_functions.mzn";
constraint cost = sum(i in 1..J-1)(switches(i, i+1));

% Trivial lower bound
constraint cost >= T - C;

%% Solve for minimum cost
solve minimize cost;