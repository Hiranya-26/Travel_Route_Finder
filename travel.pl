% ---------------- Travel Route Finder ----------------
% Finds paths between cities using DFS, BFS, and A*

% ----------- Graph Definition (Undirected Weighted Edges) -----------
edge(kandy, katugastota, 2).
edge(kandy, polgolla_dam, 1).
edge(kandy, thennekumbura, 2).
edge(katugastota, ousl, 3).
edge(katugastota, polgolla_dam, 3).
edge(ousl, digana, 2).
edge(polgolla_dam, ousl, 3).
edge(polgolla_dam, digana, 6).
edge(polgolla_dam, pallekele, 5).
edge(thennekumbura, pallekele, 3).
edge(pallekele, digana, 4).

% Undirected edges
connected(X, Y, Cost) :- edge(X, Y, Cost) ; edge(Y, X, Cost).

% ---------------- DFS ----------------
dfs(Start, Goal, Path, CostLabel) :-
    dfs_helper(Start, Goal, [Start], RevPath, 0, Cost),
    reverse(RevPath, Path),
    atomic_list_concat([Cost, 'km'], CostLabel).

dfs_helper(Goal, Goal, Path, Path, AccCost, AccCost).
dfs_helper(Current, Goal, Visited, Path, AccCost, Cost) :-
    connected(Current, Next, StepCost),
    \+ member(Next, Visited),
    NewCost is AccCost + StepCost,
    dfs_helper(Next, Goal, [Next|Visited], Path, NewCost, Cost).

% ---------------- BFS ----------------
bfs(Start, Goal, Path, CostLabel) :-
    bfs_queue([[Start]], Goal, RevPath),
    reverse(RevPath, Path),
    path_cost_num(Path, NumCost),
    atomic_list_concat([NumCost, 'km'], CostLabel).

bfs_queue([[Goal|Rest]|_], Goal, [Goal|Rest]).
bfs_queue([[Current|Rest]|Others], Goal, Path) :-
    findall([Next,Current|Rest],
            ( connected(Current, Next, _), 
              \+ member(Next, [Current|Rest]) ),
            NextPaths),
    append(Others, NextPaths, UpdatedQueue),
    bfs_queue(UpdatedQueue, Goal, Path).

% -------- Path Cost Calculation --------
path_cost_num([_], 0).
path_cost_num([A,B|Rest], Cost) :-
    connected(A, B, C),
    path_cost_num([B|Rest], RestCost),
    Cost is C + RestCost.

% ---------------- A* Search ----------------
heuristic(kandy, digana, 5).
heuristic(kandy, ousl, 3).
heuristic(kandy, pallekele, 4).
heuristic(kandy, katugastota, 2).
heuristic(kandy, polgolla_dam, 1).
heuristic(kandy, thennekumbura, 2).
heuristic(_, _, 3).  % default guess (to keep it simple)

a_star(Start, Goal, Path, CostLabel) :-
    heuristic(Start, Goal, H),
    a_star_search([[Start, 0, H, [Start]]], Goal, RevPath, Cost),
    reverse(RevPath, Path),
    atomic_list_concat([Cost, 'km'], CostLabel).

a_star_search([[Goal, G, _, Path]|_], Goal, Path, G).
a_star_search([[Current, G, _, Path]|RestQueue], Goal, FinalPath, FinalCost) :-
    findall([Next, NewG, H, [Next|Path]],
        ( connected(Current, Next, StepCost),
          \+ member(Next, Path),
          NewG is G + StepCost,
          heuristic(Next, Goal, H) ),
        NextPaths),
    append(RestQueue, NextPaths, TempQueue),
    sort_paths(TempQueue, SortedQueue),
    a_star_search(SortedQueue, Goal, FinalPath, FinalCost).

sort_paths(Paths, Sorted) :-
    map_list_to_pairs(path_f_value, Paths, Pairs),
    keysort(Pairs, SortedPairs),
    pairs_values(SortedPairs, Sorted).

path_f_value([_, G, H, _], F) :- F is G + H.

% ---------------- User Friendly Interface ----------------
find_best_route(Start, Goal) :-
    nl, write('--- Travel Route Finder ---'), nl,
    write('From: '), write(Start), write('  To: '), write(Goal), nl, nl,

    % DFS
    dfs(Start, Goal, DFSPath, DFSCost),
    write('DFS Path: '), write(DFSPath), nl,
    write('DFS Cost: '), write(DFSCost), nl, nl,

    % BFS
    bfs(Start, Goal, BFSPath, BFSCost),
    write('BFS Path: '), write(BFSPath), nl,
    write('BFS Cost: '), write(BFSCost), nl, nl,

    % A*
    a_star(Start, Goal, AStarPath, AStarCost),
    write('A* Path: '), write(AStarPath), nl,
    write('A* Cost: '), write(AStarCost), nl, nl,

    write('--- Comparison ---'), nl,
    write('DFS explores deeply, BFS finds shortest in steps, A* finds optimal using heuristics.'), nl.
