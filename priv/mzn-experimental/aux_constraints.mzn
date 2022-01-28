%constraint cost = sum(j in 1..J-1)(switches(j, j+1)); 
array[JOBS] of var set of TOOLS: magazine_sets;

constraint forall(j in JOBS)(
  link_set_to_booleans(magazine_sets[j],
        [magazine[j, t] = 1 | t in TOOLS])
);

constraint cost = sum(j in 1..J-1)(
  card(magazine_sets[j+1] diff magazine_sets[j])
);