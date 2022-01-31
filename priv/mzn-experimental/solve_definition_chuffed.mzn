include "chuffed.mzn";
solve 
%:: priority_search(sequence, [int_search([magazine[sequence[i], j] | j in TOOLS], smallest_largest, indomain_min) | i in TOOLS], random_order, indomain_min)
% :: priority_search(sequence, [int_search([sequence[i]], smallest, indomain_min) | i in JOBS], 
%     random_order, indomain_min)
%:: restart_luby(10000)
:: priority_search(sequence, [int_search([job_tools[sequence[i], j] | j in TOOLS]  %++ 
%col(magazine, t)
    , 
    smallest, indomain_split) | i in JOBS], 
    smallest, indomain_min)




%priority_search(X, [int_search([X[i]], input_order, indomain_min, complete) | i in 1..n], smallest, complete);
%     priority_search(start, smallest,
% 2 [ int_search([start[t],machine[t]], input_order, indomain_min)
% 3 | t in TASK])
minimize cost;