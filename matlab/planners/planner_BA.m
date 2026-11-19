function [cand,diag] = planner_BA(state,lm,map,cfg)
t=tic; P=cfg.planners.BA; n=P.population; budget=cfg.objective.eval_budget;p=state(1:2);
X=zeros(n,2);V=zeros(n,2);C=inf(n,1);evals=0;
for i=1:n, X(i,:)=sampleBall(p,cfg.execution.r_plan);[C(i),~]=ufln_local_objective(X(i,:),state,lm,map,cfg);evals=evals+1;end
[best,b]=min(C);bestX=X(b,:);
while evals<budget
    for i=1:n
        if evals>=budget,break;end
        f=P.fmin+(P.fmax-P.fmin)*rand;V(i,:)=V(i,:)+(X(i,:)-bestX)*f;z=X(i,:)+V(i,:);
        if rand>P.pulse,z=bestX+randn(1,2)*(P.local_frac*cfg.execution.r_plan);end
        z=ufln_project_candidate(z,state,cfg);[cz,~]=ufln_local_objective(z,state,lm,map,cfg);evals=evals+1;
        if cz<C(i) && rand<P.loudness,X(i,:)=z;C(i)=cz;if cz<best,best=cz;bestX=z;end,end
    end
end
cand=bestX;diag=mk(t,evals);
end
function z=sampleBall(p,r),a=2*pi*rand;rr=r*sqrt(rand);z=p+rr*[cos(a) sin(a)];end
function d=mk(t,e),d=struct('proposer_time_s',toc(t),'objective_evals',e,'graph_expansions',0,'edge_checks',0,'rrt_nodes',0);end
