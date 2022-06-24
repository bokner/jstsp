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
   
array[1..3] of var set of 1..3: magazine;

array[1..3] of var set of 1..3: job_sets; 

constraint forall(i in 1..3)(
  link_set_to_booleans(job_sets[i],
        [jobs[i, t] = 1| t in 1..3]
        )
);

%constraint min({t | t in test_sets[2] where t < 3}) = 2; 

%%% KTNS policy

%predicate ktns(var 1..J-1: step, 

array[1..4] of var set of 1..9: test_sets = [{3, 5, 7}, {1, 2, 5}, {2, 7, 9}, {1, 4, 8}];

predicate first_n_sets( int: N, array[int] of var set of int: sets, var set of int: first_n_sets) = 
  let {array[int] of var int: sorted_sets =  arg_sort([min(s) | s in sets])} in
    forall(i in index_set(sets))(
      i <= N <->
        sorted_sets[i] in first_n_sets
    )
  ; 

var set of 1..4: first_n_sets;

    
constraint first_n_sets(2, test_sets, first_n_sets);   


