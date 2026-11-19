function [J,parts] = ufln_local_objective(z,state,lm,map,cfg)
% Normalized common look-ahead objective for ACO/BA/FA/SAFA.
% The planner may reason inside r_plan, while the shared execution layer later
% applies r_exec. Full proposal-segment clearance is evaluated exactly.
p=state(1:2);
z=ufln_project_candidate(z,state,cfg);
segClr=ufln_segment_clearance(p,z,map,cfg,false);
if ~all(isfinite(z)) || segClr<=0
    J=1e6; parts=[1 1 1 1]; return;
end
base=max(norm(p-lm),1e-9);
newd=norm(z-lm);
lookahead=max(min(cfg.execution.r_plan,base),1e-9);
progressGain=(base-newd)/lookahead;
progressPen=1-max(0,min(progressGain,1));
clearPen=max(0,1-min(segClr/cfg.safety.clearance_target,1));
desiredStep=min(cfg.execution.r_plan,base);
step=norm(z-p);
stepPen=1-min(step/max(desiredStep,1e-9),1);
if step<1e-9
    headingPen=1;
else
    headingPen=abs(ufln_wrap(atan2(z(2)-p(2),z(1)-p(1))-state(3)))/pi;
end
parts=[progressPen clearPen stepPen headingPen];
w=cfg.objective;
J=w.w_progress*progressPen+w.w_clearance*clearPen+w.w_step*stepPen+w.w_heading*headingPen;
end
