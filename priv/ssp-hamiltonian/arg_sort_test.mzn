include "arg_sort.mzn";

int: S = 6;
int: threshold = 3;

array[1..S] of  var set of 1..10: sets = [{}, {3, 7, 9}, {1, 2, 10}, {3, 4, 6}, {2, 4, 8}, {}];

array[1..S] of var 1..S: subset_idx;
%[2, 4];

array[1..S] of var set of 1..10: subsets;

constraint subset_idx = arg_sort([min({t  | t in s where t > threshold}) | s in sets]);

constraint forall(s in index_set(sets))(
  subsets[s] =  if s <=N then sets[subset_idx[s]] else {} endif
);


int: N = 2;

