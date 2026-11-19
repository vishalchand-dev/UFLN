function [state,seg,ok,reason,prevCtrl] = ufln_track_waypoint(state,wp,map,cfg,prevCtrl) %#ok<INUSD>
% Shared V2.2 unicycle waypoint tracker.
% The reference implementation uses a stop-and-turn waypoint contract: each
% accepted waypoint starts from zero commanded speed. This prevents residual
% velocity from a previous waypoint from producing an unsafe curved transient.
dt=cfg.controller.dt; rows=[]; ok=false; reason="TRACKING_GUARD";
vprev=0; wprev=0;
for k=1:cfg.controller.max_control_steps_per_waypoint
    p=state(1:2); rho=norm(wp-p);
    if rho<=cfg.controller.waypoint_tol
        ok=true; reason="OK"; break;
    end
    alpha=ufln_wrap(atan2(wp(2)-p(2),wp(1)-p(1))-state(3));
    wdes=max(-cfg.robot.w_max,min(cfg.robot.w_max,cfg.controller.k_alpha*alpha));
    if abs(alpha)>cfg.controller.align_angle
        % Rotate in place until the waypoint is inside the forward alignment cone.
        v=0;
        w=wprev+max(-cfg.robot.a_w_max*dt,min(cfg.robot.a_w_max*dt,wdes-wprev));
    else
        vdes=min(cfg.robot.v_max,cfg.controller.k_rho*rho)*max(cos(alpha),0);
        v=vprev+max(-cfg.robot.a_v_max*dt,min(cfg.robot.a_v_max*dt,vdes-vprev));
        w=wprev+max(-cfg.robot.a_w_max*dt,min(cfg.robot.a_w_max*dt,wdes-wprev));
    end
    next=ufln_unicycle_step(state,v,w,dt);
    if ~ufln_segment_safe(state(1:2),next(1:2),map,cfg)
        % A waypoint was accepted only if the straight centre path is safe. If a
        % curved transient would violate the margin, rotate in place instead.
        if cfg.controller.safety_rotate_only && abs(w)>1e-10
            v=0;
            next=ufln_unicycle_step(state,v,w,dt);
        end
        if ~ufln_segment_safe(state(1:2),next(1:2),map,cfg)
            reason="TRACKING_SAFETY_GUARD"; break;
        end
    end
    clr=ufln_point_clearance(next(1:2),map,cfg,false);
    rows(end+1,:)=[dt,next,v,w,clr]; %#ok<AGROW>
    state=next; vprev=v; wprev=w;
end
seg=rows;
% UFLN V2.2.1 ends each waypoint segment at rest before replanning.
prevCtrl=[0 0];
end
