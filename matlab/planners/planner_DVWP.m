function [cand,diag] = planner_DVWP(state,lm,map,cfg)
t=tic; p=state(1:2); par=cfg.planners.DVWP; a=lm-p;
if norm(a)<1e-9, cand=p; else
    vatt=par.k_att*a/norm(a); vrep=ufln_obstacle_repulsion(p,map,cfg,par.d0,par.k_rep); v=vatt+vrep;
    if norm(v)<1e-9, cand=p; else, cand=p+par.step_frac*cfg.execution.r_plan*v/norm(v); end
end
cand=ufln_project_candidate(cand,state,cfg); diag=baseDiag(t); end
function d=baseDiag(t), d=struct('proposer_time_s',toc(t),'objective_evals',0,'graph_expansions',0,'edge_checks',0,'rrt_nodes',0); end
