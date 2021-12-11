%% Weighted spanning tree.
/** @group globals.graph
    Constrains the set of edges \a es of a given undirected graph to be a weighted spanning tree of weight \a W.

    @param N: the number of nodes in the given graph
    @param E: the number of edges in the given graph
    @param from: the leaving node 1..\a N for each edge
    @param to: the entering node 1..\a N for each edge
    @param w: the weight of each edge
    @param es: a Boolean for each edge whether it is in the subgraph
    @param K: the weight of the tree
**/   

predicate ws_tree(int: N, int: E, array[int] of int: from, array[int] of int: to, array[int] of var int: w,
              array[int] of var bool: es, var int: K) =
    assert(index_set(from) = 1..E,"wst: index set of from must be 1..\(E)") /\
    assert(index_set(to) = 1..E,"wst: index set of to must be 1..\(E)") /\
    assert(index_set(es) = 1..E,"wst: index set of es must be 1..\(E)") /\
    assert(index_set(w) = 1..E,"dwst: index set of w must be 1..\(E)") /\
    wst(N,E,from,to,w,es,K);

predicate wst(int: N, int: E, array[int] of int: from, array[int] of int: to, array[int] of var int: w,
                  array[int] of var bool: es, var int: K) =
    let { var 1..N: r; /* root of tree */
          array[1..N] of bool: ns = [true | n in 1..N]; } in
        tree(N,E,from,to,r,ns,es) /\
        K = sum(e in 1..E)(es[e]*w[e]);
        
include "all_different.mzn";
include "fzn_wst.mzn";
        
int: N = 4;
int: E = 6;
array[1..6] of int: from = [1, 1, 1, 2, 2, 3];
array[1..6] of int: to = [2, 3, 4, 3, 4, 4];

array[1..E] of var 1..E: weight;

array[1..E] of var bool: es;

var int: K;

constraint all_different(weight);

constraint ws_tree(N, E, from, to, weight, es, K);

solve minimize K;

                                                                                                                                