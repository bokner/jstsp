%% Decision vars
array[JOBS] of var JOBS: schedule;

%% Magazine content
array[JOBS, TOOLS] of var 0..1: magazine; 

var int: cost; 