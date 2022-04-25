include "chuffed.mzn";
%include "jacop.mzn";
annotation priority_search(array[int] of var int, array[int] of ann, ann);

solve 
%:: priority_search([0] ++ job_switches, [int_search(row(magazine, j),  smallest, indomain_min) | j in 1..J]  
%:: priority_search(tool_switches, [int_search(col(magazine, j),  smallest, indomain_min) | j in TOOLS] 
:: priority_search(job_switches, [int_search(row(magazine, j),  smallest, indomain_min) | j in 1..J-1] 
    , 
    first_fail, complete)

minimize cost;