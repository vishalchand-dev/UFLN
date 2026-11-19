function z = ufln_project_candidate(z,state,cfg)
p=state(1:2); d=z-p; nd=norm(d);
if nd>cfg.execution.r_plan, z=p+d/nd*cfg.execution.r_plan; end
m=cfg.robot.radius+cfg.safety.margin; ws=cfg.workspace;
z(1)=min(max(z(1),ws(1)+m),ws(2)-m); z(2)=min(max(z(2),ws(3)+m),ws(4)-m);
end
