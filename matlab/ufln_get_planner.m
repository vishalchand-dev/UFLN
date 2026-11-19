function f = ufln_get_planner(name)
switch upper(string(name))
    case "GREEDY", f=@planner_GREEDY;
    case "DVWP", f=@planner_DVWP;
    case "DIJKSTRA", f=@planner_DIJKSTRA;
    case "ASTAR", f=@planner_ASTAR;
    case "ACO", f=@planner_ACO;
    case "BA", f=@planner_BA;
    case "FA", f=@planner_FA;
    case "SAFA", f=@planner_SAFA;
    case "RRT", f=@planner_RRT;
    otherwise, error('Unknown planner: %s',name);
end
end
