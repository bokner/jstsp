set of int: TOOLS = 1..T;
set of int: JOBS = 1..J;
%% Input
int: J;
int: T;

array[JOBS, TOOLS] of 0..1:  job_tools;

int: C;      
