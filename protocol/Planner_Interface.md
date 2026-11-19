# Planner interface
A planner has MATLAB signature:

[candidate,diag] = planner_NAME(state,activeLandmark,map,cfg)

candidate is a finite 1x2 point within r_plan after projection. The shared execution layer, not the planner, enforces the r_exec cap and final safety decision.

diag contains proposer_time_s, objective_evals, graph_expansions, edge_checks, and rrt_nodes.

Tested mechanisms: GREEDY, DVWP, DIJKSTRA, ASTAR, ACO, BA, FA, SAFA, RRT.
