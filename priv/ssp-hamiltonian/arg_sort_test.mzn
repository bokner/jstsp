include "arg_sort.mzn";
include "globals.mzn";



predicate threshold_filter(var int: threshold, array[int] of var set of int: sets, array[int] of var set of int: filtered) = 
  forall(s in index_set(sets))(
    forall(e in filtered[s]) (
      member(sets[s], e) /\ e > threshold
    )
  );

predicate first_n(var int: N, int: threshold, array[TOOLS] of var set of JOBS: sets, array[int] of var int: ordered_idx) = 

  let {  
    array[TOOLS] of var TOOLS0: subset_idx; } in
    
    %subset_idx = arg_sort([min({t  | t in s where t > threshold}) | s in sets]) /\
    subset_idx = arg_sort([min({if (t > threshold) then t else T+1 endif  | t in s}) | s in sets])  /\

    forall(i in TOOLS) (
      ordered_idx[i] = if (i <=N /\ (card(sets[subset_idx[i]]) > 0)) then subset_idx[i] else 0 endif);
    %array[1..S] of var 0..S: subset_idx_0;
%[2, 4];

%array[1..S] of var set of 1..10: subsets;


% constraint subset_idx = arg_sort([min({t  | t in s where t > threshold}) | s in sets]);

% constraint forall(i in 1..S) (
%   subset_idx_0[i] = if i <=N then subset_idx[i] else 0 endif
% );


/*
constraint forall(s in index_set(sets))(
  subsets[s] =  if s <=N then sets[subset_idx[s]] else {} endif
);
*/

%% Test predicate

/*

int: S = 6;

set of int: TOOLS = 1..S;
set of int: TOOLS0 = 0..S;
set of int: JOBS = 1..10;

array[TOOLS] of  var set of JOBS: sets = [{}, {3, 7, 9}, {1, 2, 10}, {3, 6}, {2, 4, 8}, {}];

array[TOOLS] of var TOOLS0: first_n_idx;

var int: N = 0;

int: threshold = 3;

constraint first_n(N, threshold, sets, first_n_idx);


array[TOOLS] of var set of JOBS: subsets;

constraint forall(s in TOOLS)(
  subsets[s] =  if first_n_idx[s] > 0 then sets[first_n_idx[s]] else {} endif
);

*/

% 

int: T = 9;
int: J = 5;

set of int: TOOLS = 1..T;
set of int: TOOLS0 = 0..T;
set of int: JOBS = 1..J;


array[JOBS, TOOLS] of var set of JOBS: col_sets=
[| {}, 5..5,   {}, 4..4, {}, {},    {},    {},   {}
 | {}, 5..5,   {},   {}, {}, {},    {},    {},   {}
 | {},   {}, 1..1,   {}, {}, {},    {}, {2,4},   {}
 | {},   {},   {},   {}, {}, {}, {3,5},    {},   {}
 | {},   {},   {}, 4..4, {}, {},    {},    {}, 3..3
 |]; 

array[JOBS, TOOLS] of var TOOLS0: needed_first;




array[TOOLS] of var TOOLS: subset_idx;

int: threshold = 3;

array[TOOLS] of var set of TOOLS: test_set =  [{}, 5..5,   {}, 4..4, {}, {},    {},    {},   {}];

array[TOOLS] of var set of TOOLS: filtered_set; 

constraint threshold_filter(4, test_set, filtered_set);

%constraint subset_idx = arg_sort([min({if (t > threshold /\ card(s) > 0 ) then t else T+1 endif  | t in s}) | s in row(col_sets, 3)]);


%constraint  first_n(4, 3, row(col_sets, 3), row(needed_first, 3));

% constraint forall(j in JOBS) (
%   first_n(4, j, row(col_sets, j), row(needed_first, j))
% );
%);
