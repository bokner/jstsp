%% Job sequencing with tool switching.
%% Given the set T of tools,
%% the set J of jobs, 
%% the requried set of tools for each of the jobs,
%% and a capacity of magazine C -
%% find the schedule of jobs that minimizes the tool switches.

include "globals.mzn";

%% Input
int: J;
int: T;
set of int: TOOLS = 1..T;
set of int: JOBS = 1..J;

array[JOBS, TOOLS] of 0..1:  job_tools;

int: C;      

%% Decision vars
array[JOBS] of var JOBS: schedule;

constraint all_different(schedule);

%% Magazine content
array[JOBS, TOOLS] of var 0..1: magazine; 

constraint forall(i in JOBS, j in TOOLS)(
  magazine[i, j] >= job_tools[i, j]
);

constraint forall(i in JOBS)(
  sum(row(magazine, i)) = C
);

%% Symmetry breaks
constraint lex_lesseq(schedule, reverse(schedule));



var int: cost; 

constraint cost = sum(i in 1..J-1)(switches(i, i+1));

solve minimize cost;

function var int: switches(int: current_job, int: next_job) =
         sum(t in TOOLS)(bool2int(magazine[schedule[next_job], t] > magazine[schedule[current_job], t]));

