function [cand,diag] = planner_GREEDY(state,lm,map,cfg) %#ok<INUSD>
t=tic; p=state(1:2); d=lm-p; if norm(d)>cfg.execution.r_plan, d=d/norm(d)*cfg.execution.r_plan; end
cand=ufln_project_candidate(p+d,state,cfg); diag=baseDiag(t); end
function d=baseDiag(t), d=struct('proposer_time_s',toc(t),'objective_evals',0,'graph_expansions',0,'edge_checks',0,'rrt_nodes',0); end
