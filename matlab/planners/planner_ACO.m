function [cand,diag] = planner_ACO(state,lm,map,cfg)
t=tic; P=cfg.planners.ACO; K=P.archive; budget=cfg.objective.eval_budget; p=state(1:2);
A=zeros(K,2); C=inf(K,1); evals=0;
for i=1:K, A(i,:)=sampleBall(p,cfg.execution.r_plan); [C(i),~]=ufln_local_objective(A(i,:),state,lm,map,cfg); evals=evals+1; end
[C,ord]=sort(C);A=A(ord,:);
while evals<budget
    ranks=(0:K-1)'; w=exp(-(ranks.^2)/(2*(P.q*K)^2)); w=w/sum(w);
    m=min(P.samples,budget-evals); Z=zeros(m,2); Zc=inf(m,1);
    for s=1:m
        idx=find(rand<=cumsum(w),1,'first'); z=A(idx,:)+randn(1,2)*(P.sigma_frac*cfg.execution.r_plan); z=ufln_project_candidate(z,state,cfg);
        [Zc(s),~]=ufln_local_objective(z,state,lm,map,cfg);Z(s,:)=z;evals=evals+1;
    end
    A=[A;Z];C=[C;Zc];[C,ord]=sort(C);A=A(ord(1:K),:);C=C(1:K);
end
cand=A(1,:);diag=mk(t,evals);
end
function z=sampleBall(p,r), a=2*pi*rand; rr=r*sqrt(rand); z=p+rr*[cos(a) sin(a)];end
function d=mk(t,e),d=struct('proposer_time_s',toc(t),'objective_evals',e,'graph_expansions',0,'edge_checks',0,'rrt_nodes',0);end
