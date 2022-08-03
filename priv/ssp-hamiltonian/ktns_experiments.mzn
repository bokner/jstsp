include "globals.mzn";

int: J = 3;
int: T = 3;

set of int: JOBS = 1..J;
set of int: TOOLS = 1..T;

array[1..3, 1..3] of var int: jobs 
  = 
  [| 1, 0, 0 
   | 0, 1, 1 
   | 0, 0, 1|];
   
% array[1..3] of var set of 1..3: magazine;

% array[1..3] of var set of 1..3: job_sets; 

% constraint forall(i in 1..3)(
%   link_set_to_booleans(job_sets[i],
%         [jobs[i, t] = 1| t in 1..3]
%         )
% );

%constraint min({t | t in test_sets[2] where t < 3}) = 2; 

%%% KTNS policy

%predicate ktns(var 1..J-1: step, 

array[1..6] of var set of 1..10: test_sets = [{3, 7, 9}, {1, 2, 10}, {3, 4, 6}, {2, 4, 8}, {1, 8, 9}, {}];

predicate first_n_sets( var int: N, var int: threshold, array[int] of var set of int: sets, var set of int: first_n_sets) = 
  let {
    array[int] of var  int: sorted_sets = arg_sort([min({t  | t in s where t > threshold}) | s in sets])} in 
    forall(i in index_set(sets))(
      i <= N <->
        sorted_sets[i] in first_n_sets
    ); 

var set of 1..10: first_n_sets; %= {2,4,5};

var int: L = 4;
var int: Th = 6; 
       
constraint first_n_sets(L, Th, test_sets, first_n_sets);   


