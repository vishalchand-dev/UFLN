function report = ufln_validate_landmark_backbone(map,cfg)
% Algorithm-independent feasibility audit for the UFLN landmark corpus.
% The guaranteed backbone is not a planner path; it certifies that the map is
% not impossible solely because of landmark placement under range/LOS rules.
report=struct('ok',true,'reason',"OK",'max_edge',nan,'first_in_fov',false);
if ~isfield(map,'backbone_landmarks') || isempty(map.backbone_landmarks)
    report.ok=false; report.reason="NO_BACKBONE"; return;
end
B=map.backbone_landmarks; prev=map.start(1:2); maxEdge=0;
for i=1:size(B,1)
    d=norm(B(i,:)-prev); maxEdge=max(maxEdge,d);
    if d>0.75*cfg.sensor.range+1e-8
        report.ok=false; report.reason="BACKBONE_RANGE"; report.max_edge=maxEdge; return;
    end
    if ~ufln_line_of_sight(prev,B(i,:),map,cfg)
        report.ok=false; report.reason="BACKBONE_LOS"; report.max_edge=maxEdge; return;
    end
    if ~ufln_segment_safe(prev,B(i,:),map,cfg)
        report.ok=false; report.reason="BACKBONE_SAFETY"; report.max_edge=maxEdge; return;
    end
    prev=B(i,:);
end
if norm(B(end,:)-map.goal)>1e-8
    report.ok=false; report.reason="BACKBONE_GOAL"; report.max_edge=maxEdge; return;
end
% The initial pose is generated to see the first backbone landmark directly.
v=B(1,:)-map.start(1:2);
err=abs(ufln_wrap(atan2(v(2),v(1))-map.start(3)));
report.first_in_fov = err <= deg2rad(cfg.sensor.fov_full_deg)/2 + 1e-10;
if ~report.first_in_fov
    report.ok=false; report.reason="FIRST_ANCHOR_NOT_IN_FOV"; report.max_edge=maxEdge; return;
end
% Each density must contain the complete backbone and every non-goal landmark
% must have at least one safe/visible, closer-to-goal successor within range.
sets={map.landmarks_low,map.landmarks_med,map.landmarks_high};
for si=1:numel(sets)
    L=sets{si};
    for bi=1:size(B,1)
        if min(vecnorm(L-B(bi,:),2,2))>1e-8
            report.ok=false; report.reason="BACKBONE_MISSING_FROM_DENSITY"; report.max_edge=maxEdge; return;
        end
    end
    for i=1:size(L,1)
        if norm(L(i,:)-map.goal)<=1e-8, continue; end
        dg=norm(L(i,:)-map.goal); found=false;
        for j=1:size(L,1)
            if i==j, continue; end
            if norm(L(j,:)-map.goal)>=dg-0.1, continue; end
            if norm(L(j,:)-L(i,:))>0.95*cfg.sensor.range, continue; end
            if ufln_line_of_sight(L(i,:),L(j,:),map,cfg) && ufln_segment_safe(L(i,:),L(j,:),map,cfg)
                found=true; break;
            end
        end
        if ~found
            report.ok=false; report.reason="DEAD_END_LANDMARK"; report.max_edge=maxEdge; return;
        end
    end
end
report.max_edge=maxEdge;
end
