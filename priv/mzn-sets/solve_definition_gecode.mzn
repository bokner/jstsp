include "gecode.mzn";
annotation relax_and_reconstruct(array[int] of var int,int);
annotation restart_luby(int);   

% 65, 90
int: lns = 90;
int: restart = 100; 

    solve 
    :: seq_search([
     int_default_search(first_fail, indomain_random), 
     int_search(array1d(magazine), dom_w_deg, indomain_split),
                        

                        ])
            :: relax_and_reconstruct(array1d(magazine), lns) 
            :: restart_luby(restart)  
          
minimize cost;