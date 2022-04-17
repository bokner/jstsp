%include "chuffed.mzn";
include "jacop.mzn";
solve 
:: priority_search(job_switches, [int_search([card(magazine_row_sets[j])], first_fail, indomain_min) | j in 1..J-1]  
    , 
    smallest)

minimize cost;