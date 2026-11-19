function [cand,diag] = planner_RRT(state,lm,map,cfg)
t=tic;P=cfg.planners.RRT;p=state(1:2);nodes=p;parent=0;best=1;bestD=norm(p-lm);checks=0;
for k=2:P.max_nodes
    if rand<P.goal_bias, q=lm; else, q=sampleBall(p,cfg.execution.r_plan); end
    [~,near]=min(vecnorm(nodes-q,2,2));v=q-nodes(near,:);if norm(v)<1e-9,continue;end
    z=nodes(near,:)+min(P.step,norm(v))*v/norm(v);z=ufln_project_candidate(z,state,cfg);checks=checks+1;
    if ~ufln_segment_safe(nodes(near,:),z,map,cfg),continue;end
    nodes(end+1,:)=z;parent(end+1,1)=near; %#ok<AGROW>
    d=norm(z-lm);if d<bestD,bestD=d;best=size(nodes,1);end
end
% trace back to first step, then return furthest directly safe node on tree path
path=best;u=best;while parent(u)>0,u=parent(u);path=[u path];end %#ok<AGROW>
cand=p;for j=2:numel(path),q=nodes(path(j),:);if ufln_segment_safe(p,q,map,cfg),cand=q;else,break;end,end
diag=struct('proposer_time_s',toc(t),'objective_evals',0,'graph_expansions',0,'edge_checks',checks,'rrt_nodes',size(nodes,1));
end
function z=sampleBall(p,r),a=2*pi*rand;rr=r*sqrt(rand);z=p+rr*[cos(a) sin(a)];end
