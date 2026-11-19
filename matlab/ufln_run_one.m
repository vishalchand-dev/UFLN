function [result,trace] = ufln_run_one(map,cfg,plannerName,seed,recordKey)
if seed~=0,rng(seed,'twister');end
planner=ufln_get_planner(plannerName);L=ufln_landmarks(map,cfg);nL=size(L,1);visited=false(nL,1);active=0;
state=double(map.start);prevCtrl=[0 0];tRun=tic;timeNow=0;
% Trace columns: time x y theta v w active visibleCount propX propY execX execY clearance scan fallback
traceMat=[0 state 0 0 0 0 nan nan nan nan ufln_point_clearance(state(1:2),map,cfg,false) 0 0];
nav=0;trackSteps=0;invalidProps=0;fallbacks=0;scanRec=0;visLoss=0;scanAngle=0;switches=0;distinctReached=0;propTime=0;objEvals=0;graphExp=0;edgeChecks=0;rrtNodes=0;visibleCountAccum=0;visibleChecks=0;planningCalls=0;term="MAX_NAV_STEPS";success=false;
for nav=1:cfg.execution.max_nav_steps
    if norm(state(1:2)-map.goal)<=cfg.controller.goal_tol,term="GOAL_REACHED";success=true;break;end
    if active>0 && norm(state(1:2)-L(active,:))<=cfg.controller.landmark_tol
        visited(active)=true;distinctReached=distinctReached+1;active=0;
    end
    [vis,~]=ufln_visible_landmarks(state,L,map,cfg,visited);visibleCountAccum=visibleCountAccum+numel(vis);visibleChecks=visibleChecks+1;
    lostThisStep=false;
    if active>0 && ~ismember(active,vis),active=0;visLoss=visLoss+1;lostThisStep=true;end
    if active==0
        active=ufln_select_landmark(state,L,map,cfg,visited);
        if active==0
            if ~lostThisStep
                visLoss=visLoss+1;
            end
            [state,found,scanRows,ang]=ufln_scan_for_landmark(state,L,map,cfg,visited);
            scanRec=scanRec+1;
            scanAngle=scanAngle+ang;
            for rr=1:size(scanRows,1),timeNow=timeNow+scanRows(rr,1);traceMat(end+1,:)=[timeNow scanRows(rr,2:4) 0 scanRows(rr,6) 0 0 nan nan nan nan scanRows(rr,7) 1 0];end %#ok<AGROW>
            if ~found,term="NO_VISIBLE_LANDMARK";break;end
            active=ufln_select_landmark(state,L,map,cfg,visited);if active==0,term="NO_VISIBLE_LANDMARK";break;end
        end
        switches=switches+1;if switches>cfg.execution.max_landmark_switches,term="LANDMARK_SWITCH_GUARD";break;end
    end
    lm=L(active,:);
    planningCalls=planningCalls+1;[cand,pd]=planner(state,lm,map,cfg);propTime=propTime+pd.proposer_time_s;objEvals=objEvals+pd.objective_evals;graphExp=graphExp+pd.graph_expansions;edgeChecks=edgeChecks+pd.edge_checks;rrtNodes=rrtNodes+pd.rrt_nodes;
    [wp,usedFallback,invalid]=ufln_execute_candidate(state,cand,lm,map,cfg);invalidProps=invalidProps+invalid;fallbacks=fallbacks+usedFallback;
    if norm(wp-state(1:2))<1e-10,term="NO_SAFE_EXECUTION";break;end
    [state,seg,ok,reason,prevCtrl]=ufln_track_waypoint(state,wp,map,cfg,prevCtrl);trackSteps=trackSteps+size(seg,1);
    for rr=1:size(seg,1)
        timeNow=timeNow+seg(rr,1);[vv,~]=ufln_visible_landmarks(seg(rr,2:4),L,map,cfg,visited);traceMat(end+1,:)=[timeNow seg(rr,2:4) seg(rr,5:6) active numel(vv) cand wp seg(rr,7) 0 usedFallback]; %#ok<AGROW>
    end
    if ~ok,term=reason;break;end
end
endTime=toc(tRun);
if ~success && norm(state(1:2)-map.goal)<=cfg.controller.goal_tol,success=true;term="GOAL_REACHED";end
trace=ufln_trace_struct(traceMat,recordKey,plannerName,map.id,seed);
metrics=ufln_metrics_from_trace(trace,map,cfg);
result=struct('record_key',string(recordKey),'map_id',string(map.id),'corpus_version',string(map.corpus_version),'difficulty',string(map.difficulty),'planner',string(plannerName),'seed',seed,'success',success,'termination_reason',string(term), ...
    'nav_steps',nav,'tracking_steps',trackSteps,'path_length',metrics.path_length,'reference_length',double(map.reference_length),'path_ratio',metrics.path_ratio, ...
    'end_to_end_time_s',endTime,'proposer_time_total_s',propTime,'proposer_time_mean_s',propTime/max(planningCalls,1),'planning_calls',planningCalls,'min_clearance',metrics.min_clearance,'p05_clearance',metrics.p05_clearance, ...
    'heading_variation_per_m',metrics.heading_variation_per_m,'linear_accel_rms',metrics.linear_accel_rms,'angular_accel_rms',metrics.angular_accel_rms,'control_effort',metrics.control_effort, ...
    'invalid_proposals',invalidProps,'fallback_count',fallbacks,'scan_recoveries',scanRec,'scan_angle_total_rad',scanAngle,'visibility_loss_events',visLoss,'landmark_switches',switches,'distinct_landmarks_reached',distinctReached, ...
    'mean_visible_landmarks_decision',visibleCountAccum/max(visibleChecks,1),'objective_evals',objEvals,'graph_expansions',graphExp,'edge_checks',edgeChecks,'rrt_nodes',rrtNodes,'goal_error',norm(state(1:2)-map.goal), ...
    'map_difficulty_score',double(map.difficulty_score),'map_obstacle_area_ratio',double(map.obstacle_area_ratio),'map_reference_path_ratio',double(map.reference_path_ratio),'map_reference_min_clearance',double(map.reference_min_clearance),'map_backbone_count',double(map.backbone_count));
end
