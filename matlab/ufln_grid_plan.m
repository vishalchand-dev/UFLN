function [cand,diag] = ufln_grid_plan(state,lm,map,cfg,useAstar)
t=tic; p=state(1:2); h=cfg.planners.GRAPH.grid; r=cfg.execution.r_plan;
xs=(p(1)-r):h:(p(1)+r); ys=(p(2)-r):h:(p(2)+r); pts=[];
for i=1:numel(xs), for j=1:numel(ys)
    q=[xs(i) ys(j)]; if norm(q-p)<=r+1e-9 && ufln_point_clearance(q,map,cfg,false)>0, pts(end+1,:)=q; end %#ok<AGROW>
end,end
% ensure current point is present as node 1
pts=[p;pts]; n=size(pts,1); edgeChecks=0;
% projected target
d=lm-p; if norm(d)>r, tgt=p+d/norm(d)*r; else,tgt=lm;end
[~,goal]=min(vecnorm(pts-tgt,2,2)); start=1;
G=inf(n,1); G(start)=0; parent=zeros(n,1); closed=false(n,1); expansions=0;
while true
    ids=find(~closed & isfinite(G)); if isempty(ids),break;end
    score=G(ids); if useAstar, score=score+vecnorm(pts(ids,:)-pts(goal,:),2,2); end
    [~,k]=min(score); u=ids(k); if u==goal, break; end
    closed(u)=true; expansions=expansions+1;
    dist=vecnorm(pts-pts(u,:),2,2); nbr=find(dist>1e-9 & dist<=cfg.planners.GRAPH.connect+1e-9 & ~closed);
    for vv=nbr'
        edgeChecks=edgeChecks+1; if ~ufln_segment_safe(pts(u,:),pts(vv,:),map,cfg),continue;end
        ng=G(u)+dist(vv); if ng<G(vv),G(vv)=ng;parent(vv)=u;end
    end
end
if ~isfinite(G(goal)) || goal==start, cand=p; else
    path=goal; u=goal; while parent(u)~=0, u=parent(u); path=[u path]; if u==start,break;end,end %#ok<AGROW>
    cand=pts(path(min(2,numel(path))),:);
    % choose furthest path node directly visible from current
    for k=2:numel(path)
        q=pts(path(k),:); if ufln_segment_safe(p,q,map,cfg), cand=q; else, break; end
    end
end
diag=struct('proposer_time_s',toc(t),'objective_evals',0,'graph_expansions',expansions,'edge_checks',edgeChecks,'rrt_nodes',0);
end
