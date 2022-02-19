
/*
Partial sequence is a sub-sequence of the sequence of jobs.
It's "optimized", i.e., has a minimum number of tool switches
among all permutations of the subset that corresponds to this sub-sequence.

One of the methods it could be obtained is through "set-cover" method.

The partial sequence is used to constrain the main job sequence to 
preserve the order of the partial sequence within.
For instance, if the number of jobs is 5, the partial sequence is [2, 4, 3, 1], 
then the job sequences are:
[5, 2, 4, 3, 1], [2, 5, 4, 3, 1], [2, 4, 5, 3, 1], [2, 4, 3, 5, 1], [2, 4, 3, 1, 5] 
*/

int: PARTIAL_SEQ_SIZE;
set of int: PARTIAL_SEQ = 1..PARTIAL_SEQ_SIZE; 
array[PARTIAL_SEQ] of JOBS: partial_sequence;

%array[JOBS] of var JOBS: sequence;

constraint forall(i in 1..PARTIAL_SEQ_SIZE - 1)(
   position_in_sequence(partial_sequence[i]) < 
   position_in_sequence(partial_sequence[i+1])
);

  
function var int: position_in_sequence(JOBS: value) = 
   sum(  [ if value = sequence[i] 
              then i
           else 0 endif  
          | i in index_set(sequence) ]
   );
