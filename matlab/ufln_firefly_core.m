function [cand,diag] = ufln_firefly_core(state,lm,map,cfg,isSAFA)
t=tic;if isSAFA,P=cfg.planners.SAFA;else,P=cfg.planners.FA;end
n=P.population;budget=cfg.objective.eval_budget;p=state(1:2);X=zeros(n,2);C=inf(n,1);evals=0;alpha=P.alpha0;
for i=1:n,X(i,:)=sampleBall(p,cfg.execution.r_plan);[C(i),~]=ufln_local_objective(X(i,:),state,lm,map,cfg);evals=evals+1;end
while evals<budget
    [~,ord]=sort(C);X=X(ord,:);C=C(ord);Xold=X;Cold=C;
    for i=1:n
        for j=1:n
            if evals>=budget,break;end
            if Cold(j)<Cold(i)
                d=Xold(i,:)-Xold(j,:);beta=P.beta0*exp(-P.gamma*dot(d,d));z=Xold(i,:)+beta*(Xold(j,:)-Xold(i,:))+alpha*(2*rand(1,2)-1)*(P.random_frac*cfg.execution.r_plan);
                if isSAFA
                    v=lm-p;if norm(v)>1e-9,z=z+P.drift_frac*cfg.execution.r_plan*v/norm(v);end
                end
                z=ufln_project_candidate(z,state,cfg);[cz,~]=ufln_local_objective(z,state,lm,map,cfg);evals=evals+1;
                if cz<C(i),X(i,:)=z;C(i)=cz;end
            end
        end
        if evals>=budget,break;end
    end
    alpha=alpha*P.alpha_damp;
end
[~,b]=min(C);cand=X(b,:);diag=struct('proposer_time_s',toc(t),'objective_evals',evals,'graph_expansions',0,'edge_checks',0,'rrt_nodes',0);
end
function z=sampleBall(p,r),a=2*pi*rand;rr=r*sqrt(rand);z=p+rr*[cos(a) sin(a)];end
