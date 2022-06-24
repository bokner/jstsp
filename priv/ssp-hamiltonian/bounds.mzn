%% Trivial lower bound
constraint cost >= T - C;

%% Trivial upper bound
constraint cost <= upper_bound; 

%% Debug
var int: upper_bound;

constraint upper_bound = min(job_switches_ub * (J - 1), tool_switches_ub * T); 