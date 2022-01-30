include "chuffed.mzn";
solve 
:: priority_search(tool_switches, 
    [int_search(tool_switches, first_fail, indomain_min)], first_fail, indomain_min)
minimize cost;