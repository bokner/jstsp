% First N sets sorted by their minimum.
% Additionally, restrict the sets to have elements greater than the threshold.
% 
predicate first_n_sets(var int: N, var int: threshold, array[TOOLS] of var set of JOBS: sets, var set of TOOLS: first_n_sets) = 
  let {
    array[TOOLS] of var JOBS: sorted_sets = arg_sort([min([t  | t in s where t > threshold]) | s in sets])
    } in 
    forall(i in index_set(sets))(
      i <= N <->
        sorted_sets[i] in first_n_sets
    );

%% Constrains the content of the magazine for the next job
%% to follow KTNS (keep tool needed first) policy.
%        
predicate ktns(1..J-1: position) = 
  let {
    var set of TOOLS: next_job = job_tool_sets[sequence[position+1]];
    var set of TOOLS: magazine_content = magazine_row_sets[position];
    var set of TOOLS: new_tools = next_job diff magazine_content;
    var set of TOOLS: replacements = magazine_content diff next_job; 
    var set of TOOLS: needed_first;
  }  in 
    if card(replacements) > card(new_tools) then
      (        
        first_n_sets(card(new_tools), position, [if r in replacements then magazine_col_sets[r] else {} endif | r in TOOLS], needed_first) /\
        forall(t in needed_first)(
          magazine[position+1, t] = 1)
      ) else true endif
  ;    